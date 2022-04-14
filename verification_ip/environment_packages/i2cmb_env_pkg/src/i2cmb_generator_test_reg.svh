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
		// run the transaction generator; Create all transactions, then, pass trans-
		//		actions to agents, in order, in parallel. 
		// ****************************************************************************
		virtual task run();

		env_cfg.disable_coverage();
		env_cfg.enable_register_testing();

		generate_default_testing();

		generate_access_ctrl_testing();
			
		generate_crosschecking();

		// Iterate through all generated transactions, passing each down to respective agents.
		fork
				foreach(i2c_trans[i]) i2c_agent_handle.bl_put(i2c_trans[i]);
				foreach(wb_trans[i]) begin
					wb_agent_handle.bl_put(wb_trans[i]);
					if(wb_trans[i].en_printing) ncsu_info("",{get_full_name(),wb_trans[i].to_s_uglyprint},NCSU_LOW); 
				end
			join

		env_cfg.enable_error_testing = 1'b1;
		generate_error_testing();

			// Iterate through all generated transactions, passing each down to respective agents.
			fork
				foreach(i2c_trans[i]) i2c_agent_handle.bl_put(i2c_trans[i]);
				foreach(wb_trans[i]) begin
					wb_agent_handle.bl_put(wb_trans[i]);
					if(wb_trans[i].en_printing) ncsu_info("",{get_full_name(),wb_trans[i].to_s_uglyprint},NCSU_LOW); 
				end
			join



		endtask


	function void generate_default_testing();
		reg_read(CSR);
		reg_read(DPR);
		reg_read(CMDR);
		reg_read(FSMR);
	endfunction
	function void generate_access_ctrl_testing();
		reg_write(CSR, 8'b0011_1111);
		reg_write(CMDR, 8'b0111_1000);
		reg_write(FSMR, 8'hff);
		generate_default_testing();
	endfunction
	function void generate_crosschecking();
		reg_write(CSR, 8'b1100_0000);
		generate_default_testing();
		reg_write(DPR, 8'hff);
		generate_default_testing();
		reg_write(CMDR, 8'b1000_0111);
		generate_default_testing();
	endfunction

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


	// ****************************************************************************
	// Send an explicit transaction to the DUT, requesting a READ of register
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
	// Send an explicit transaction to the DUT, requesting a WRITE of register
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