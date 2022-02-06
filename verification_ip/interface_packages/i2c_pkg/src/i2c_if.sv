`timescale 1ns/1ps

interface i2c_if       #(
	int ADDR_WIDTH = 32,
	int DATA_WIDTH = 16 //,
	//bit [6:0] SLAVE_ADDRESS = 0                          
)
(
	// System sigals
	input wire clk_i,
	input wire rst_i,
	// Master signals
	input wire scl_i,
	input wire sda_i,
	output wire sda_o
);

	parameter SCL_RATE = 1e5; // In kHz
	parameter int SCL_PERIOD = 5000;
	//parameter SLAVE_ADDRESS = 7'h44;

	enum bit [1:0] {INTR_RST=2'b00,RAISE_START=2'b01, RAISE_STOP=2'b10} stst;

	longint simulation_cycles;

	bit [8:0] slave_address;

	bit start = 1'b0;
	bit [3:0] status = 2'b0000;
	bit [1:0] interrupt = 2'b00;
	int counter;
	bit [8:0] buffer;
	bit we;
	bit nack;
	byte test_received_data[$];

	always @(posedge clk_i) simulation_cycles += 1;

	// ****************************************************************************

	task configure(input bit [8:0] input_addr);
		slave_address = input_addr;
		endtask

	task print_report();
		static string s;// = " Received Bytes (0x): ";
		
		static string temp;
		s = " Received Bytes (0x): ";
			foreach(test_received_data[i]) begin
				temp.hextoa(integer'(test_received_data[i]));
				temp=temp.substr(6,7);
				s = {s, temp};
			end
			s = {s, " ."};
			$display("%s", s);
	endtask

	task detect_connection_negotiation();
		static bit [1:0] control;
		static logic [3:0] sample;
		@(posedge clk_i);
		forever begin
			/*@(posedge scl_i);
			status[0] = sda_i;
			#(SCL_PERIOD) status[1] = sda_i;
			* */
			sample[0]=sda_i;
			sample[1]=scl_i;
			#10 sample[2]=sda_i;
			sample[3]=scl_i;
			if(sample[1]==1'b1 && sample[3]==1'b1) begin
				control[0] = sample[0];
				control[1] = sample[2];
			end
			case(control)
				2'b01: begin //start
					interrupt = RAISE_START;
					$display("STart! %d", simulation_cycles);
					start = 1'b1;end
				2'b10: begin //end
					interrupt = RAISE_STOP;
					$display("STop!%d", simulation_cycles);
					start = 1'b0;
				end
			endcase


			/*	if(status[0]==1 && status[1]==0) begin
				start = 1;
				break;
			end*/
		end
	endtask

	task wait_for_start(output bit [8:0] data);

		$display("REPORT SUCCESSFUL BOOT!");
		fork detect_connection_negotiation();

			forever begin
				wait(start == 1'b1 && interrupt == RAISE_START);

				interrupt = INTR_RST;
				$display("START CONDITION DETECTED AT %d", simulation_cycles);
				receive_address(data);
				/*foreach(test_received_data[i]) begin
					$display("Received a byte: 0x%h",test_received_data[i]);
				end*/
				print_report();
			end
		join;
	endtask

	task receive_address(output bit [8:0] address);
		$display("Attempting to read address");
		//status = 2'b0;
		counter = 8;
		for(int i=8;i>=0;i--) begin
			@(posedge scl_i);
			buffer[i] = sda_i;
			while(scl_i == 1'b1) begin
				@(posedge clk_i);
				if(interrupt == RAISE_STOP) begin
					return;
				end
			end
		end
		$display("Address read complete, Addr: 0x%h, NAK:0b%b",buffer[8:2],buffer[0]);
		address=buffer;
		if(buffer[8:2]==slave_address[8:2] || buffer[8:2]==7'b000_0000) begin
			$display("Address match! Receive Data");
			we=buffer[1];
			nack=buffer[0];
			if(!we) begin
				receive_data();
			end
			else begin
				transmit_data();
			end
		end
	endtask

	task receive_data();
		//status=2'b11;
		counter=0;
		while(1) begin
			//$display("Attempt read byte %d", counter);
			for(int i=8;i>=0;i--) begin
				@(posedge scl_i);
				//$display("timestep %d",simulation_cycles);
				buffer[i] = sda_i;
				while(scl_i == 1'b1) begin
					@(posedge clk_i);
					if(interrupt == RAISE_STOP) begin
						return;
					end
				end
			end

			test_received_data.push_back(buffer[8:1]);
		/*	counter += 1;
			if(counter == 16) begin
				break;
			end*/
		end


	endtask

	task transmit_data();
		$display("Attempt xmit data");
		//status[0]=1'b1;
	endtask
endinterface
