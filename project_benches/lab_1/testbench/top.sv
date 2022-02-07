`timescale 1ns / 10ps

module top();
	
	//Physical Parameters
	parameter int WB_ADDR_WIDTH = 2;
	parameter int WB_DATA_WIDTH = 8;
	parameter int NUM_I2C_BUSSES = 1;
	
	parameter bit VERBOSE_DEBUG_MODE=0;

	// Test Parameters
	parameter int I2C_SLAVE_PER_BUS = 1;
	parameter int QTY_WORDS_TO_WRITE=8;
//	parameter bit [6:0] I2C_SLAVE_ADDR = 7'h44;

	// Physical DUT Interface networks
	bit  clk;
	bit  rst = 1'b1;
	wire cyc;
	wire stb;
	wire we;
	tri1 ack;
	wire [WB_ADDR_WIDTH-1:0] adr;
	wire [WB_DATA_WIDTH-1:0] dat_wr_o;
	wire [WB_DATA_WIDTH-1:0] dat_rd_i;
	wire irq;
	tri  [NUM_I2C_BUSSES-1:0] scl;
	tri  [NUM_I2C_BUSSES-1:0] sda;
	//triand  [NUM_I2C_BUSSES-1:0] sda_o;

	// Test Logical Buffers
	logic we_mon;
	logic [WB_ADDR_WIDTH-1:0] adr_mon;
	logic [WB_DATA_WIDTH-1:0] dat_mon;

	logic [WB_ADDR_WIDTH-1:0] adr_in;
	logic [WB_DATA_WIDTH-1:0] dat_in;
	logic [WB_DATA_WIDTH-1:0] buf_in;
	logic we_in;
	
	// Device Configuration and Command Logics
	enum logic[7:0] {ENABLE_CORE_INTERRUPT=8'b11xxxxxx, SET_I2C_BUS=8'bxxxxx110, I2C_START=8'bxxxxx100, 
						I2C_WRITE=8'bxxxxx001, I2C_STOP=8'bxxxxx101, READ_WITH_NACK=8'bxxxxx011, READ_WITH_ACK=8'bxxxxx010} cmd;
	enum bit [1:0] {CSR=2'b00, DPR=2'b01, CMDR=2'b10} dut_reg;
	bit [8:0] i2c_slave_addr = 9'h12;
	
	// Test Bank Data Buffers
	bit [7:0] output_buffer [QTY_WORDS_TO_WRITE];
	byte input_buffer [QTY_WORDS_TO_WRITE * 2]; 

	// FIRE INITIAL LOGIC BLOCKS
	initial clock_generator();
	initial reset_generator();
	initial populate_test_buffers();
	initial wishbone_monitor();
	initial test_flow();
	initial simple_receive_data();

	task populate_test_buffers();
		/*output_buffer[0]=8'hff;
		output_buffer[1]=8'h1;
		output_buffer[2]=8'hfe;
		output_buffer[3]=8'h2;
		output_buffer[4]=8'hfd;
		output_buffer[5]=8'h3;
		output_buffer[6]=8'hfc;
		output_buffer[7]=8'h4;*/
		output_buffer[0]=8'hff;
		output_buffer[1]=8'hfe;
		output_buffer[2]=8'hfd;
		output_buffer[3]=8'hfc;
		output_buffer[4]=8'hfb;
		output_buffer[5]=8'hfa;
		output_buffer[6]=8'hf9;
		output_buffer[7]=8'hf8;
		
		
			
	endtask

	task simple_receive_data();
		bit [8:0] localreg;
		i2c_slave_addr = i2c_slave_addr << 2;
		i2c_slave.configure(i2c_slave_addr);
		i2c_slave.wait_for_start(localreg);	
	endtask

	// ****************************************************************************
	task clock_generator();

		clk <= 1;
		forever #5 clk = ~clk;
	endtask


	// ****************************************************************************
	task reset_generator();
		rst <= 1;
		#133 rst = ~rst;
	endtask


	// ****************************************************************************
	// Monitor Wishbone bus and display transfers in the transcript
	task wishbone_monitor();
		if(VERBOSE_DEBUG_MODE) begin
		forever begin
			#10 wb_bus.master_monitor(adr_mon, dat_mon, we_mon);
			if(adr_mon == 0) begin
				$display("Address: CSR(%h) Data: %b we: %h", adr_mon, dat_mon, we_mon);
			end else if(adr_mon == 1) begin
				$display("Address: DPR (%h) Data: %h we: %h", adr_mon, dat_mon, we_mon);

			end else if(adr_mon == 2) begin
				$display("Address: CMDR (%h) Data: %h we: %h", adr_mon, dat_mon, we_mon);
			end else begin
				$display("Address: %h Data: %h we: %h", adr_mon, dat_mon, we_mon);
			end
		end
		end
	endtask


	// ****************************************************************************
	// Define the flow of the simulation
	task test_flow();
		logic [7:0] short_buffer;
		$display("STARTING TEST FLOW");

		@(negedge rst) wb_bus.master_write(CSR, ENABLE_CORE_INTERRUPT); 	// Enable core by writing to CSR (EXAMPLE 1)

		select_I2C_bus(8'h00);
		repeat(2) begin
		issue_start_command();
		transmit_slave_address(i2c_slave_addr[8:1]);
		
		// Write contents of "output Buffer" to selected I2C Slave in a single stream
		for(int i=0;i<QTY_WORDS_TO_WRITE;i++) begin
			write_data_byte(output_buffer[i]);
		end

		wb_bus.master_write(CMDR, I2C_STOP); 		// STOP Command STEP 12
		wait_interrupt();
		
		end
		$display(" WRITE ALL TASK DONE, Begin READ ALL");
		#1000000 issue_start_command();
		transmit_slave_address(i2c_slave_addr[8:1]);
		write_data_byte(output_buffer[7]);
		issue_start_command();
		request_read_from_address(i2c_slave_addr[8:1]);
		for(int i=0;i<=15;i++) begin
			//$display("\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\tAttempt WB read %d",i);
			read_data_byte(short_buffer);
			//$display("\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\tEmplacing %h into array at %d",short_buffer, i);
			input_buffer[i]=short_buffer;
		end
		wb_bus.master_write(CMDR, I2C_STOP); 		// STOP Command STEP 12
		wait_interrupt();
		$display("READ ALL TASK DONE.");
		print_read_report;
	endtask
	
	task print_read_report();
	//	static string s;// = " Received Bytes (0x): ";
		//static string temp;
		//s = " Master Read Received Bytes (0x): ";
			foreach(input_buffer[i]) begin
			//	temp.hextoa(integer'(input_buffer[i]));
				//temp=temp.substr(6,7);
				//s = {s, temp};
				$display("\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\tReceived at master %h  VS %h", input_buffer[i], output_buffer[i]);
			end
			//s = {s, " ."};
			//$display("%s", s);
			endtask

task wait_interrupt();
	wait(irq==1'b1); 								// STEP 11
	wb_bus.master_read(2'h2, buf_in);
	//$display("\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\tBufferDump %b", buf_in);
	//@(posedge clk);
endtask

task wait_interrupt_with_NACK();
	wait(irq==1'b1); 								// STEP 11
	wb_bus.master_read(2'h2, buf_in);
	if(buf_in[6]==1'b1) $display("\t[ WB ] NACK");
	//$display("\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\tBufferDump %b", buf_in);
	//@(posedge clk);
endtask

task select_I2C_bus(input bit [7:0] selected_bus);
		wb_bus.master_write(DPR, selected_bus); 				// 005 to DPR (EXAMPLE 3 STEP 1)
		wb_bus.master_write(CMDR, SET_I2C_BUS);		 	// 110 to cmdr STEP 2

		wait_interrupt;
endtask

task issue_start_command();
		wb_bus.master_write(CMDR, I2C_START); 		//100 to cmdr STEP 4
		wait_interrupt();
endtask

task transmit_slave_address(input bit [7:0] addr); // Request a write
		addr[0]=1'b0;
		wb_bus.master_write(DPR, addr); 				//44 (SLAVE ADDR) to dpr STEP 6
		wb_bus.master_write(CMDR, I2C_WRITE); 		// WRITE Command STEP 7
		
	wait_interrupt_with_NACK();	// In case of a down/inresponsive slave, we'd get a nack//TODO: Handle NACK
		
endtask

task request_read_from_address(input bit [7:0] addr);
		addr[0]=1'b1;
		wb_bus.master_write(DPR, addr); 				//44 (SLAVE ADDR) to dpr STEP 6
		wb_bus.master_write(CMDR, I2C_WRITE); 		// WRITE Command STEP 7
		
		wait_interrupt_with_NACK();	// In case of a down/inresponsive slave, we'd get a nack//TODO: Handle NACK
		
		endtask

task write_data_byte(input bit [7:0] data);
			wb_bus.master_write(DPR, data); 				//78 (DATA) to dpr STEP 9
		wb_bus.master_write(CMDR, I2C_WRITE); 		// WRITE Command STEP 10
		
		wait_interrupt_with_NACK();
	endtask
task read_data_byte(output bit [7:0] iobuf);
			
	wb_bus.master_write(CMDR, READ_WITH_ACK); 		// WRITE Command STEP 10
	wait_interrupt_with_NACK();
	wb_bus.master_read(DPR, iobuf); 				//78 (DATA) to dpr STEP 9
	//$display("\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\tWISHBONE REGISTER READS %h", iobuf);	
		
	endtask
	
	// ****************************************************************************
	// Instatiate the slave I2C BFM
	i2c_if		#(
		.ADDR_WIDTH(WB_ADDR_WIDTH),
		.DATA_WIDTH(WB_DATA_WIDTH)//,
		//.SLAVE_ADDRESS(I2C_SLAVE_ADDR)
	)
	i2c_slave (
		.clk_i(clk),
		.rst_i(rst),
		.scl_i(scl),
		.sda_i(sda),
		.sda_o(sda)
	);
	
	// Instantiate the Wishbone master Bus Functional Model
	wb_if       #(
	.ADDR_WIDTH(WB_ADDR_WIDTH),
	.DATA_WIDTH(WB_DATA_WIDTH)
	)
	wb_bus (
		// System sigals
		.clk_i(clk),
		.rst_i(rst),
		// Master signals
		.cyc_o(cyc),
		.stb_o(stb),
		.ack_i(ack),
		.adr_o(adr),
		.we_o(we),
		// Slave signals
		.cyc_i(),
		.stb_i(),
		.ack_o(),
		.adr_i(),
		.we_i(),
		// Shred signals
		.dat_o(dat_wr_o),
		.dat_i(dat_rd_i)
	);

	// ****************************************************************************
	// Instantiate the DUT - I2C Multi-Bus Controller
	\work.iicmb_m_wb(str) #(.g_bus_num(NUM_I2C_BUSSES)) DUT
	(
		// ------------------------------------
		// -- Wishbone signals:
		.clk_i(clk), // in    std_logic;                            -- Clock
		.rst_i(rst), // in    std_logic;                            -- Synchronous reset (active high)
		// -------------
		.cyc_i(cyc), // in    std_logic;                            -- Valid bus cycle indication
		.stb_i(stb), // in    std_logic;                            -- Slave selection
		.ack_o(ack), //   out std_logic;                            -- Acknowledge output
		.adr_i(adr), // in    std_logic_vector(1 downto 0);         -- Low bits of Wishbone address
		.we_i(we), // in    std_logic;                            -- Write enable
		.dat_i(dat_wr_o), // in    std_logic_vector(7 downto 0);         -- Data input
		.dat_o(dat_rd_i), //   out std_logic_vector(7 downto 0);         -- Data output
		// ------------------------------------
		// ------------------------------------
		// -- Interrupt request:
		.irq(irq), //   out std_logic;                            -- Interrupt request
		// ------------------------------------
		// ------------------------------------
		// -- I2C interfaces:
		.scl_i(scl), // in    std_logic_vector(0 to g_bus_num - 1); -- I2C Clock inputs
		.sda_i(sda), // in    std_logic_vector(0 to g_bus_num - 1); -- I2C Data inputs
		.scl_o(scl), //   out std_logic_vector(0 to g_bus_num - 1); -- I2C Clock outputs
		.sda_o(sda) //   out std_logic_vector(0 to g_bus_num - 1)  -- I2C Data outputs
		// ------------------------------------
	);


endmodule
