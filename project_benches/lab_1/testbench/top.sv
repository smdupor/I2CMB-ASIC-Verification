`timescale 1ns / 10ps

module top();

	parameter int WB_ADDR_WIDTH = 2;
	parameter int WB_DATA_WIDTH = 8;
	parameter int NUM_I2C_BUSSES = 1;
//	parameter bit [6:0] I2C_SLAVE_ADDR = 7'h44;

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

	logic we_mon;
	logic [WB_ADDR_WIDTH-1:0] adr_mon;
	logic [WB_DATA_WIDTH-1:0] dat_mon;

	logic [WB_ADDR_WIDTH-1:0] adr_in;
	logic [WB_DATA_WIDTH-1:0] dat_in;
	logic we_in;
	
	enum logic[7:0] {ENABLE_CORE_INTERRUPT=8'b11xxxxxx, SET_I2C_BUS=8'bxxxxx110, I2C_START=8'bxxxxx100, 
						I2C_WRITE=8'bxxxxx001, I2C_STOP=8'bxxxxx101} cmd;
	enum bit [2:0] {CSR=2'b00, DPR=2'b01, CMDR=2'b10} dut_reg;

	// FIRE INITIAL LOGIC BLOCKS
	initial clock_generator();
	initial reset_generator();
	initial wishbone_monitor();
	initial test_flow();
	initial simple_receive_data();

	task simple_receive_data();
		bit [8:0] localreg;
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
	endtask


	// ****************************************************************************
	// Define the flow of the simulation
	task test_flow();

		$display("STARTING TEST FLOW");

		#1000 wb_bus.master_write(CSR, ENABLE_CORE_INTERRUPT); 	// Enable core by writing to CSR (EXAMPLE 1)

		wb_bus.master_write(DPR, 8'h00); 				// 005 to DPR (EXAMPLE 3 STEP 1)
		wb_bus.master_write(CMDR, SET_I2C_BUS);		 	// 110 to cmdr STEP 2

		wait(irq==1'b1); 								// STEP 3
		wb_bus.master_read(CMDR, adr_in);
		@(posedge clk);

		wb_bus.master_write(CMDR, I2C_START); 		//100 to cmdr STEP 4
		
		wait(irq==1'b1); 								// STEP 5
		wb_bus.master_read(CMDR, adr_in);
		@(posedge clk);

		wb_bus.master_write(DPR, 8'h44); 				//44 (SLAVE ADDR) to dpr STEP 6
		wb_bus.master_write(CMDR, I2C_WRITE); 		// WRITE Command STEP 7
		
		wait(irq==1'b1); 								// STEP 8
		wb_bus.master_read(CMDR, adr_in);	////TODO: The NACK bit needs to be checked here; if we receive a NACK, need to stop.
		@(posedge clk);

		wb_bus.master_write(DPR, 8'hde); 				//78 (DATA) to dpr STEP 9
		wb_bus.master_write(CMDR, I2C_WRITE); 		// WRITE Command STEP 10
		
		wait_interrupt();
		
		wb_bus.master_write(DPR, 8'had); 				//78 (DATA) to dpr STEP 9
		wb_bus.master_write(CMDR, I2C_WRITE); 	 	// WRITE Command STEP 10
		wait_interrupt();
		wb_bus.master_write(DPR, 8'hbe); 				//78 (DATA) to dpr STEP 9
		wb_bus.master_write(CMDR, I2C_WRITE); 		// WRITE Command STEP 10
		wait_interrupt();
		wb_bus.master_write(DPR, 8'hef); 				//78 (DATA) to dpr STEP 9
		wb_bus.master_write(CMDR, I2C_WRITE); 		// WRITE Command STEP 10
		wait_interrupt();
		wb_bus.master_write(DPR, 8'hfe); 				//78 (DATA) to dpr STEP 9
		wb_bus.master_write(CMDR, I2C_WRITE); 		// WRITE Command STEP 10
		wait_interrupt();
		wb_bus.master_write(DPR, 8'hed); 				//78 (DATA) to dpr STEP 9
		wb_bus.master_write(CMDR, I2C_WRITE); 		// WRITE Command STEP 10
		wait_interrupt();
		wb_bus.master_write(DPR, 8'hbe); 				//78 (DATA) to dpr STEP 9
		wb_bus.master_write(CMDR, I2C_WRITE); 		// WRITE Command STEP 10
		wait_interrupt();
		wb_bus.master_write(DPR, 8'hef); 				//78 (DATA) to dpr STEP 9
		wb_bus.master_write(CMDR, I2C_WRITE); 		// WRITE Command STEP 10
		wait_interrupt();


		wb_bus.master_write(CMDR, I2C_STOP); 		// STOP Command STEP 12
	
		wait(irq==1'b1); 								// STEP 13	
		wb_bus.master_read(CMDR, adr_in);
		
		$display("TASK DONE");


	endtask

task wait_interrupt();
	wait(irq==1'b1); 								// STEP 11
	wb_bus.master_read(2'h2, adr_in);
	@(posedge clk);
endtask

task select_I2C_bus(input bit [7:0] i);

	
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
