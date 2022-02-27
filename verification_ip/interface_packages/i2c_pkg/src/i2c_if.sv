`timescale 1ns/1ps

interface i2c_if       #(
	int I2C_ADDR_WIDTH = 10,
	int I2C_DATA_WIDTH = 8,
	bit TRANSFER_DEBUG_MODE=0 //,
	//bit [6:0] SLAVE_ADDRESS = 0                          
)
(
	// System sigals
	input wire clk_i,
	input wire rst_i,
	// Master signals
	input wire scl_i,
	input triand sda_i,
	output wire sda_o,
	output byte most_recent_xfer
);
	import i2c_types_pkg::*;

	logic sda_drive=1'b1;
	assign sda_o = sda_drive;

	logic [7:0] next_xfer_oracle;
	assign most_recent_xfer = next_xfer_oracle;

	enum bit [1:0] {INTR_RST=2'b00,RAISE_START=2'b01, RAISE_STOP=2'b10, RAISE_RESTART=2'b11} stst;

	bit [8:0] slave_address;

	bit start;
	bit sampler_running;
	bit monitor_only;
	bit [1:0] i2c_slv_interrupt;
	bit [1:0] i2c_mon_interrupt;
	bit [8:0] i2c_slv_io_buffer;
	bit [8:0] i2c_slv_mon_buffer;
	bit slv_write_response;
	bit [7:0] slave_receive_buffer[$];
	bit [7:0] slave_transmit_buffer[$];

	task reset_and_configure(input bit [8:0] input_addr);
		slave_address = (input_addr << 2);
		start = 1'b0;
		sampler_running=1'b0;
		monitor_only = 1'b1;
		i2c_slv_interrupt = INTR_RST;
		i2c_mon_interrupt = INTR_RST;
		detect_connection_negotiation();
	endtask

	task bypass_push_transmit_buf(input byte slv_xmit_value);
		slave_transmit_buffer.push_back(slv_xmit_value);
	endtask

	function byte get_receive_entry(int i);
		return slave_receive_buffer[i];
	endfunction

	task reset_test_buffers();
		slave_receive_buffer.delete();
		slave_transmit_buffer.delete();
	endtask

	task print_read_report();
		static string s;
		static string temp;
		s = " Slave Received Bytes (0x): ";
		foreach(slave_receive_buffer[i]) begin
			temp.itoa(integer'(slave_receive_buffer[i]));
			s = {s,temp,","};
		end
		$display("%s", s.substr(0,s.len-2));
	endtask

	task detect_connection_negotiation();
		static bit [1:0] control;
		static logic [3:0] sample;
		sampler_running = 1'b1;
		@(posedge clk_i); // Wait for Serial clock to rise to 
		forever begin
			// Continuously sample sda and scl at 100MHz
			sample[0]=sda_i;
			sample[1]=scl_i;
			#10 sample[2]=sda_i;
			sample[3]=scl_i;

			// If we find a valid transition indicating start/stop/restart, Store values in control
			if(sample[1]==1'b1 && sample[3]==1'b1) begin
				control[0] = sample[0];
				control[1] = sample[2];
			end

			// Check control and raise relevant interrupt code to rest of system if conditions met
			case(control)
				2'b01: begin // start or Re-start
					if(start==1'b0) begin
						i2c_slv_interrupt = RAISE_START;
						i2c_mon_interrupt = RAISE_START;
					end
					else begin
						i2c_slv_interrupt = RAISE_RESTART;
						i2c_mon_interrupt = RAISE_RESTART;
					end
					start = 1'b1;end
				2'b10: begin // end condition
					i2c_slv_interrupt = RAISE_STOP;
					i2c_mon_interrupt = RAISE_STOP;
					start = 1'b0;
				end
			endcase
			//if(~sampler_running) return;
		end
	endtask

task i2c_monitor(output bit[I2C_ADDR_WIDTH-1:0] addr, output i2c_op_t op, output bit [I2C_DATA_WIDTH-1:0] data []);
	//static bit[6:0] addr;
	static bit we;
	static bit ack;
	static bit kill;
	//static bit [7:0] data[];
	static int mon_index;
	static bit [7:0] local_data[$];
	local_data.delete;
	kill=0;
	$display("INTERFACE MONITORING YEAH");
	
	wait(start == 1'b1 && (i2c_mon_interrupt == RAISE_START || i2c_mon_interrupt == RAISE_RESTART));
	i2c_mon_interrupt = INTR_RST; // Reset the interrupt on detected
	$display("Saw Start yeah");
	//if(monitor_only) i2c_slv_interrupt = INTR_RST; // Reset the interrupt on detected
	for(int i=8;i>=0;i--) begin
			@(posedge scl_i);
			i2c_slv_mon_buffer[i] = sda_i;
			@(negedge scl_i) if(mon_intr_raised()) break;
		end
		addr=i2c_slv_mon_buffer[8:2];
		op = i2c_slv_mon_buffer[1]? I2_WRITE : I2_READ;
		ack=i2c_slv_mon_buffer[0];
		$display("GOT Addr YEAH");
	
	while(1) begin
			if(scl_i==1'b1 && mon_intr_raised()) break;
			
			for(int i=8;i>=0;i--) begin
				if(mon_intr_raised()) begin
					kill=1;
					break;
					end
				@(posedge scl_i);
				while(scl_i ==1'b1 && !mon_intr_raised())
					#10 i2c_slv_mon_buffer[i] = sda_i; 
			end
			$display("GOT Byte YEAH");
			if(kill==0)begin
					local_data.push_back(i2c_slv_mon_buffer[8:1]);
			ack=i2c_slv_mon_buffer[0];
			
			++mon_index;
			end
			if(mon_intr_raised()) break;
		end
		$display("GOT Break YEAH");
		data=local_data;
	endtask

	task wait_for_start(output i2c_op_t op, output bit [I2C_DATA_WIDTH-1:0] write_data []);
		monitor_only <= 1'b0;
		//$display("REPORT SUCCESSFUL BOOT!");
		//if(~sampler_running) fork detect_connection_negotiation();

		//	forever begin
				wait(start == 1'b1 && (i2c_slv_interrupt == RAISE_START || i2c_slv_interrupt == RAISE_RESTART));
				#10 i2c_slv_interrupt = INTR_RST; // Reset the interrupt on detected
				receive_address(op, write_data); // Handle the request
			//end
		//join;
	endtask

	task receive_address(output i2c_op_t op, output bit [I2C_DATA_WIDTH-1:0] write_data []);
		static bit [7:0] write_buf[$];
		// Read Address and opcode from serial bus
		//$display("Attempt addr");
		for(int i=8;i>=1;i--) begin
			@(posedge scl_i);
			i2c_slv_io_buffer[i] = sda_i;
			@(negedge scl_i) if(intr_raised()) return;
		end
		if(i2c_slv_io_buffer[8:2]==slave_address[8:2] || i2c_slv_io_buffer[8:2]==7'b000_0000) begin
			// SEND THE ACK Back to master upon a match
			sda_drive <= 1'b0;
			@(negedge scl_i) sda_drive <= 1'bz;

			// Select the writeenable to branch from
			slv_write_response=i2c_slv_io_buffer[1];

			// Branch to handle requested op
			if(!slv_write_response)begin
				op=I2_READ;
				receive_data(write_buf);
			end
			else begin
				op=I2_WRITE;
				transmit_data();
			end
		end
		write_data = write_buf;
	endtask

	task receive_data(output bit [I2C_DATA_WIDTH-1:0] write_data [$]);
		static int index;
		//write_data = new[64];
		//$display("Attempt recv");
		while(1) begin
			if(scl_i==1'b1)
			if(intr_raised()) return;
			for(int i=8;i>=1;i--) begin
				if(intr_raised()) return;
				@(posedge scl_i);
				while(scl_i ==1'b1 && !intr_raised())
					#10 i2c_slv_io_buffer[i] = sda_i; 
				if(intr_raised()) return;
				//@(negedge scl_i) if(intr_raised()) return;
			end
			sda_drive = 1'b0;
			@(posedge scl_i);
			@(negedge scl_i) sda_drive =1'bz;
			slave_receive_buffer.push_back(i2c_slv_io_buffer[8:1]);
			write_data.push_back(i2c_slv_io_buffer[8:1]);
			++index;
			
			if(TRANSFER_DEBUG_MODE) $write("  [I2C] -->>> %d\t <WRITE>\n",i2c_slv_io_buffer[8:1]);
		end
	endtask

	task transmit_data();
		static bit local_ack;
		static int i, j;
		local_ack = 0;
		for(j=0;j<=128;j++)begin // TODO!!!!!! NEED TO READ FOREVER NOT UPTO 128
		// Get data out of buffer to send
			i2c_slv_io_buffer[8:1] = slave_transmit_buffer.pop_front();

			//Send a byte on sda while clock is high			
			for(i=8;i>=1;i--) begin
				sda_drive <= i2c_slv_io_buffer[i];
				@(posedge scl_i);
				@(negedge scl_i);
			end

			// Check for ack/NACK from master
			sda_drive <= 1'bz;
			@(posedge scl_i) local_ack = sda_i;

			// Debug output
			next_xfer_oracle=i2c_slv_io_buffer[8:1];

			// Check for NACK/DONE or STOP/RESTART CONDTION
			if(local_ack==1'b1) return;
			@(negedge scl_i) if(intr_raised()) return;
		end
		//TODO: Does  this Command ever get hit?????? 
		sda_drive=1'bz;
	endtask


	function bit intr_raised();
		intr_raised = (i2c_slv_interrupt == RAISE_STOP || i2c_slv_interrupt == RAISE_RESTART || i2c_slv_interrupt == RAISE_START);
	endfunction
	
		function bit mon_intr_raised();
		mon_intr_raised = (i2c_mon_interrupt == RAISE_STOP || i2c_mon_interrupt == RAISE_RESTART || i2c_mon_interrupt == RAISE_START);
	endfunction
endinterface
