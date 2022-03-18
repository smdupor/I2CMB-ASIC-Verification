`timescale 1ns / 10ps


module top();
	import i2c_types_pkg::*;
	import printing_pkg::*;
	import ncsu_pkg::*;
	import i2c_pkg::*;
	import wb_pkg::*;
	import i2cmb_env_pkg::*;

	//Physical P    arameters 
	parameter int WB_ADDR_WIDTH = 2;
	parameter int WB_DATA_WIDTH = 8;
	parameter int TOP_I2C_ADDR_WIDTH = 7;
	parameter int TOP_I2C_DATA_WIDTH = 8;
	parameter int NUM_I2C_BUSSES = 16;
	parameter int I2C_BUS_RATES[16] = {400,350,300,250,200,150,100,90,80,72,60,50,42,35,30,100}; // Bus clocks in kHz for testing at various speeds
	parameter int SELECTED_I2C_BUS = 2;
	parameter int SELECTED_I2C_SLAVE_ADDRESS = 18;

	// Verbosity Debug Printing Levels
	parameter bit VERBOSE_DEBUG_MODE = 0;
	parameter bit TOP_TRANSFER_DEBUG_MODE = 0;
	parameter bit ENABLE_WISHBONE_VERBOSE_DEBUG = 0;
	parameter bit ENABLE_WISHBONE_SIMPLE_DEBUG = 1;

	// Test Parameters
	parameter int I2C_SLAVE_PER_BUS = 2;
	parameter int QTY_WORDS_TO_WRITE=32;
	i2cmb_test tst;

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

	// Test Logical Buffers
	logic we_mon;
	logic [WB_ADDR_WIDTH-1:0] adr_mon;
	logic [WB_DATA_WIDTH-1:0] dat_mon;
	logic [WB_ADDR_WIDTH-1:0] adr_in;
	logic [WB_DATA_WIDTH-1:0] dat_in;
	logic [WB_DATA_WIDTH-1:0] buf_in;
	logic we_in;
	byte slv_most_recent_xfer;

	// Data validation queues, holds unaltered copies of all transfers from pre-initiation
	bit [7:0] validation_write_buffer[$];
	bit [7:0] validation_read_buffer[$];

	// Device/Wishbone Configuration and Command Logics
	enum logic[7:0] {ENABLE_CORE_INTERRUPT=8'b11xxxxxx,DISABLE_CORE=8'b0xxxxxxx,
		SET_I2C_BUS=8'bxxxxx110, I2C_START=8'bxxxxx100, I2C_WRITE=8'bxxxxx001,
		I2C_STOP=8'bxxxxx101, READ_WITH_NACK=8'bxxxxx011, READ_WITH_ACK=8'bxxxxx010} cmd;

	enum logic[2:0] {M_SET_I2C_BUS=3'b110, M_I2C_START=3'b100, M_I2C_WRITE=3'b001,
		M_I2C_STOP=3'b101, M_READ_WITH_NACK=3'b011, M_READ_WITH_ACK=3'b010} mon;


	enum bit [1:0] {CSR=2'b00, DPR=2'b01, CMDR=2'b10} dut_reg;

	bit [8:0] i2c_slave_addr;

	// Tuple datatype to store a combination of an address and a single byte of data from a transfer
	typedef struct {
		bit [6:0] address;
		bit [7:0] data;
	} recv_tuple_t;

	// Driver Data Buffers
	bit [7:0] master_transmit_buffer [$];
	recv_tuple_t master_receive_buffer [$];
	bit [7:0] slave_read_transmit_buffer[2][$];

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
		i2c_slave_addr = SELECTED_I2C_SLAVE_ADDRESS;
		fork i2c_bus.reset_and_configure(i2c_slave_addr); join_none;
		rst <= 1;
		#133 rst = ~rst;
	end




	//_____________________________________________________________________________________\\
	//                           CMD/SIGNAL MONITORING                                     \\
	//_____________________________________________________________________________________\\

	// ****************************************************************************
	// Monitor Wishbone bus and display transfers in the transcript
	// 			NB: Control of monitoring level is parameterized and BY DEFAULT,
	// 			Wishbone-transfer monitoring is disabled at this time.
	// ****************************************************************************
	/*initial begin : wishbone_monitor
		static bit transfer_in_progress, print_next_read, address_state;
		static bit [7:0] last_dpr;
		string s,t;
		forever begin
			// Initiate Wishbone master monitoring no more than once per system clock
			@(posedge clk) wb_bus.master_monitor(adr_mon, dat_mon, we_mon);
			if(adr_mon == 0) begin
				// Monitor for DUT Enable/Disable
				if(ENABLE_WISHBONE_VERBOSE_DEBUG) $display("[WB] CSR(%h) Data: %b we: %h", adr_mon, dat_mon, we_mon);
			end
			else if(adr_mon == 1) begin // Monitor for commands passed to DUT
				if(ENABLE_WISHBONE_SIMPLE_DEBUG) begin
					last_dpr = dat_mon;
					if(print_next_read) begin // Swallow interrupt reads and print transfers only
						print_next_read = 1'b0;
						$display("\t\t\t\t\t\t\t\tWB_BUS Transfer  READ Data: %d", last_dpr);
					end
				end
				//	Verbose mode: Show all register reads
				if(ENABLE_WISHBONE_VERBOSE_DEBUG) $display("[WB] DPR (%h) Data: %b we: %h", adr_mon, dat_mon, we_mon);
			end
			else if(adr_mon == 2) begin
				if(ENABLE_WISHBONE_SIMPLE_DEBUG) begin
					// Detect start condition and prepare start && address report
					if(dat_mon[2:0] == M_I2C_START && we_mon) begin
						s = "\t\t\t\t\t\t\t\tWB_BUS: Sent START";
						transfer_in_progress = 1'b1;
						address_state = 1'b1;
					end
					// Detect stop condition and immediately report 
					if(dat_mon[2:0] == M_I2C_STOP && we_mon) begin
						$display("\t\t\t\t\t\t\t\tWB_BUS: Sent STOP");
						transfer_in_progress = 1'b0;
					end
					// Determine whether write action is requesting an address transmit,  a write, or a read
					if(dat_mon[2:0] == M_I2C_WRITE && we_mon && !address_state) begin $display("\t\t\t\t\t\t\t\tWB_BUS: Transfer WRITE Data : %d", last_dpr);end
					else if(dat_mon[2:0] == M_I2C_WRITE && we_mon) begin
						t.itoa(integer'(last_dpr[8:1]));
						if(last_dpr[0]==1'b0) s = {s," && Address ", t," : req. WRITE"};
						else s = {s," && Address ", t, " : req. READ"};
						$display("%s",s);
						address_state = 1'b0;
					end
					// Detect that we are swallowing an interrupt read for a COMMAND READ and notify statemachine
					if(dat_mon[2:0] == M_READ_WITH_ACK || dat_mon[2:0] == M_READ_WITH_NACK) print_next_read = 1'b1;
				end
				// If verbose debugging, display all command register actions
				if(ENABLE_WISHBONE_VERBOSE_DEBUG) $display("[WB] CMDR (%h) Data: %b we: %h", adr_mon, dat_mon, we_mon);
			end
			else begin
				// if verbose debugging, display all non-specific commands outside of prior decision tree
				if(ENABLE_WISHBONE_VERBOSE_DEBUG) $display("Address: %h Data: %b we: %h", adr_mon, dat_mon, we_mon);
			end
		end
	end*/

	// ****************************************************************************
	// Monitor I2C Bus and display all transfers with DIRECTION, associated ADDRESS, 
	// and captured DATA for each transfer. Messages are grouped by complete transfer.
	// ****************************************************************************
	/*initial begin : monitor_i2c_bus
		bit[TOP_I2C_ADDR_WIDTH-1:0] i2mon_addr;
		i2c_op_t i2mon_op;
		bit [TOP_I2C_DATA_WIDTH-1:0] i2mon_data [];
		string s,temp;
		s = "";

		forever begin
			// Request transfer info from i2c BFM
			i2c_bus.monitor(i2mon_addr, i2mon_op, i2mon_data);

			// Format header based on WRITE or READ
			if(i2mon_op == I2_WRITE) begin
				s = "I2C_BUS WRITE Transfer To   Address: ";
			end
			else begin
				s = "I2C_BUS READ  Transfer From Address: ";
			end

			// Add ADDRESS associated with transfer to string, followed by "Data: " tag
			temp.itoa(integer'(i2mon_addr));
			s = {s,temp," Data: "};

			// Concatenate each data byte to string. PRINT_LINE_LEN parameter introduces a
			// number-of-characters cap, beyond which each  line will be wrapped to the nextline.
			foreach(i2mon_data[i]) begin
				if(s.len % PRINT_LINE_LEN < 4) s = {s,"\n\t"};
				temp.itoa(integer'(i2mon_data[i]));
				s = {s,temp,","};
			end

			$display("%s", s.substr(0,s.len-2));

			// In the case of a multi-line transfer, print a horizontal rule to make clear where 
			// this transfer transcript message ends
			if(s.len>60) display_hrule;
		end
	end*/

	//_____________________________________________________________________________________\\
	//                                 VALUE GENERATION                                    \\
	//_____________________________________________________________________________________\\

	// ****************************************************************************
	// Generate all required values for all tests, and store in
	// 		driver buffers (which will be destroyed) and validation buffers
	// 		(which are not modified after this step). This allows for
	// 		straightforward test flow and automated checking of results
	// 		at conclusion of simulation.
	// ****************************************************************************
	initial begin : generator_populate_test_buffers
		int i;
		// Generate data for first series of writes
		for(i=0;i<=31;i++) begin
			master_transmit_buffer.push_back(byte'(i));
			validation_write_buffer.push_back(byte'(i));
		end
		// Generate data for reads in second series of reads
		i2c_bus.reset_test_buffers();
		for(i=100;i<=131;i++) begin
			slave_read_transmit_buffer[0].push_back(byte'(i));
			validation_read_buffer.push_back(byte'(i));
		end
		// Generate data for writes in third alternating r/w series
		for(i=64;i<=127;i++)begin
			master_transmit_buffer.push_back(byte'(i));
			validation_write_buffer.push_back(byte'(i));
		end
		// Generate data for reads in third alternating r/w series
		for(i=63;i>=0;i--) begin
			slave_read_transmit_buffer[1].push_back(byte'(i));
			validation_read_buffer.push_back(byte'(i));
		end
	end

	//_____________________________________________________________________________________\\
	//                           VALUE VALIDATION AND REPORTING                            \\
	//_____________________________________________________________________________________\\

	// ****************************************************************************
	// Utilizing stored unaltered validation queues, test the values of all bytes transferred,
	// both writes and reads, utilizing the storage memories of the driver modules.
	// If all values match their predicted value, report ALL test cases passed and continue.
	// If some test cases failed, report quantity failed, and report which (in numerical order)
	// test cases show a mismatched value.
	// ****************************************************************************
	task check_and_scoreboard();
		int pass, fail,pauser;
		int failed_cases[$];
		$display("\n\n");
		display_hstars();
		display_hstars();
		$display("\n\t TRANSFERS COMPLETE; VALIDATING STORED TRANSFERS using check_and_scoreboard()");
		display_hrule();

		foreach(validation_write_buffer[i]) begin
			if(validation_write_buffer[i] != i2c_bus.get_receive_entry(i)) begin
				++fail;
				failed_cases.push_back(i);
			end
			else ++pass;
			pauser=i;
		end
		++pauser;
		foreach(validation_read_buffer[i]) begin
			if(validation_read_buffer[i] != master_receive_buffer[i].data) begin
				++fail;
				failed_cases.push_back(pauser+i);
			end
			else ++pass;
		end

		if(fail>0) begin
			$display("\t\tTEST CASES FAILED: %d\n", fail);
			foreach(failed_cases[i]) $display("FAIL Transaction # %d ",failed_cases[i]);
		end
		else $display("ALL test cases PASSED: %d Test cases validated.\n",pass);

	endtask

	// ****************************************************************************
	// Print the compact complete report of ALL bytes READ by the WB-Master from 
	// the I2C slave since the last system reset.
	// ****************************************************************************
	task master_print_read_report();
		static string s;
		static string temp;
		display_hstars();
		display_hstars();
		$display("");
		$display("\t\tCOMPACT COMPLETE TRANSFER REPORT \n\t\t\t\t(In-Order)");
		display_hrule();
		$display("MASTER WB-Bus Received Bytes from READS:");
		s = "\t";
		foreach(master_receive_buffer[i]) begin
			if(s.len % PRINT_LINE_LEN < 4) s = {s,"\n\t"};
			temp.itoa(integer'(master_receive_buffer[i].data));
			s = {s,temp,","};
		end
		$display("%s", s.substr(0,s.len-2));
		display_hrule();
	endtask

	//_____________________________________________________________________________________\\
	//                           WISHBONE DRIVER ABSTRACTIONS                              \\
	//_____________________________________________________________________________________\\

	// ****************************************************************************
	// Enable the DUT core. Effectively, a soft reset after a disable command
	// 		NB: Also sets the enable_interrupt bit of the DUT such that we can use
	// 			raised interrupts to determine DUT-ready rather than polling
	//			DUT registers for readiness.
	// ****************************************************************************
	task enable_dut_with_interrupt();
		wb_bus.master_write(CSR, ENABLE_CORE_INTERRUPT); // Enable DUT
	endtask

	// ****************************************************************************
	// Select desired I2C bus of DUT to use for transfers.
	// ****************************************************************************
	task select_I2C_bus(input bit [7:0] selected_bus);
		wb_bus.master_write(DPR, selected_bus);
		wb_bus.master_write(CMDR, SET_I2C_BUS);
		wait_interrupt;
	endtask

	// ****************************************************************************
	// Disable the DUT and STALL for 2 system cycles
	// ****************************************************************************
	task disable_dut();
		wb_bus.master_write(CSR, DISABLE_CORE); // Enable DUT
		repeat(2) begin @(posedge clk); $display("Stall"); end
	endtask

	// ****************************************************************************
	// Wait for, and clear, interrupt rising from WB-end of DUT. 
	// Do not check incoming status bits.
	// ****************************************************************************
	task wait_interrupt();
		wait(irq==1'b1);
		wb_bus.master_read(CMDR, buf_in);
	endtask

	// ****************************************************************************
	// Wait for, and clear, interrupt rising from WB-end of DUT. 
	// Check status register and alert user to problem if a NACK was received.
	// ****************************************************************************
	task wait_interrupt_with_NACK();
		wait(irq==1'b1);
		wb_bus.master_read(CMDR, buf_in);
		if(buf_in[6]==1'b1) $display("\t[ WB ] NACK");
	endtask

	// ****************************************************************************
	// Send a start command to I2C nets via DUT
	// ****************************************************************************
	task issue_start_command();
		wb_bus.master_write(CMDR, I2C_START);
		wait_interrupt();
	endtask

	// ****************************************************************************
	// Send a stop command to I2C Nets via DUT
	// ****************************************************************************
	task issue_stop_command();
		wb_bus.master_write(CMDR, I2C_STOP); // Stop the transaction/Close connection
		wait_interrupt();
	endtask

	// ****************************************************************************
	// Format incoming address byte and set R/W bit to request a WRITE.
	// Transmit this formatted address byte on the I2C bus
	// ****************************************************************************
	task transmit_address_req_write(input bit [7:0] addr);
		addr = addr << 2;
		addr[0]=1'b0;
		wb_bus.master_write(DPR, addr);
		wb_bus.master_write(CMDR, I2C_WRITE);
		wait_interrupt_with_NACK(); // In case of a down/unresponsive slave, we'd get a nack	
	endtask

	// ****************************************************************************
	// Format incoming address byte and set R/W bit to request a READ.
	// Transmit this formatted address byte on the I2C bus
	// ****************************************************************************
	task transmit_address_req_read(input bit [7:0] addr);
		addr = addr << 2;
		addr[0]=1'b1;
		wb_bus.master_write(DPR, addr);
		wb_bus.master_write(CMDR, I2C_WRITE);
		wait_interrupt_with_NACK(); // In case of a down/unresponsive slave, we'd get a nack
	endtask

	// ****************************************************************************
	// Write a single byte of data to a previously-addressed I2C Slave
	// Check to ensure we didn't get a NACK/ Got the ACK from the slave.
	// ****************************************************************************
	task write_data_byte(input bit [7:0] data);
		if(TOP_TRANSFER_DEBUG_MODE) $write("\t%d -->>> [WB]  {DUT}",data);
		wb_bus.master_write(DPR, data);
		wb_bus.master_write(CMDR, I2C_WRITE);
		wait_interrupt_with_NACK();
	endtask

	// ****************************************************************************
	// READ a single byte of data from a previously-addressed I2C Slave,
	//      Indicating that we are REQUESTING ANOTHER byte after this byte.
	// Check to ensure we didn't get a NACK/ Got the ACK from the slave.
	// ****************************************************************************
	task read_data_byte_with_continue(output bit [7:0] iobuf);
		wb_bus.master_write(CMDR, READ_WITH_ACK);
		wait_interrupt_with_NACK();
		wb_bus.master_read(DPR, iobuf);
		if(TOP_TRANSFER_DEBUG_MODE) $write("\t%d <<<-- [WB]  {DUT}  [I2C] <<<-- %d\t <READ>\n",iobuf,slv_most_recent_xfer);
	endtask

	// ****************************************************************************
	// READ a single byte of data from a previously-addressed I2C Slave,
	//      Indicating that this is the LAST BYTE of this transfer, and the next
	// 		bus action will be a STOP signal.
	// Check to ensure we didn't get a NACK/ Got the ACK from the slave.
	// ****************************************************************************
	task read_data_byte_with_stop(output bit [7:0] iobuf);
		wb_bus.master_write(CMDR, READ_WITH_NACK);
		wait_interrupt_with_NACK();
		wb_bus.master_read(DPR, iobuf);
		if(TOP_TRANSFER_DEBUG_MODE) $write("\t%d <<<-- [WB]  {DUT}  [I2C] <<<-- %d\t <READ>\n",iobuf,slv_most_recent_xfer);
	endtask

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
		.scl_i(scl[NUM_I2C_BUSSES-SELECTED_I2C_BUS-1]),
		.sda_i(sda[NUM_I2C_BUSSES-SELECTED_I2C_BUS-1]),
		.sda_o(sda[NUM_I2C_BUSSES-SELECTED_I2C_BUS-1])
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

	// ****************************************************************************
	// Define the flow of the simulation
	// ****************************************************************************
	initial begin : test_flow
		bit [TOP_I2C_DATA_WIDTH-1:0] localreg[];
		bit transfer_complete;
		i2c_op_t operation;
		logic [7:0] tf_buffer;
		recv_tuple_t tf_tup;
		//virtual wb_if wbbus2;



		ncsu_config_db#(virtual wb_if )::set("tst.env.wb_agent", wb_bus);
		ncsu_config_db#(virtual i2c_if )::set("tst.env.i2c_agent", i2c_bus);

		//wbbus2 = ncsu_config_db#(virtual wb_if )::get(get_full_name(), this.bus)));

		tst = new("tst",null);

		fork tst.run(); join_none;

		// Indicate test flow is starting to user
		display_header_banner();

		// Enable the DUT and select the correct bus
		@(negedge rst) enable_dut_with_interrupt();
		select_I2C_bus(SELECTED_I2C_BUS);

		/////////////////////////////////////////////////////////////////
		// Write 32 values in a single complete transaction 
		/////////////////////////////////////////////////////////////////
		fork i2c_bus.wait_for_i2c_transfer(operation,localreg);
			begin
				issue_start_command();
				transmit_address_req_write(i2c_slave_addr[8:1]);

				// Write contents of "output Buffer" to selected I2C Slave in a single stream
				for(int i=0;i<QTY_WORDS_TO_WRITE;i++)
					write_data_byte(master_transmit_buffer.pop_front());
				issue_stop_command();
			end
		join

		/////////////////////////////////////////////////////////////////
		// Read 32 values in a single complete transaction 
		/////////////////////////////////////////////////////////////////
		fork
			// Thread 0: Slave BFM Connection Handler
			i2c_bus.wait_for_i2c_transfer(operation,localreg);

			// Thread 1: Provide data to slave via BYPASS data feeder to BFM 
			i2c_bus.provide_read_data(slave_read_transmit_buffer[0], transfer_complete);

			// Thread 2: Execute Wishbone-end commands of Read-32 flow.
			begin
				issue_start_command();
				transmit_address_req_read(i2c_slave_addr[8:1]);
				for(int i=0;i<QTY_WORDS_TO_WRITE-1;i++) begin
					read_data_byte_with_continue(tf_buffer); // Read all but the last byte
					tf_tup.address = i2c_slave_addr[8:2];
					tf_tup.data = tf_buffer;
					master_receive_buffer.push_back(tf_tup); // Store in Driver test Queue
				end
				read_data_byte_with_stop(tf_buffer); // Read the last byte
				tf_tup.address = i2c_slave_addr[8:2];
				tf_tup.data = tf_buffer;
				master_receive_buffer.push_back(tf_tup); // Store in Driver test Queue

				// Send a stop at conclusion of transaction
				issue_stop_command();
			end
		join

		/////////////////////////////////////////////////////////////////
		// Alternating Write/Read Transactions for 64 values of each type
		/////////////////////////////////////////////////////////////////
		// Thread 0: Provide data to slave via BYPASS data feeder to BF
		fork i2c_bus.provide_read_data(slave_read_transmit_buffer[1], transfer_complete); join_none

		for(int i=0;i<QTY_WORDS_TO_WRITE*2;i++) begin
			// Write a single byte
			fork
				// Thread 1: Slave BFM Connection Handler
				i2c_bus.wait_for_i2c_transfer(operation,localreg);

				// Thread 2:  Execute Wishbone-end command of Write-64[one byte] flow.
				begin
					issue_start_command();
					transmit_address_req_write(i2c_slave_addr[8:1]);
					write_data_byte(master_transmit_buffer[i]);
					issue_start_command();
				end
			join

			// Restart and Read a single Byte
			fork
				// Thread 1: Slave BFM Connection Handler
				i2c_bus.wait_for_i2c_transfer(operation,localreg);

				// Thread 2:  Execute Wishbone-end command of Read-64[one byte] flow.
				begin
					transmit_address_req_read(i2c_slave_addr[8:1]);
					read_data_byte_with_stop(tf_buffer);

					// Store received data in driver 
					tf_tup.address = i2c_slave_addr[8:2];
					tf_tup.data = tf_buffer;
					master_receive_buffer.push_back(tf_tup);
				end
			join
		end

		// Send STOP at end of Read-Write-64 transaction
		issue_stop_command();

		// Validate all transferred bytes against validation buffers
		check_and_scoreboard();

		// Print Compact complete reports for both ends of system
		master_print_read_report;
		i2c_bus.print_driver_write_report();

		// Display authorship Banner
		display_footer_banner();

		// Exit the tests
		$finish;
	end

endmodule
