class i2cmb_generator_test_reg extends i2cmb_generator;
`ncsu_register_object(i2cmb_generator_test_reg);

	// ****************************************************************************
	// Constructor, setters and getters
	// ****************************************************************************
	function new(string name = "", ncsu_component_base  parent = null);
		super.new(name,parent);

		if ( !$value$plusargs("GEN_TRANS_TYPE=%s", trans_name)) begin
			$display("FATAL: +GEN_TRANS_TYPE plusarg not found on command line");
			$fatal;
		end

		$display("%m found +GEN_TRANS_TYPE=%s", trans_name);
		if(trans_name == "i2cmb_generator_test_reg") begin
			trans_name = "i2c_transaction";
		end
		else $fatal;
		verbosity_level = global_verbosity_level;
	endfunction

	// ****************************************************************************
	// Perform register and error tests on the DUT:
	// DEFAULT VALUES
	// READ-ONLY REGIONS are actually READ-ONLY
	// WRITES to one register do not change the values of others
	// DUT Error conditions from illegal operations
	// ****************************************************************************
	virtual task run();

		env_cfg.disable_coverage();
		env_cfg.enable_register_testing();

		generate_default_testing();

		generate_access_ctrl_testing();

		generate_crosschecking();

		super.run();

		env_cfg.enable_error_testing = 1'b1;
		generate_error_testing();

		super.run();
	endtask

	//_____________________________________________________________________________________\\
	//                                TEST FLOW GENERATION                                 \\
	//_____________________________________________________________________________________\\

	// ****************************************************************************
	// Test the default values of each register at initialization
	// ****************************************************************************
	function void generate_default_testing();
		reg_read(CSR);
		reg_read(DPR);
		reg_read(CMDR);
		reg_read(FSMR);
	endfunction
		
		
	// ****************************************************************************
	// Test that all read-only regions are, indeed, read-only, of all DUT registers.
	// ****************************************************************************
	function void generate_access_ctrl_testing();
		reg_write(CSR, 8'b0011_1111);
		reg_write(CMDR, 8'b0111_1000);
		reg_write(FSMR, 8'hff);
		generate_default_testing();
	endfunction

	// ****************************************************************************
	// Verify that writes to one register do not change the values of other registers.
	// ****************************************************************************
	function void generate_crosschecking();
		reg_write(CSR, 8'b1100_0000);
		generate_default_testing();
		reg_write(DPR, 8'hff);
		generate_default_testing();
		reg_write(CMDR, 8'b1000_0111);
		generate_default_testing();
	endfunction

	// ****************************************************************************
	// Explicitly create error conditions while the NON-I2C PREDICTOR is connected.
	// Verify that DUT raises error bit in the error scenarios:
	// Select bus AFTER start DURING transaction
	// Initiate WAIT command AFTER start DURING transaction
	// ****************************************************************************
	function void generate_error_testing();

		disable_dut();
		enable_dut_with_interrupt();

		select_I2C_bus(0);
		issue_start_command();
		// Bus Sel after start illegal
		select_I2C_bus(3);

		disable_dut();
		enable_dut_with_interrupt();

		select_I2C_bus(0);
		issue_start_command();
		// Wait after start illegal
		issue_wait(1);

		disable_dut();
	endfunction


	//_____________________________________________________________________________________\\
	//                                TRANSACTION CREATORS                                 \\
	//_____________________________________________________________________________________\\

	// ****************************************************************************
	// Send an explicit transaction to the DUT, requesting a READ of a register
	// ****************************************************************************
	function void reg_read(input bit [1:0] adr);
		//master_write(CSR, ENABLE_CORE_INTERRUPT); // Enable DUT		
		wb_transaction t = new("dut_read");
		t.write = 1'b0;
		t.line = adr;
		t.cmd = 8'b0;
		t.word = 8'b0;
		t.wait_int_nack=1'b0;
		t.wait_int_ack=1'b0;
		t.stall_cycles=5;
		t.label("DUT Read");
		wb_trans.push_back(t);
	endfunction

	// ****************************************************************************
	// Send an explicit transaction to the DUT, requesting a WRITE of a register
	// ****************************************************************************
	function void reg_write(input bit [2:0] adr, input bit [7:0] data);
		//master_write(CSR, ENABLE_CORE_INTERRUPT); // Enable DUT		
		wb_transaction t = new("dut_write");
		t.write = 1'b1;
		t.line = adr;
		t.cmd = data;
		t.word= data;
		t.wait_int_nack=1'b0;
		t.wait_int_ack=1'b0;
		t.stall_cycles=5;
		t.label("DUT Write");
		wb_trans.push_back(t);
	endfunction

endclass