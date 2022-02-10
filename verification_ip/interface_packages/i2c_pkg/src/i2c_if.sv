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
	output reg sda_o//, 
	//output byte most_recent_xfer
);
	logic sda_drive=1'b1;
	assign sda_o = sda_drive;

	parameter SCL_RATE = 1e5; // In kHz
	parameter int SCL_PERIOD = 5000;
	//parameter SLAVE_ADDRESS = 7'h44;
	byte most_recent_xfer;
	
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

	//TEMP
//	import banclas::my_str_t;

	
	always @(posedge clk_i) simulation_cycles += 1;

	// ****************************************************************************

	task configure(input bit [8:0] input_addr);
		slave_address = input_addr;
		start = 1'b0;
	endtask
	
	task bypass_push_transmit_buf(input byte slv_xmit_value);
		//$display("Push back %h size before %d", slv_xmit_value, slave_transmit_buffer.size());
		slave_transmit_buffer.push_back(slv_xmit_value);
		
	endtask
	
	task reset_test_buffers();
		slave_receive_buffer.delete();
		slave_transmit_buffer.delete();
	endtask
	
	task print_read_report();
		static string s; // = " Received Bytes (0x): ";

		static string temp;
		s = " \t\t\tSlave Received Bytes (0x): ";
		$display("%s", s);
		foreach(slave_receive_buffer[i]) begin
			//temp.hextoa(integer'(slave_receive_buffer[i]));
			//temp=temp.substr(temp.len-2,temp.len-1);
			//s = {s, temp};
			$display("\t\t\t %d", slave_receive_buffer[i]);
		end
		//s = {s, " ."};
		//$display("%s", s);
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
					if(start==1'b0) begin
						interrupt = RAISE_START;
						//$display("STart! %d", simulation_cycles);
						 end
					else begin
						interrupt = RAISE_RESTART;
						//$display("RE-STart! %d", simulation_cycles); 
						end
					start = 1'b1;end
				2'b10: begin //end
					interrupt = RAISE_STOP;
					//$display("STop!%d", simulation_cycles);
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
				wait(start == 1'b1 && (interrupt == RAISE_START || interrupt == RAISE_RESTART));

				interrupt = INTR_RST;
				//$display("START CONDITION DETECTED AT %d", simulation_cycles);
				receive_address(data);
				/*foreach(test_received_data[i]) begin
					$display("Received a byte: 0x%h",test_received_data[i]);
				end*/
				//print_report();
			end
		join;
	endtask

	task receive_address(output bit [8:0] address);
		//$display("Attempting to read address");
		//status = 2'b0;
		counter = 8;
		for(int i=8;i>=1;i--) begin
			@(posedge scl_i);
			buffer[i] = sda_i;
			@(negedge scl_i) if(intr_raised()) return;
		end
		sda_drive <= 1'b0;
		//sda_drive <= 1'b0;
		@(negedge scl_i) sda_drive <= 1'bz;
		//$display("Address read complete, Addr: 0x%h, Read: 0b%b, NAK:0b%b",buffer[8:2],buffer[1],buffer[0]);
		address=buffer;
		if(buffer[8:2]==slave_address[8:2] || buffer[8:2]==7'b000_0000) begin // Possible bug with all-call and read
			//$display("Address match! Receive Data");
			we=buffer[1];
			nack=1'b0;
			if(!we) begin
			//	$display("Address match! Receive Data");
				receive_data();
			end
			else begin
				//	$display("Address match! Transmit Data");
				transmit_data();
			end
		end
	endtask

	task receive_data();
		//status=2'b11;
		counter=0;
		while(1) begin
			//$display("Attempt read byte %d", counter);
			for(int i=8;i>=1;i--) begin
				@(posedge scl_i);
				//$display("timestep %d",simulation_cycles);
				buffer[i] = sda_i;
				@(negedge scl_i) if(intr_raised()) return;
			end
			sda_drive = 1'b0;
			@(posedge scl_i);
			@(negedge scl_i) sda_drive =1'bz;
			slave_receive_buffer.push_back(buffer[8:1]);
			if(TRANSFER_DEBUG_MODE) $write("  [I2C] -->>> %d\t <WRITE>\n",buffer[8:1]);
			/*	counter += 1;
			if(counter == 16) begin
				break;
			end*/
		end


	endtask

	task transmit_data();
		static bit local_ack;
		static int i, j;
		//$display("Attempt xmit data");
		local_ack = 0;
		
		//	test_received_data.push_back(buffer[8:1]);
		//$display("Actually Attempt xmit data");
		
		for(j=0;j<=128;j++)begin
			//local_ack <= j == 0 ? 1:0;
			buffer[8:1] = slave_transmit_buffer.pop_front();
			
			//$display("Attempt xmit byte %d, contents: %h,  with ack %b", j, buffer[8:1], local_ack);
			for(i=8;i>=1;i--) begin
				
			//	$display("\t\t\t\t\t\t\t\t\t\t\t\twrite %b of %h at timestep %d",buffer[i], buffer[8:1],simulation_cycles);
				sda_drive <= buffer[i] ;
				@(posedge scl_i);
				@(negedge scl_i); //begin if(intr_raised()) return;
				//	sda_drive <= 1'bz;
					//end
			end
			sda_drive <= 1'bz;
			//$display("SDA: %b", sda_i);
			@(posedge scl_i) local_ack = sda_i;
			//$display("SDA: %b", sda_i);
			//$display("Lack: %b", local_ack);
			//if(local_ack==1'b0) $display("\t[I2C]ACK");
			if(TRANSFER_DEBUG_MODE) most_recent_xfer <= byte'(buffer[8:1]);//$write("\t\t\t {DUT}  [I2C] <<<-- %d\n",buffer[8:1]);
			if(local_ack==1'b1) return;//$display("\t[I2C]NACK");
			@(negedge scl_i) if(intr_raised()) return;
			
		end
		sda_drive=1'bz;
	endtask
	
	
	function bit intr_raised();
		intr_raised = (interrupt == RAISE_STOP || interrupt == RAISE_RESTART || interrupt == RAISE_START);
	endfunction
endinterface
