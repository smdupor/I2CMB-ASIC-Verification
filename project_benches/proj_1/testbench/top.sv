`timescale 1ns / 10ps


module top();
	import i2c_types_pkg::*;
	//Physical Parameters
	parameter int WB_ADDR_WIDTH = 2;
	parameter int WB_DATA_WIDTH = 8;
	parameter int I2C_ADDR_WIDTH = 7;
	parameter int I2C_DATA_WIDTH = 8;
	parameter int NUM_I2C_BUSSES = 16;
	parameter int I2C_BUS_RATES[16] = {400,350,300,250,200,150,100,90,80,72,60,50,42,35,30,100}; // Bus clocks in kHz for testing at various speeds
	parameter int SELECTED_I2C_BUS = 2;

	parameter bit VERBOSE_DEBUG_MODE=0;
	parameter bit TRANSFER_DEBUG_MODE=0;

	// Test Parameters
	parameter int I2C_SLAVE_PER_BUS = 2;
	parameter int QTY_WORDS_TO_WRITE=32;

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

	// Test Logical Buffers
	logic we_mon;
	logic [WB_ADDR_WIDTH-1:0] adr_mon;
	logic [WB_DATA_WIDTH-1:0] dat_mon;

	logic [WB_ADDR_WIDTH-1:0] adr_in;
	logic [WB_DATA_WIDTH-1:0] dat_in;
	logic [WB_DATA_WIDTH-1:0] buf_in;
	logic we_in;
	byte slv_most_recent_xfer;

	// Device Configuration and Command Logics
	enum logic[7:0] {ENABLE_CORE_INTERRUPT=8'b11xxxxxx,DISABLE_CORE=8'b0xxxxxxx, SET_I2C_BUS=8'bxxxxx110, I2C_START=8'bxxxxx100,
		I2C_WRITE=8'bxxxxx001, I2C_STOP=8'bxxxxx101, READ_WITH_NACK=8'bxxxxx011, READ_WITH_ACK=8'bxxxxx010} cmd;
	enum bit [1:0] {CSR=2'b00, DPR=2'b01, CMDR=2'b10} dut_reg;

	bit [8:0] i2c_slave_addr = 9'h12;
	typedef struct {
		bit [6:0] address;
		bit [7:0] data;
	} tuple;

	// Test Bank Data Buffers
	bit [7:0] master_transmit_buffer [$];
	tuple master_receive_buffer [$];
	bit [7:0] validation_write_buffer[$];
	bit [7:0] validation_read_buffer[$];

	// FIRE INITIAL LOGIC BLOCKS
	initial clock_generator();
	initial reset_generator();
	initial populate_test_buffers();
	initial wishbone_monitor();
	initial test_flow();
	initial simple_receive_data();

	task populate_test_buffers();
		int i;
		for(i=0;i<QTY_WORDS_TO_WRITE;i++) begin
			master_transmit_buffer.push_back(byte'(i));
			validation_write_buffer.push_back(byte'(i));
		end
		for(i=64;i<=127;i++)begin
			master_transmit_buffer.push_back(byte'(i));
			validation_write_buffer.push_back(byte'(i));
		end
		i2c_slave0.reset_test_buffers();
		for(i=100;i<=131;i++) begin
			i2c_slave0.bypass_push_transmit_buf(byte'(i));
			validation_read_buffer.push_back(byte'(i));
		end
		for(i=63;i>=0;i--) begin
			i2c_slave0.bypass_push_transmit_buf(byte'(i));
			validation_read_buffer.push_back(byte'(i));
		end
	endtask

	task check_and_scoreboard();
		int pass, fail,pauser;
		int failed_cases[$];
		display_hstars();
		$display("\t TRANSFERS COMPLETE; VALIDATING STORED TRANSFERS");
		display_hrule();
		foreach(validation_write_buffer[i]) begin
			//$display ("Val: %d, Got: %d",validation_write_buffer[i],i2c_slave0.get_receive_entry(i));
			if(validation_write_buffer[i] != i2c_slave0.get_receive_entry(i)) begin
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
	else $display("ALL test cases PASSED: Total valid bytes transferred: %d",pass);
		
	endtask

	task simple_receive_data();
		bit [I2C_DATA_WIDTH-1:0] localreg[256];
		i2c_op_t operation;
		// Setup Slave 0 (The one we use)
		fork i2c_slave0.reset_and_configure(i2c_slave_addr);
		join_none;
		// Setup Slave 1
		//i2c_slave_addr+=1;
		//i2c_slave1.reset_and_configure(i2c_slave_addr);

		// Select Slave 0 For testflow
		//i2c_slave_addr-=1;
		//i2c_slave0.wait_for_start(operation,localreg);
		//i2c_slave1.wait_for_start(operation,localreg);	
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

	initial begin : monitor_i2c_bus
		bit[I2C_ADDR_WIDTH-1:0] i2mon_addr;
		i2c_op_t i2mon_op;
		bit [I2C_DATA_WIDTH-1:0] i2mon_data [];
		string s,temp;
		s = "I2C_BUS WRITE Transfer From Address: ";
		//$display("MONITORING YEAAH");
		//@(negedge rst);
		forever begin
			i2c_slave0.i2c_monitor(i2mon_addr, i2mon_op, i2mon_data);
			//$display("RETURN YEAH");
			if(i2mon_op == I2_WRITE) begin
				s = "I2C_BUS WRITE Transfer To   Address: ";
				
			end
			else begin
				s = "I2C_BUS READ  Transfer From Address: ";
			end
				temp.itoa(integer'(i2mon_addr));
				s = {s,temp," Data: "};
			foreach(i2mon_data[i]) begin
				//$display("FOREACH YEAH");
				temp.itoa(integer'(i2mon_data[i]));
				s = {s,temp,","};
			end
			$display("%s", s.substr(0,s.len-2));
			if(s.len>60) display_hrule;
		end
	end


	// ****************************************************************************
	// Define the flow of the simulation
	task test_flow();
		bit [I2C_DATA_WIDTH-1:0] localreg[];
		i2c_op_t operation;
		logic [7:0] tf_buffer;
		tuple tf_tup;
		localreg = new[32];
		display_hstars();
		$display("\t\t\tSTARTING TEST FLOW");
		display_hstars();
		@(negedge rst) enable_dut_with_interrupt();
		select_I2C_bus(SELECTED_I2C_BUS);
		fork i2c_slave0.wait_for_start(operation,localreg);
			begin
				issue_start_command();
				transmit_address_req_write(i2c_slave_addr[8:1]);

				// Write contents of "output Buffer" to selected I2C Slave in a single stream
				for(int i=0;i<QTY_WORDS_TO_WRITE;i++) write_data_byte(master_transmit_buffer.pop_front());
				issue_stop_command();
			end
		join;
		//#100 $display(" WRITE 0-31 TASK DONE, Begin READ Task\n\n");
		
		//foreach(localreg[i]) $display("Recv: %d", localreg[i]);
		// Start negotiation and perform read-all task
		fork
			i2c_slave0.wait_for_start(operation,localreg);
			begin
				issue_start_command();
				transmit_address_req_read(i2c_slave_addr[8:1]);
				for(int i=0;i<QTY_WORDS_TO_WRITE-1;i++) begin
					read_data_byte_with_continue(tf_buffer); // Read all but the last byte
					tf_tup.address = i2c_slave_addr[8:2];
					tf_tup.data = tf_buffer;
					master_receive_buffer.push_back(tf_tup);
				end
				read_data_byte_with_stop(tf_buffer); // Read the last byte
				tf_tup.address = i2c_slave_addr[8:2];
				tf_tup.data = tf_buffer;
				master_receive_buffer.push_back(tf_tup);

				issue_stop_command();
			end
		join;
		//#100 $display("READ 100-131 TASK DONE. BEGIN READ/WRITE TASK\n\n");

		// Start alternating read/write task
		for(int i=0;i<QTY_WORDS_TO_WRITE*2;i++) begin
			fork
				i2c_slave0.wait_for_start(operation,localreg);
				begin
					issue_start_command();
					transmit_address_req_write(i2c_slave_addr[8:1]);
					write_data_byte(master_transmit_buffer[i]);
					issue_start_command();
				end
			join;
			fork
				i2c_slave0.wait_for_start(operation,localreg);
				begin
					transmit_address_req_read(i2c_slave_addr[8:1]);
					read_data_byte_with_stop(tf_buffer);
					tf_tup.address = i2c_slave_addr[8:2];
					tf_tup.data = tf_buffer;
					master_receive_buffer.push_back(tf_tup);
				end
			join;
		end
		issue_stop_command();
		issue_stop_command();
		// Print Results of test flow/Reports
		#1000 check_and_scoreboard();
		master_print_read_report;
		i2c_slave0.print_read_report();
		display_hstars();


		// Exit the tests
		$finish;
	endtask

	task master_print_read_report();
		static string s;
		static string temp;
		display_hstars();
		$display("\t\tCOMPACT COMPLETE TRANSFER REPORT (In-Order)");
		display_hrule();
		s = "MASTER WB-Bus Received Bytes from READS:\n ";
		foreach(master_receive_buffer[i]) begin
			temp.itoa(integer'(master_receive_buffer[i].data));
			s = {s,temp,","};
		end
		$display("%s", s.substr(0,s.len-2));
		display_hrule();
	endtask

	task issue_stop_command();
		wb_bus.master_write(CMDR, I2C_STOP); // Stop the transaction/Close connection
		wait_interrupt();
	endtask

	task enable_dut_with_interrupt();
		wb_bus.master_write(CSR, ENABLE_CORE_INTERRUPT); // Enable DUT
	endtask

	task disable_dut();
		wb_bus.master_write(CSR, DISABLE_CORE); // Enable DUT
		repeat(2) begin @(posedge clk); $display("Stall"); end
	endtask

	task wait_interrupt();
		wait(irq==1'b1);
		wb_bus.master_read(CMDR, buf_in);
	endtask

	task wait_interrupt_with_NACK();
		wait(irq==1'b1);
		wb_bus.master_read(CMDR, buf_in);
		if(buf_in[6]==1'b1) $display("\t[ WB ] NACK");
	endtask

	task select_I2C_bus(input bit [7:0] selected_bus);
		wb_bus.master_write(DPR, selected_bus);
		wb_bus.master_write(CMDR, SET_I2C_BUS);
		wait_interrupt;
	endtask

	task issue_start_command();
		wb_bus.master_write(CMDR, I2C_START);
		wait_interrupt();
	endtask

	task transmit_address_req_write(input bit [7:0] addr);
		addr = addr << 2;
		addr[0]=1'b0;
		wb_bus.master_write(DPR, addr);
		wb_bus.master_write(CMDR, I2C_WRITE);
		wait_interrupt_with_NACK(); // In case of a down/unresponsive slave, we'd get a nack
		//TODO: Handle NACK ?? Or allow steamrolling....		
	endtask

	task transmit_address_req_read(input bit [7:0] addr);
		addr = addr << 2;
		addr[0]=1'b1;
		wb_bus.master_write(DPR, addr);
		wb_bus.master_write(CMDR, I2C_WRITE);
		wait_interrupt_with_NACK(); // In case of a down/unresponsive slave, we'd get a nack
		//TODO: Handle NACK ?? Or allow steamrolling....
	endtask

	task write_data_byte(input bit [7:0] data);
		if(TRANSFER_DEBUG_MODE) $write("\t%d -->>> [WB]  {DUT}",data);
		wb_bus.master_write(DPR, data);
		wb_bus.master_write(CMDR, I2C_WRITE);
		wait_interrupt_with_NACK();
	endtask

	task read_data_byte_with_continue(output bit [7:0] iobuf);

		wb_bus.master_write(CMDR, READ_WITH_ACK);
		wait_interrupt_with_NACK();
		wb_bus.master_read(DPR, iobuf);
		if(TRANSFER_DEBUG_MODE) $write("\t%d <<<-- [WB]  {DUT}  [I2C] <<<-- %d\t <READ>\n",iobuf,slv_most_recent_xfer);
	endtask

	task read_data_byte_with_stop(output bit [7:0] iobuf);

		wb_bus.master_write(CMDR, READ_WITH_NACK);
		wait_interrupt_with_NACK();
		wb_bus.master_read(DPR, iobuf);
		if(TRANSFER_DEBUG_MODE) $write("\t%d <<<-- [WB]  {DUT}  [I2C] <<<-- %d\t <READ>\n",iobuf,slv_most_recent_xfer);
	endtask


	// ****************************************************************************
	// Instatiate the slave I2C BFM
	i2c_if		#(
	.I2C_ADDR_WIDTH(I2C_ADDR_WIDTH),
	.I2C_DATA_WIDTH(I2C_DATA_WIDTH),
	.TRANSFER_DEBUG_MODE(TRANSFER_DEBUG_MODE) //,
	//.SLAVE_ADDRESS(I2C_SLAVE_ADDR)
	)
	i2c_slave0 (
		.clk_i(clk),
		.rst_i(rst),
		.scl_i(scl[NUM_I2C_BUSSES-SELECTED_I2C_BUS-1]),
		.sda_i(sda[NUM_I2C_BUSSES-SELECTED_I2C_BUS-1]),
		.sda_o(sda[NUM_I2C_BUSSES-SELECTED_I2C_BUS-1]),
		.most_recent_xfer(slv_most_recent_xfer)
	);
	/*i2c_if		#(
		.I2C_ADDR_WIDTH(I2C_ADDR_WIDTH),
		.I2C_DATA_WIDTH(I2C_DATA_WIDTH),
		.TRANSFER_DEBUG_MODE(TRANSFER_DEBUG_MODE)//,
		//.SLAVE_ADDRESS(I2C_SLAVE_ADDR)
	)
	i2c_slave1 (
		.clk_i(clk),
		.rst_i(rst),
		.scl_i(scl[NUM_I2C_BUSSES-SELECTED_I2C_BUS-1]),
		.sda_i(sda[NUM_I2C_BUSSES-SELECTED_I2C_BUS-1]),
		.sda_o(sda[NUM_I2C_BUSSES-SELECTED_I2C_BUS-1])//,
		//.most_recent_xfer(slv_most_recent_xfer)
	);*/

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


endmodule
