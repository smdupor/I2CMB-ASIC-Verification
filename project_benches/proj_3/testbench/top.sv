`timescale 1ns / 10ps

module top();
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
	parameter int I2C_BUS_RATES[16] = {400,350,300,250,200,150,100,90,80,72,60,50,42,35,30,100}; // Bus clocks in kHz for testing at various speeds

	// Physical DUT Interface networks
	bit  clk;
	bit  rst;
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

	// Test Objects
	i2cmb_test tst;

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
		fork i2c_bus.reset(); join_none;
		rst <= 1;
		#133 rst = ~rst;
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
		.rst_i(rst),
		.scl_i(scl), //[NUM_I2C_BUSSES-SELECTED_I2C_BUS-1]),
		.sda_i(sda), //[NUM_I2C_BUSSES-SELECTED_I2C_BUS-1]),
		.sda_o(sda) //[NUM_I2C_BUSSES-SELECTED_I2C_BUS-1])
	);

	// ****************************************************************************
	// Instantiate the Wishbone master Bus Functional Model
	wb_if       #(
	.ADDR_WIDTH(WB_ADDR_WIDTH),
	.DATA_WIDTH(WB_DATA_WIDTH)
	)
	wb_bus (
		// System sigals
		.clk_i(clk),
		.rst_i(rst),
		.irq_i(irq),
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
	) DUT
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


	//_____________________________________________________________________________________\\
	//                           TOP-LEVEL TEST FLOW                                       \\
	//_____________________________________________________________________________________\\
	initial begin : test_flow
		// Create the interfaces and register with the db
		ncsu_config_db#(virtual wb_if )::set("tst.env.wb_agent", wb_bus);
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
