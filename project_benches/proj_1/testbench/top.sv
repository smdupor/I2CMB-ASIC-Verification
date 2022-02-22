`timescale 1ns / 10ps


module top();
	
	//Physical Parameters
	parameter int WB_ADDR_WIDTH = 2;
	parameter int WB_DATA_WIDTH = 8;
	parameter int NUM_I2C_BUSSES = 16;
	parameter int I2C_BUS_RATES[16] = {400,350,300,250,200,150,100,90,80,72,60,50,42,35,30,100}; // Bus clocks in kHz for testing at various speeds
	parameter int SELECTED_I2C_BUS = 0; 
	
	parameter bit VERBOSE_DEBUG_MODE=0;
	parameter bit TRANSFER_DEBUG_MODE=1;

	// Test Parameters
	parameter int I2C_SLAVE_PER_BUS = 2;
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
	enum logic[7:0] {ENABLE_CORE_INTERRUPT=8'b11xxxxxx, SET_I2C_BUS=8'bxxxxx110, I2C_START=8'bxxxxx100, 
						I2C_WRITE=8'bxxxxx001, I2C_STOP=8'bxxxxx101, READ_WITH_NACK=8'bxxxxx011, READ_WITH_ACK=8'bxxxxx010} cmd;
	enum bit [1:0] {CSR=2'b00, DPR=2'b01, CMDR=2'b10} dut_reg;
	bit [8:0] i2c_slave_addr = 9'h12;
	
	// Test Bank Data Buffers
	bit [7:0] master_transmit_buffer [$];
	byte master_receive_buffer [$]; 
	
	// FIRE INITIAL LOGIC BLOCKS
	initial clock_generator();
	initial reset_generator();
	initial populate_test_buffers();
	initial wishbone_monitor();
	initial test_flow();
	initial simple_receive_data();

	task populate_test_buffers();
		int i;
		for(i=0;i<QTY_WORDS_TO_WRITE;i++) master_transmit_buffer.push_back(byte'(i));
		for(i=0;i<QTY_WORDS_TO_WRITE;i++) master_transmit_buffer.push_back(byte'(i));
		i2c_slave0.reset_test_buffers();
		for(i=QTY_WORDS_TO_WRITE;i<QTY_WORDS_TO_WRITE*2;i++) i2c_slave0.bypass_push_transmit_buf(byte'(i));
		for(i=QTY_WORDS_TO_WRITE;i<QTY_WORDS_TO_WRITE*2;i++) i2c_slave0.bypass_push_transmit_buf(byte'(i));
	endtask

	task simple_receive_data();
		bit [8:0] localreg;
		// Setup Slave 0 (The one we use)
		i2c_slave0.configure(i2c_slave_addr);

		// Setup Slave 1
		i2c_slave_addr+=1;
		i2c_slave1.configure(i2c_slave_addr);

		// Select Slave 0 For testflow
		i2c_slave_addr-=1;
		i2c_slave0.wait_for_start(localreg);
		i2c_slave1.wait_for_start(localreg);	
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

		@(negedge rst) wb_bus.master_write(CSR, ENABLE_CORE_INTERRUPT); // Enable DUT

		select_I2C_bus(SELECTED_I2C_BUS);
		
		issue_start_command();
		transmit_address_req_write(i2c_slave_addr[8:1]);
		
		// Write contents of "output Buffer" to selected I2C Slave in a single stream
		for(int i=0;i<QTY_WORDS_TO_WRITE;i++) begin
			write_data_byte(master_transmit_buffer[i]);
		end

		wb_bus.master_write(CMDR, I2C_STOP); // Stop the transaction/Close connection
		wait_interrupt();
		
		$display(" WRITE ALL TASK DONE, Begin READ ALL");
		
		// Start negotiation and perform read-all task
		issue_start_command();
		transmit_address_req_read(i2c_slave_addr[8:1]);
		for(int i=0;i<QTY_WORDS_TO_WRITE-1;i++) begin 
			read_data_byte_with_continue(short_buffer); // Read all but the last byte
			master_receive_buffer.push_back(short_buffer);
		end
			read_data_byte_with_stop(short_buffer); // Read the last byte
			master_receive_buffer.push_back(short_buffer);
		wb_bus.master_write(CMDR, I2C_STOP); 		// Stop the transaction/Close connection
		wait_interrupt();
		
		$display("READ ALL TASK DONE. BEGIN READ/WRITE TASK.");
		
		// Start alternating read/write task
		for(int i=0;i<QTY_WORDS_TO_WRITE;i++) begin
			issue_start_command();
			transmit_address_req_write(i2c_slave_addr[8:1]);
			write_data_byte(master_transmit_buffer[i]);
			issue_start_command();
			transmit_address_req_read(i2c_slave_addr[8:1]);
			read_data_byte_with_stop(short_buffer);
			master_receive_buffer.push_back(short_buffer);
		end
		wb_bus.master_write(CMDR, I2C_STOP); 		// Stop the transaction/Close connection
		wait_interrupt();
		
		// Print Results of test flow/Reports
		i2c_slave0.print_read_report();
		master_print_read_report;

		// Exit the tests
		$finish;
	endtask
	
	task master_print_read_report();
			static string s;
					static string temp;
					s = " Master Received Bytes (0x): ";
					foreach(master_receive_buffer[i]) begin
						temp.itoa(integer'(master_receive_buffer[i]));
						s = {s,temp,","};
					end
					$display("%s", s.substr(0,s.len-2));
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
		wait_interrupt_with_NACK();	// In case of a down/unresponsive slave, we'd get a nack
		//TODO: Handle NACK ?? Or allow steamrolling....		
endtask

task transmit_address_req_read(input bit [7:0] addr);
		addr = addr << 2;
		addr[0]=1'b1;
		wb_bus.master_write(DPR, addr);
		wb_bus.master_write(CMDR, I2C_WRITE);
		wait_interrupt_with_NACK();	// In case of a down/unresponsive slave, we'd get a nack
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
		.ADDR_WIDTH(WB_ADDR_WIDTH),
		.DATA_WIDTH(WB_DATA_WIDTH),
		.TRANSFER_DEBUG_MODE(TRANSFER_DEBUG_MODE)//,
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
	i2c_if		#(
		.ADDR_WIDTH(WB_ADDR_WIDTH),
		.DATA_WIDTH(WB_DATA_WIDTH),
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
