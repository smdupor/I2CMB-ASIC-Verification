`timescale 1ns/1ps

interface i2c_if       #(
	int I2C_ADDR_WIDTH = 10,
	int I2C_DATA_WIDTH = 8,
	bit TRANSFER_DEBUG_MODE = 0                          
)
(
	// System signals
	input wire clk_i,
	input wire rst_i,
	// Master signals
	input wire scl_i,
	input triand sda_i,
	output wire sda_o
);
	// Types and Enum Switches for Interrupts
	import i2c_types_pkg::*;
	enum bit [1:0] {INTR_RST=2'b00,RAISE_START=2'b01, RAISE_STOP=2'b10, RAISE_RESTART=2'b11} intrs;
	enum bit {STOP, START} stst;
	enum bit {ACK, NACK} aknk;
	
	// Configured address of this Slave
	bit [8:0] slave_address;

	// Internal Signals: Control and Start/Stop/Restart Interrupts
	bit xfer_in_progress;
	bit sampler_running;
	bit [1:0] i2c_slv_interrupt;

	// Internal Driver Signals and Buffers
	bit [8:0] i2c_slv_io_buffer;
	bit slv_write_response;
	bit [7:0] slave_receive_buffer[$];
	bit [7:0] slave_transmit_buffer[$];
	
	// Internal Monitor Signals and Buffers
	bit monitor_only;
	bit [1:0] i2c_mon_interrupt;
	bit [8:0] i2c_slv_mon_buffer;

	// Indices of MSB and LSB of a Byte in a larger buffer
	parameter int MSB=8;
	parameter int LSB=1;

	// Register for driving Serial Data Line by Slave BFM
	logic sda_drive=1'bz;
	assign sda_o = sda_drive;

	// Reset the Slave BFM and configure it to hold input_addr address.
	// Reset task automatically starts the sampler for detecting start/stop
	task reset_and_configure(input bit [8:0] input_addr);
		slave_address = (input_addr << 2);
		xfer_in_progress = STOP;
		sampler_running = STOP;
		monitor_only = 1'b1;	// Assume that we only need monitor until driver is called
		i2c_slv_interrupt = INTR_RST;
		i2c_mon_interrupt = INTR_RST;
		connection_negotiation_sampler();
	endtask
	
	// Empty the Driver's buffers on a reset
	task reset_test_buffers();
		slave_receive_buffer.delete();
		slave_transmit_buffer.delete();
	endtask

	// Provide data to be transmitted by the slave BFM upon a requested read op from the Master
	task provide_read_data(input bit [I2C_DATA_WIDTH-1:0] read_data [], output bit transfer_complete);
		foreach(read_data[i]) slave_transmit_buffer.push_back(read_data[i]);
		wait(slave_transmit_buffer.size == 0);
		transfer_complete = 1'b1;
	endtask

	task connection_negotiation_sampler();
		static bit [1:0] control;
		static logic [3:0] samples;
		sampler_running = START;
		@(posedge clk_i); // Wait for Serial clock to rise to 
		forever begin
			// Continuously sample sda and scl at 100MHz
			samples[0]=sda_i;
			samples[1]=scl_i;
			#10 samples[2]=sda_i;
			samples[3]=scl_i;

			// If we find a valid transition indicating start/stop/restart, Store values in control
			if(samples[1]==1'b1 && samples[3]==1'b1) begin
				control[0] = samples[0];
				control[1] = samples[2];
			end

			// Check control and raise relevant interrupt code to rest of system if conditions met
			case(control)
				2'b01: begin			 	// start or Re-start
					if(xfer_in_progress== STOP) begin 	// Not Running, Start Detected
						i2c_slv_interrupt = RAISE_START;
						i2c_mon_interrupt = RAISE_START;
					end
					else begin				// Already running, Restart detected
						i2c_slv_interrupt = RAISE_RESTART;
						i2c_mon_interrupt = RAISE_RESTART;
					end
					xfer_in_progress = START;end
				2'b10: begin 				// Stop Condition Detected
					i2c_slv_interrupt = RAISE_STOP;
					i2c_mon_interrupt = RAISE_STOP;
					xfer_in_progress = STOP;
				end
			endcase
		end
	endtask

	task monitor(output bit[I2C_ADDR_WIDTH-1:0] addr, output i2c_op_t op, output bit [I2C_DATA_WIDTH-1:0] data []);
		static bit ack;
		static bit [7:0] local_data[$];
		local_data.delete;

		wait(xfer_in_progress == START && (i2c_mon_interrupt == RAISE_START || i2c_mon_interrupt == RAISE_RESTART));
		i2c_mon_interrupt = INTR_RST; // Reset the interrupt on detected

		// Capture the incoming address, operation, and ack
		for(int i=MSB;i>=0;i--) begin
			@(posedge scl_i);
			i2c_slv_mon_buffer[i] = sda_i;
		end
		addr = i2c_slv_mon_buffer[MSB:2];
		op = i2c_slv_mon_buffer[1]? I2_READ : I2_WRITE;
		ack = i2c_slv_mon_buffer[0];
				
		// Record the transferred data
		monitor_record_data(local_data, op);
		
		// Copy transferred data to output array
		data=local_data;
	endtask

	task monitor_record_data(output bit [I2C_DATA_WIDTH-1:0] write_data [$], input i2c_op_t op);
		static bit [8:0] rec_dat_mon_buf;
		write_data.delete;
		forever begin
			for(int i=MSB;i>=0;i--) begin
				if(mon_intr_raised()) return;
				@(posedge scl_i) rec_dat_mon_buf[i] = sda_i;
				@(negedge scl_i);
			end
			write_data.push_back(rec_dat_mon_buf[MSB:LSB]);
			if(op==I2_READ && rec_dat_mon_buf[0]==NACK) return; // Return on Read op and NACK (End Call)
			if(TRANSFER_DEBUG_MODE) $write("  [I2C] -->>> %d\t <WRITE>\n",i2c_slv_io_buffer[MSB:LSB]);
		end
	endtask

	task wait_for_i2c_transfer(output i2c_op_t op, output bit [I2C_DATA_WIDTH-1:0] write_data []);
		monitor_only <= 1'b0; // Tell The monitor/sampler that there is also a driver in parallel
		wait(xfer_in_progress == START && (i2c_slv_interrupt == RAISE_START || i2c_slv_interrupt == RAISE_RESTART));
		i2c_slv_interrupt = INTR_RST; // Reset the interrupt on detected
		driver_receive_address(op, write_data); // Handle the request
	endtask

	task driver_receive_address(output i2c_op_t op, output bit [I2C_DATA_WIDTH-1:0] write_data []);
		static bit [7:0] write_buf[$];
		// Read Address and opcode from serial bus
		for(int i=MSB;i>=LSB;i--) begin
			@(posedge scl_i);
			i2c_slv_io_buffer[i] = sda_i;
			@(negedge scl_i) if(intr_raised()) return;
		end
		
		// Determine whether address matches configured slave address OR the All-Call address
		if(i2c_slv_io_buffer[MSB:2]==slave_address[MSB:2] || i2c_slv_io_buffer[MSB:2]==7'b000_0000) begin
			// SEND THE ACK Back to master upon a match
			driver_transmit_ACK();
			
			// Determine the operation code
			op = i2c_slv_io_buffer[1]? I2_READ : I2_WRITE;
			
			// Branch to handle requested operation
			if(op==I2_WRITE)driver_receive_write_data(write_buf);
			else driver_transmit_read_data();
			
		end
		// Copy queued captured write data into return array.
		write_data = write_buf;
	endtask

	task driver_receive_write_data(output bit [I2C_DATA_WIDTH-1:0] write_data [$]);
		forever begin
			driver_read_single_byte();

			// Check to ensure we have not encountered a stop/restart condition, if so, 
			// return control to caller for next transfer to begin
			if(intr_raised()) return;

			// Reply with the ACK of this byte
			driver_transmit_ACK();

			// Store byte in Driver's local buffer and returnable buffer
			slave_receive_buffer.push_back(i2c_slv_io_buffer[MSB:LSB]);
			write_data.push_back(i2c_slv_io_buffer[MSB:LSB]);
			if(TRANSFER_DEBUG_MODE) $write("  [I2C] -->>> %d\t <WRITE>\n",i2c_slv_io_buffer[MSB:LSB]);
		end
	endtask

	task driver_read_single_byte();
		for(int i=MSB;i>=LSB;i--) begin
			// Capture the value
			@(posedge scl_i) i2c_slv_io_buffer[i] = sda_i;
			// Sample/Watch for a possible restart/stop signal until negedge scl_i
			while(scl_i ==1'b1)	#10	if(intr_raised()) return;
		end
	endtask

	task driver_transmit_ACK();
		sda_drive = 1'b0;
		@(posedge scl_i);
		@(negedge scl_i) sda_drive =1'bz;
	endtask

	task driver_transmit_read_data();
		static bit local_ack;
		local_ack = 0;
		while(slave_transmit_buffer.size > 0) begin
			// Get data out of transmit buffer to send
			i2c_slv_io_buffer[MSB:LSB] = slave_transmit_buffer.pop_front();

			//Send a byte on sda while clock is high			
			driver_transmit_single_byte();

			// Check for ack/NACK from master
			sda_drive <= 1'bz;
			@(posedge scl_i) local_ack = sda_i;

			// Check for NACK/DONE or STOP/RESTART CONDTION
			if(local_ack==NACK) return;
			@(negedge scl_i) if(intr_raised()) return;
		end
	endtask

	task driver_transmit_single_byte();
		for(int i=MSB;i>=LSB;i--) begin
			sda_drive <= i2c_slv_io_buffer[i];
			@(posedge scl_i);
			@(negedge scl_i);
		end
	endtask
	

	function bit intr_raised();
		intr_raised = (i2c_slv_interrupt == RAISE_STOP || i2c_slv_interrupt == RAISE_RESTART || i2c_slv_interrupt == RAISE_START);
	endfunction

	function bit mon_intr_raised();
		mon_intr_raised = (i2c_mon_interrupt == RAISE_STOP || i2c_mon_interrupt == RAISE_RESTART || i2c_mon_interrupt == RAISE_START);
	endfunction
		
	function byte get_receive_entry(int i);
		return slave_receive_buffer[i];
	endfunction
	
	function void print_driver_write_report();
		static string s;
		static string temp;
		$display("SLAVE I2C-Bus Received Bytes from WRITES:");
		s = "\t";
		foreach(slave_receive_buffer[i]) begin
			if(s.len % PRINT_LINE_LEN < 4) s = {s,"\n\t"};
			temp.itoa(integer'(slave_receive_buffer[i]));
			s = {s,temp,","};
		end
		$display("%s", s.substr(0,s.len-2));
	endfunction
	
	
endinterface
