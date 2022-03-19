interface wb_if #(int ADDR_WIDTH = 2, int DATA_WIDTH = 8)(

	// System sigals
	input wire clk_i,
	input wire rst_i,
	input wire irq_i,
	// Master signals
	output reg cyc_o,
	output reg stb_o,
	input wire ack_i,
	output reg [ADDR_WIDTH-1:0] adr_o,
	output reg we_o,
	// Slave signals
	input wire cyc_i,
	input wire stb_i,
	output reg ack_o,
	input wire [ADDR_WIDTH-1:0] adr_i,
	input wire we_i,
	// Shred signals
	output reg [DATA_WIDTH-1:0] dat_o,
	input wire [DATA_WIDTH-1:0] dat_i
);
	import wb_types_pkg::*;

	logic [7:0] buf_in;

	initial reset_bus();

	// ****************************************************************************              
	task wait_for_reset();
		if (rst_i !== 0) @(negedge rst_i);
	endtask

	// ****************************************************************************              
	task wait_for_num_clocks(int num_clocks);
		repeat (num_clocks) @(posedge clk_i);
	endtask

	// ****************************************************************************              
	task wait_for_interrupt();
		@(posedge irq_i);
	endtask

	// ****************************************************************************              
	task reset_bus();
		cyc_o <= 1'b0;
		stb_o <= 1'b0;
		we_o <= 1'b0;
		adr_o <= 'b0;
		dat_o <= 'b0;
	endtask

	// ****************************************************************************              
	task master_write(
		input bit [ADDR_WIDTH-1:0]  addr,
		input bit [DATA_WIDTH-1:0]  data
	);

		@(posedge clk_i);
		adr_o <= addr;
		dat_o <= data;
		cyc_o <= 1'b1;
		stb_o <= 1'b1;
		we_o <= 1'b1;
		while (!ack_i) @(posedge clk_i);
		cyc_o <= 1'b0;
		stb_o <= 1'b0;
		adr_o <= 'bx;
		dat_o <= 'bx;
		we_o <= 1'b0;
		@(posedge clk_i);

	endtask

	// ****************************************************************************              
	task master_read(
		input bit [ADDR_WIDTH-1:0]  addr,
		output bit [DATA_WIDTH-1:0] data
	);

		@(posedge clk_i);
		adr_o <= addr;
		dat_o <= 'bx;
		cyc_o <= 1'b1;
		stb_o <= 1'b1;
		we_o <= 1'b0;
		@(posedge clk_i);
		while (!ack_i) @(posedge clk_i);
		cyc_o <= 1'b0;
		stb_o <= 1'b0;
		adr_o <= 'bx;
		dat_o <= 'bx;
		we_o <= 1'b0;
		data = dat_i;

	endtask

	// ****************************************************************************              
	task master_monitor(
		output bit [ADDR_WIDTH-1:0] addr,
		output bit [DATA_WIDTH-1:0] data,
		output bit we
	);

		while (!cyc_o) @(posedge clk_i);
		while (!ack_i) @(posedge clk_i);
		addr = adr_o;
		we = we_o;
		if (we_o) begin
			data = dat_o;
		end else begin
			data = dat_i;
		end
		while (cyc_o) @(posedge clk_i);
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
		master_write(CSR, ENABLE_CORE_INTERRUPT); // Enable DUT
	endtask

	// ****************************************************************************
	// Select desired I2C bus of DUT to use for transfers.
	// ****************************************************************************
	task select_I2C_bus(input bit [7:0] selected_bus);
		//$display("Select %d", selected_bus);
		master_write(DPR, selected_bus);
		//$display("Issue select cmd");
		master_write(CMDR, SET_I2C_BUS);
		//$display("Stall for interrupt");
		wait_interrupt();
		//$display("Returned from interrupt");
	endtask

	// ****************************************************************************
	// Disable the DUT and STALL for 2 system cycles
	// ****************************************************************************
	task disable_dut();
		master_write(CSR, DISABLE_CORE); // Enable DUT
		repeat(2) begin @(posedge clk_i); $display("Stall"); end
	endtask

	// ****************************************************************************
	// Wait for, and clear, interrupt rising from WB-end of DUT. 
	// Do not check incoming status bits.
	// ****************************************************************************
	task wait_interrupt();
		wait(irq_i ==1'b1);
		master_read(CMDR, buf_in);
	endtask

	// ****************************************************************************
	// Wait for, and clear, interrupt rising from WB-end of DUT. 
	// Check status register and alert user to problem if a NACK was received.
	// ****************************************************************************
	task wait_interrupt_with_NACK();
		wait(irq_i ==1'b1);
		master_read(CMDR, buf_in);
		if(buf_in[6]==1'b1) $display("\t[ WB ] NACK");
	endtask

	// ****************************************************************************
	// Send a start command to I2C nets via DUT
	// ****************************************************************************
	task issue_start_command();
		master_write(CMDR, I2C_START);
		wait_interrupt();
	endtask

	// ****************************************************************************
	// Send a stop command to I2C Nets via DUT
	// ****************************************************************************
	task issue_stop_command();
		master_write(CMDR, I2C_STOP); // Stop the transaction/Close connection
		wait_interrupt();
	endtask

	// ****************************************************************************
	// Format incoming address byte and set R/W bit to request a WRITE.
	// Transmit this formatted address byte on the I2C bus
	// ****************************************************************************
	task transmit_address_req_write(input bit [7:0] addr);
		//	$display("ATTEMPT WRITE ADDR: %d", addr);
		addr = addr << 1;
		addr[0]=1'b0;
		master_write(DPR, addr);
		master_write(CMDR, I2C_WRITE);
		wait_interrupt_with_NACK(); // In case of a down/unresponsive slave, we'd get a nack	
	endtask

	// ****************************************************************************
	// Format incoming address byte and set R/W bit to request a READ.
	// Transmit this formatted address byte on the I2C bus
	// ****************************************************************************
	task transmit_address_req_read(input bit [7:0] addr);
		addr = addr << 1;
		addr[0]=1'b1;
		master_write(DPR, addr);
		master_write(CMDR, I2C_WRITE);
		wait_interrupt_with_NACK(); // In case of a down/unresponsive slave, we'd get a nack
	endtask

	// ****************************************************************************
	// Write a single byte of data to a previously-addressed I2C Slave
	// Check to ensure we didn't get a NACK/ Got the ACK from the slave.
	// ****************************************************************************
	task write_data_byte(input bit [7:0] data);
		master_write(DPR, data);
		master_write(CMDR, I2C_WRITE);
		wait_interrupt_with_NACK();
	endtask

	// ****************************************************************************
	// READ a single byte of data from a previously-addressed I2C Slave,
	//      Indicating that we are REQUESTING ANOTHER byte after this byte.
	// Check to ensure we didn't get a NACK/ Got the ACK from the slave.
	// ****************************************************************************
	task read_data_byte_with_continue(output bit [7:0] iobuf);
		master_write(CMDR, READ_WITH_ACK);
		wait_interrupt_with_NACK();
		master_read(DPR, iobuf);
	endtask

	// ****************************************************************************
	// READ a single byte of data from a previously-addressed I2C Slave,
	//      Indicating that this is the LAST BYTE of this transfer, and the next
	// 		bus action will be a STOP signal.
	// Check to ensure we didn't get a NACK/ Got the ACK from the slave.
	// ****************************************************************************
	task read_data_byte_with_stop(output bit [7:0] iobuf);
		master_write(CMDR, READ_WITH_NACK);
		wait_interrupt_with_NACK();
		master_read(DPR, iobuf);
	endtask

endinterface
