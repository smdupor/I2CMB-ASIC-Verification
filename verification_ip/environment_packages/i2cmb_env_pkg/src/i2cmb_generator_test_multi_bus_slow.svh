class i2cmb_generator_test_multi_bus_slow extends i2cmb_generator;
`ncsu_register_object(i2cmb_generator_test_multi_bus_slow);

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
		if(trans_name == "i2cmb_generator_test_multi_bus_slow") begin
			trans_name = "i2c_rand_data_transaction";
		end
		else $fatal;
		verbosity_level = global_verbosity_level;
	endfunction

	// ****************************************************************************
	// Base Multi-bus test flow: Test randomized transactions in a 16-bus DUT
	// ****************************************************************************
	virtual task run();
		enable_dut_with_interrupt();
		generate_random_base_flow(17, 1);
		wb_agent_handle.expect_nacks(1'b0);
		super.run();
	endtask

	//_____________________________________________________________________________________\\
	//                                TEST FLOW GENERATION                                 \\
	//_____________________________________________________________________________________\\


endclass