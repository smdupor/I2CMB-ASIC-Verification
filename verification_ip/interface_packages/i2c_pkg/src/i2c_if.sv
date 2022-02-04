`timescale 1us/1ps

interface i2c_if       #(
      int ADDR_WIDTH = 32,                                
      int DATA_WIDTH = 16//,
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
parameter SCL_PERIOD = 5;
parameter SLAVE_ADDRESS = 7'h44;

longint simulation_cycles;

	bit start = 1'b0;
	bit [1:0] status = 2'b00;
	int counter;
	bit [8:0] buffer;
	bit we;
	bit nack;
	byte data[$];

always @(posedge clk_i) simulation_cycles += 1;	

// ****************************************************************************              
task wait_for_start(output bit [8:0] data);
		
	$display("REPORT SUCCESSFUL BOOT!");

	
	while(!start) begin
		@(posedge scl_i);
			 status[0] = sda_i;
			#(SCL_PERIOD) status[1] = sda_i;
			if(status[0]==1 && status[1]==0) begin
				start = 1;
				break;
		end
	end
	$display("START CONDITION DETECTED AT %d", simulation_cycles);
	receive_address(data);
endtask        

task receive_address(output bit [8:0] address);
	$display("Attempting to read address");
	status = 2'b0;
	counter = 8;
	for(int i=8;i>=0;i--) begin
		@(posedge scl_i);
		buffer[i] = sda_i;
	end
	$display("Address read complete, Addr: 0x%h, NAK:0b%b",buffer[8:1],buffer[0]);
	address=buffer;
	if(1) begin
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
	status=2'b11;
	counter=0;
	while(1) begin
		$display("Attempt read byte %d", counter);
		for(int i=8;i>=0;i--) begin
			@(posedge scl_i);
			buffer[i] = sda_i;
		end
		
	data.push_back(buffer[8:1]);	
	counter += 1;
	if(counter == 8) begin
		break;
		end
end
foreach(data[i]) begin
	$display("Received a byte: 0x%h",data[i]);	
end

endtask

task transmit_data();
	$display("Attempt xmit data");
	status[0]=1'b1;
endtask
endinterface
