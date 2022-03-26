class wb_driver extends ncsu_component#(.T(wb_transaction));

	function new(string name = "", ncsu_component_base parent = null);
		super.new(name,parent);
	endfunction

	virtual wb_if bus;
	wb_configuration configuration;
	wb_transaction wb_trans;
	bit dut_enable;
	logic [7:0] tf_buffer;

	// ****************************************************************************
	//  Construction, Setters and Getters
	// ****************************************************************************
	function void set_configuration(wb_configuration cfg);
		configuration = cfg;
	endfunction


	// ****************************************************************************
	// Issue a received transaction to the DUT 
	// ****************************************************************************
	virtual task bl_put(T trans);
		bit [7:0] buffer;
		wb_trans = trans;
		bus.wait_for_reset();

		ncsu_info("\n",{get_full_name()," ",trans.convert2string()},NCSU_DEBUG);

		if(wb_trans.write) begin
			if(wb_trans.line == CMDR || wb_trans.line == CSR) bus.master_write(wb_trans.line, wb_trans.cmd);
			if(wb_trans.line == DPR) bus.master_write(wb_trans.line, wb_trans.word);
			if(wb_trans.wait_int_ack) bus.wait_interrupt();
			if(wb_trans.wait_int_nack) bus.wait_interrupt_with_NACK();
			if(wb_trans.stall_cycles > 0) bus.wait_for_num_clocks(wb_trans.stall_cycles);
		end
		else begin
			if(wb_trans.line == CMDR ||  wb_trans.line == CSR) bus.master_read(wb_trans.line, buffer);
			if(wb_trans.line==DPR) bus.master_read(wb_trans.line, buffer);
			if(wb_trans.wait_int_ack) bus.wait_interrupt();
			if(wb_trans.wait_int_nack) bus.wait_interrupt_with_NACK();
			if(wb_trans.stall_cycles > 0) bus.wait_for_num_clocks(wb_trans.stall_cycles);

		end
	endtask
endclass
