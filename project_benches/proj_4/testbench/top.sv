`timescale 1ns / 10ps

module top(); //#(I2C_MAX_BUS_RATE = 400);
	import i2c_types_pkg::*;
	import printing_pkg::*;
	import ncsu_pkg::*;
	import i2c_pkg::*;
	import wb_pkg::*;
	import i2cmb_env_pkg::*;

	//Physical Parameters 
	parameter int WB_ADDR_WIDTH = 2;
	parameter int WB_DATA_WIDTH = 8;
	parameter int TOP_I2C_ADDR_WIDTH = 7;
	parameter int TOP_I2C_DATA_WIDTH = 8;
	parameter int NUM_I2C_BUSSES = 16;
	parameter int I2C_BUS_RATES[16] = {400,350,300,250,200,150,100,90,85,80,75,70,60,50,40,99}; // Bus clocks in kHz for testing at various speeds
	parameter int I2C_MAX_BUS_RATE = 400;
	parameter int I2C_STD_BUS_RATE = 400;

	// Physical DUT Interface networks
	bit  clk;
	bit  rst;
	tri rst_o[3];
	wire cyc[3];
	wire stb[3];
	wire we[3];
	tri1 ack[3];
	wire [WB_ADDR_WIDTH-1:0] adr[3];
	wire [WB_DATA_WIDTH-1:0] dat_wr_o[3];
	wire [WB_DATA_WIDTH-1:0] dat_rd_i[3];
	wire irq[3];
	tri  [NUM_I2C_BUSSES-1:0] scl;
	tri  [NUM_I2C_BUSSES-1:0] sda;

	// Test Objects
	i2cmb_test tst;

	//15214930

	//_____________________________________________________________________________________\\
	//                           SYSTEM-LEVEL SIGNAL GENERATORS                            \\
	//_____________________________________________________________________________________\\

	// ****************************************************************************
	// System-level clock: Generate a 10ns system clock which drives DUT logic
	// ****************************************************************************
	initial begin : clk_generator
		clk <= 1;
		forever #5 clk = ~clk;
	end

	// ****************************************************************************
	// Hard Reset: Reset BOTH the DUT and the I2C Slave BFM
	// ****************************************************************************
	initial begin : rst_generator
		string trans_name;
		if ( !$value$plusargs("GEN_TRANS_TYPE=%s", trans_name)) begin
			$display("FATAL: +GEN_TRANS_TYPE plusarg not found on command line");
			$fatal;
		end
		
		fork i2c_bus.reset(); join_none;		// Tell the i2c bfm to reset.

		fork
		begin rst <= 1;							// Only used by components listening to this
			#133 rst = ~rst;					// Bit. DUTs actually listen to interface 
			#10 rst = 1'bz;						// driven resets.
		end
		wb_bus_16_range.force_hard_reset();		// Allow interfaces to power DUT resets
		wb_bus_16_max.force_hard_reset();		// so that reset signals can be injected
		wb_bus_1_max.force_hard_reset();		// into the overall test flow
		join
		/*if(trans_name == "i2cmb_generator_arb_loss_restart") begin
			wb_bus_1_max.disable_rst_driver();		// But only use on certain tests, where
			wb_bus_16_range.disable_rst_driver();	// Only one interface may drive a reset
		end											// at a time.*/
	end

	//_____________________________________________________________________________________\\
	//                           INTERFACE/DUT INSTANTIATIONS                              \\
	//_____________________________________________________________________________________\\

	// ****************************************************************************
	// Instantiate the slave I2C Bus Functional Model
	i2c_if		#(
	.I2C_ADDR_WIDTH(TOP_I2C_ADDR_WIDTH),
	.I2C_DATA_WIDTH(TOP_I2C_DATA_WIDTH)
	)
	i2c_bus (
		.clk_i(clk),
		.rst_i(rst_o[1]),
		.scl_i(scl), //[NUM_I2C_BUSSES-SELECTED_I2C_BUS-1]),
		.sda_i(sda), //[NUM_I2C_BUSSES-SELECTED_I2C_BUS-1]),
		.sda_o(sda), //[NUM_I2C_BUSSES-SELECTED_I2C_BUS-1])
		.scl_o(scl)
	);

	// ****************************************************************************
	// Instantiate the Wishbone master Bus Functional Model
	wb_if       #(
	.ADDR_WIDTH(WB_ADDR_WIDTH),
	.DATA_WIDTH(WB_DATA_WIDTH)
	)
	wb_bus_16_range (
		// System sigals
		.clk_i(clk),
		.rst_i(rst),
		.rst_o(rst_o[0]),
		.irq_i(irq[0]),
		// Master signals
		.cyc_o(cyc[0]),
		.stb_o(stb[0]),
		.ack_i(ack[0]),
		.adr_o(adr[0]),
		.we_o(we[0]),
		// Slave signals
		.cyc_i(),
		.stb_i(),
		.ack_o(),
		.adr_i(),
		.we_i(),
		// Shred signals
		.dat_o(dat_wr_o[0]),
		.dat_i(dat_rd_i[0])
	);

		wb_if       #(
	.ADDR_WIDTH(WB_ADDR_WIDTH),
	.DATA_WIDTH(WB_DATA_WIDTH)
	)
	wb_bus_16_max (
		// System sigals
		.clk_i(clk),
		.rst_i(rst),
		.rst_o(rst_o[1]),
		.irq_i(irq[1]),
		// Master signals
		.cyc_o(cyc[1]),
		.stb_o(stb[1]),
		.ack_i(ack[1]),
		.adr_o(adr[1]),
		.we_o(we[1]),
		// Slave signals
		.cyc_i(),
		.stb_i(),
		.ack_o(),
		.adr_i(),
		.we_i(),
		// Shred signals
		.dat_o(dat_wr_o[1]),
		.dat_i(dat_rd_i[1])
	);

	wb_if       #(
	.ADDR_WIDTH(WB_ADDR_WIDTH),
	.DATA_WIDTH(WB_DATA_WIDTH)
	)
	wb_bus_1_max (
		// System sigals
		.clk_i(clk),
		.rst_i(rst),
		.rst_o(rst_o[2]),
		.irq_i(irq[2]),
		// Master signals
		.cyc_o(cyc[2]),
		.stb_o(stb[2]),
		.ack_i(ack[2]),
		.adr_o(adr[2]),
		.we_o(we[2]),
		// Slave signals
		.cyc_i(),
		.stb_i(),
		.ack_o(),
		.adr_i(),
		.we_i(),
		// Shred signals
		.dat_o(dat_wr_o[2]),
		.dat_i(dat_rd_i[2])
	);


	// ****************************************************************************
	// Instantiate the DUT - I2C Multi-Bus Controller
	// All busses MAX BUS RATE (cmdline configurable)
	\work.iicmb_m_wb(str) #(.g_bus_num(NUM_I2C_BUSSES),
	.g_f_scl_0(I2C_MAX_BUS_RATE),
	.g_f_scl_1(I2C_MAX_BUS_RATE),
	.g_f_scl_2(I2C_MAX_BUS_RATE),
	.g_f_scl_3(I2C_MAX_BUS_RATE),
	.g_f_scl_4(I2C_MAX_BUS_RATE),
	.g_f_scl_5(I2C_MAX_BUS_RATE),
	.g_f_scl_6(I2C_MAX_BUS_RATE),
	.g_f_scl_7(I2C_MAX_BUS_RATE),
	.g_f_scl_8(I2C_MAX_BUS_RATE),
	.g_f_scl_9(I2C_MAX_BUS_RATE),
	.g_f_scl_a(I2C_MAX_BUS_RATE),
	.g_f_scl_b(I2C_MAX_BUS_RATE),
	.g_f_scl_c(I2C_MAX_BUS_RATE),
	.g_f_scl_d(I2C_MAX_BUS_RATE),
	.g_f_scl_e(I2C_MAX_BUS_RATE),
	.g_f_scl_f(I2C_MAX_BUS_RATE)
	) DUT_16_max
	(
		// ------------------------------------
		// -- Wishbone signals:
		.clk_i(clk), // in    std_logic;                            -- Clock
		.rst_i(rst_o[1]), // in    std_logic;                            -- Synchronous reset (active high)
		// -------------
		.cyc_i(cyc[1]), // in    std_logic;                            -- Valid bus cycle indication
		.stb_i(stb[1]), // in    std_logic;                            -- Slave selection
		.ack_o(ack[1]), //   out std_logic;                            -- Acknowledge output
		.adr_i(adr[1]), // in    std_logic_vector(1 downto 0);         -- Low bits of Wishbone address
		.we_i(we[1]), // in    std_logic;                            -- Write enable
		.dat_i(dat_wr_o[1]), // in    std_logic_vector(7 downto 0);         -- Data input
		.dat_o(dat_rd_i[1]), //   out std_logic_vector(7 downto 0);         -- Data output
		// ------------------------------------
		// ------------------------------------
		// -- Interrupt request:
		.irq(irq[1]), //   out std_logic;                            -- Interrupt request
		// ------------------------------------
		// ------------------------------------
		// -- I2C interfaces:
		.scl_i(scl), // in    std_logic_vector(0 to g_bus_num - 1); -- I2C Clock inputs
		.sda_i(sda), // in    std_logic_vector(0 to g_bus_num - 1); -- I2C Data inputs
		.scl_o(scl), //   out std_logic_vector(0 to g_bus_num - 1); -- I2C Clock outputs
		.sda_o(sda) //   out std_logic_vector(0 to g_bus_num - 1)  -- I2C Data outputs
		// ------------------------------------
	);

	// Instance with all busses at different rates
	\work.iicmb_m_wb(str) #(.g_bus_num(NUM_I2C_BUSSES),
	.g_f_scl_0(I2C_BUS_RATES[0]),
	.g_f_scl_1(I2C_BUS_RATES[1]),
	.g_f_scl_2(I2C_BUS_RATES[2]),
	.g_f_scl_3(I2C_BUS_RATES[3]),
	.g_f_scl_4(I2C_BUS_RATES[4]),
	.g_f_scl_5(I2C_BUS_RATES[5]),
	.g_f_scl_6(I2C_BUS_RATES[6]),
	.g_f_scl_7(I2C_BUS_RATES[7]),
	.g_f_scl_8(I2C_BUS_RATES[8]),
	.g_f_scl_9(I2C_BUS_RATES[9]),
	.g_f_scl_a(I2C_BUS_RATES[10]),
	.g_f_scl_b(I2C_BUS_RATES[11]),
	.g_f_scl_c(I2C_BUS_RATES[12]),
	.g_f_scl_d(I2C_BUS_RATES[13]),
	.g_f_scl_e(I2C_BUS_RATES[14]),
	.g_f_scl_f(I2C_BUS_RATES[15])
	) DUT_16_speed_ranged
	(
		// ------------------------------------
		// -- Wishbone signals:
		.clk_i(clk), // in    std_logic;                            -- Clock
		.rst_i(rst_o[0]), // in    std_logic;                            -- Synchronous reset (active high)
		// -------------
		.cyc_i(cyc[0]), // in    std_logic;                            -- Valid bus cycle indication
		.stb_i(stb[0]), // in    std_logic;                            -- Slave selection
		.ack_o(ack[0]), //   out std_logic;                            -- Acknowledge output
		.adr_i(adr[0]), // in    std_logic_vector(1 downto 0);         -- Low bits of Wishbone address
		.we_i(we[0]), // in    std_logic;                            -- Write enable
		.dat_i(dat_wr_o[0]), // in    std_logic_vector(7 downto 0);         -- Data input
		.dat_o(dat_rd_i[0]), //   out std_logic_vector(7 downto 0);         -- Data output
		// ------------------------------------
		// ------------------------------------
		// -- Interrupt request:
		.irq(irq[0]), //   out std_logic;                            -- Interrupt request
		// ------------------------------------
		// ------------------------------------
		// -- I2C interfaces:
		.scl_i(scl), // in    std_logic_vector(0 to g_bus_num - 1); -- I2C Clock inputs
		.sda_i(sda), // in    std_logic_vector(0 to g_bus_num - 1); -- I2C Data inputs
		.scl_o(scl), //   out std_logic_vector(0 to g_bus_num - 1); -- I2C Clock outputs
		.sda_o(sda) //   out std_logic_vector(0 to g_bus_num - 1)  -- I2C Data outputs
		// ------------------------------------
	);

	// Instance with just a single bus.
		\work.iicmb_m_wb(str) #(.g_bus_num(1),
			.g_f_scl_0(I2C_MAX_BUS_RATE)
		) DUT_1_max
	(
		// ------------------------------------
		// -- Wishbone signals:
		.clk_i(clk), // in    std_logic;                            -- Clock
		.rst_i(rst_o[2]), // in    std_logic;                            -- Synchronous reset (active high)
		// -------------
		.cyc_i(cyc[2]), // in    std_logic;                            -- Valid bus cycle indication
		.stb_i(stb[2]), // in    std_logic;                            -- Slave selection
		.ack_o(ack[2]), //   out std_logic;                            -- Acknowledge output
		.adr_i(adr[2]), // in    std_logic_vector(1 downto 0);         -- Low bits of Wishbone address
		.we_i(we[2]), // in    std_logic;                            -- Write enable
		.dat_i(dat_wr_o[2]), // in    std_logic_vector(7 downto 0);         -- Data input
		.dat_o(dat_rd_i[2]), //   out std_logic_vector(7 downto 0);         -- Data output
		// ------------------------------------
		// ------------------------------------
		// -- Interrupt request:
		.irq(irq[2]), //   out std_logic;                            -- Interrupt request
		// ------------------------------------
		// ------------------------------------
		// -- I2C interfaces:
		.scl_i(scl[15]), // in    std_logic_vector(0 to g_bus_num - 1); -- I2C Clock inputs
		.sda_i(sda[15]), // in    std_logic_vector(0 to g_bus_num - 1); -- I2C Data inputs
		.scl_o(scl[15]), //   out std_logic_vector(0 to g_bus_num - 1); -- I2C Clock outputs
		.sda_o(sda[15]) //   out std_logic_vector(0 to g_bus_num - 1)  -- I2C Data outputs
		// ------------------------------------
	);


	


	//_____________________________________________________________________________________\\
	//                           TOP-LEVEL TEST FLOW                                       \\
	//_____________________________________________________________________________________\\
	initial begin : test_flow
		// Create the interfaces and register with the db
		ncsu_config_db#(virtual wb_if )::set("tst.env.wb_agent_16_ranged", wb_bus_16_range);
		ncsu_config_db#(virtual wb_if )::set("tst.env.wb_agent_16_max", wb_bus_16_max);
		ncsu_config_db#(virtual wb_if )::set("tst.env.wb_agent_1_max", wb_bus_1_max);
		ncsu_config_db#(virtual i2c_if )::set("tst.env.i2c_agent", i2c_bus);

		// Create test object
		tst = new("tst",null);

		// Handle argument-passable verbosity
		handle_verbosity_plusarg();

		// Initiate the test
		tst.run();

		// Display authorship Banner
		display_footer_banner();

		// Exit the sim
		$finish;
	end

	// ****************************************************************************
	// Handling of VERBOSITY LEVEL plusarg to turn on/off levels of global
	// 		verbosity based on sim argument.
	// ****************************************************************************
	function void handle_verbosity_plusarg();
		string s;
		if(tst == null) begin
			$display("Verbosity configuration called before test object instantiation; Exiting");
			$fatal;
		end

		if ( !$value$plusargs("VERBOSITY_LEVEL=%s", s)) begin
			// No argument passed, default to ncsu-medium verbosity
			tst.set_global_verbosity(NCSU_MEDIUM);
		end
		else begin
			$display(s);
			//$fatal;
			case(s)
				"NONE":tst.set_global_verbosity(NCSU_NONE);
				"LOW":tst.set_global_verbosity(NCSU_LOW);
				"MEDIUM":tst.set_global_verbosity(NCSU_MEDIUM);
				"HIGH":tst.set_global_verbosity(NCSU_HIGH);
				"DEBUG":tst.set_global_verbosity(NCSU_DEBUG);
				default: tst.set_global_verbosity(NCSU_NONE);
			endcase
		end
	endfunction

endmodule
