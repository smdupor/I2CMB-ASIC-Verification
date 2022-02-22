`timescale 1ns/1ps

interface i2c_if       #(
	int ADDR_WIDTH = 32,
	int DATA_WIDTH = 16,
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
	output reg sda_o,
	output byte most_recent_xfer
);
	logic sda_drive=1'b1;
	assign sda_o = sda_drive;

	parameter SCL_RATE = 1e5; // In kHz
	parameter int SCL_PERIOD = 5000;
	//parameter SLAVE_ADDRESS = 7'h44;

	logic [7:0] next_xfer_oracle;
	assign most_recent_xfer = next_xfer_oracle;


	enum bit [1:0] {INTR_RST=2'b00,RAISE_START=2'b01, RAISE_STOP=2'b10, RAISE_RESTART=2'b11} stst;

	longint simulation_cycles;

	bit [8:0] slave_address;

	bit start = 1'b0;
	bit [3:0] status = 2'b0;
	bit [1:0] interrupt = 2'b0;
	int counter;
	bit [8:0] buffer;
	bit we;
	bit nack;
	byte slave_receive_buffer[$];
	byte slave_transmit_buffer[$];

	always @(posedge clk_i) simulation_cycles += 1;

	// ****************************************************************************

	task configure(input bit [8:0] input_addr);
		slave_address = (input_addr << 2);
		start = 1'b0;
	endtask

	task bypass_push_transmit_buf(input byte slv_xmit_value);
		slave_transmit_buffer.push_back(slv_xmit_value);
	endtask

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
		@(posedge clk_i); // Wait for Serial clock to rise to init
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
						interrupt = RAISE_START;
					end
					else begin
						interrupt = RAISE_RESTART;
					end
					start = 1'b1;end
				2'b10: begin // end condition
					interrupt = RAISE_STOP;
					start = 1'b0;
				end
			endcase
		end
	endtask

	task wait_for_start(output bit [8:0] data);

		$display("REPORT SUCCESSFUL BOOT!");
		fork detect_connection_negotiation();

			forever begin
				wait(start == 1'b1 && (interrupt == RAISE_START || interrupt == RAISE_RESTART));
				interrupt = INTR_RST; // Reset the interrupt on detected
				receive_address(); // Handle the request
			end
		join;
	endtask

	task receive_address();
		// Read Address and opcode from serial bus
		for(int i=8;i>=1;i--) begin
			@(posedge scl_i);
			buffer[i] = sda_i;
			@(negedge scl_i) if(intr_raised()) return;
		end
		if(buffer[8:2]==slave_address[8:2] || buffer[8:2]==7'b000_0000) begin
			// SEND THE ACK Back to master upon a match
			sda_drive <= 1'b0;
			@(negedge scl_i) sda_drive <= 1'bz;

			// Select the writeenable to branch from
			we=buffer[1];

			// Branch to handle requested op
			if(!we) receive_data();
			else transmit_data();
		end
	endtask

	task receive_data();
		while(1) begin
			for(int i=8;i>=1;i--) begin
				@(posedge scl_i);
				buffer[i] = sda_i;
				@(negedge scl_i) if(intr_raised()) return;
			end
			sda_drive = 1'b0;
			@(posedge scl_i);
			@(negedge scl_i) sda_drive =1'bz;
			slave_receive_buffer.push_back(buffer[8:1]);
			if(TRANSFER_DEBUG_MODE) $write("  [I2C] -->>> %d\t <WRITE>\n",buffer[8:1]);
		end
	endtask

	task transmit_data();
		static bit local_ack;
		static int i, j;
		local_ack = 0;
		for(j=0;j<=128;j++)begin // TODO!!!!!! NEED TO READ FOREVER NOT UPTO 128
		// Get data out of buffer to send
			buffer[8:1] = slave_transmit_buffer.pop_front();

			//Send a byte on sda while clock is high			
			for(i=8;i>=1;i--) begin
				sda_drive <= buffer[i];
				@(posedge scl_i);
				@(negedge scl_i);
			end

			// Check for ack/NACK from master
			sda_drive <= 1'bz;
			@(posedge scl_i) local_ack = sda_i;

			// Debug output
			next_xfer_oracle=buffer[8:1];

			// Check for NACK/DONE or STOP/RESTART CONDTION
			if(local_ack==1'b1) return;
			@(negedge scl_i) if(intr_raised()) return;
		end
		//TODO: Does  this Command ever get hit?????? 
		sda_drive=1'bz;
	endtask


	function bit intr_raised();
		intr_raised = (interrupt == RAISE_STOP || interrupt == RAISE_RESTART || interrupt == RAISE_START);
	endfunction
endinterface
