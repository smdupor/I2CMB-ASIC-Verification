class i2cmb_generator_test_single_bus extends i2cmb_generator;
`ncsu_register_object(i2cmb_generator_test_single_bus);
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
		if(trans_name == "i2cmb_generator_test_single_bus") begin
			trans_name = "i2c_rand_data_transaction";
		end
		else $fatal;
		verbosity_level = global_verbosity_level;
	endfunction

	// ****************************************************************************
	// TEST FOR A DUT INSTANCE WITH ONLY ONE BUS. TEST LEGAL AND ILLEGAL BUS SELECTIONS.
	// ****************************************************************************
	virtual task run();
		enable_dut_with_interrupt();

		generate_single_bus_random_base_flow(75, 1);
		wb_agent_handle.expect_nacks(1'b0);
		env_cfg.expect_bus_mismatch = 1'b0;
		wb_agent_handle.configuration.expect_bus_mismatch = 1'b0;

		// Run The first flow and delete it from Generator once complete
		super.run();
		i2c_trans.delete();
		wb_trans.delete();

		generate_random_bus_error_flow(75, 0);
		foreach(i2c_trans[i]) i2c_trans[i].selected_bus = 0;
		env_cfg.expect_bus_mismatch = 1'b1;
		wb_agent_handle.configuration.expect_bus_mismatch = 1'b1;
		env_cfg.disable_bus_checking = 1'b1;
		

		super.run();
	endtask

	//_____________________________________________________________________________________\\
	//                                TEST FLOW GENERATION                                 \\
	//_____________________________________________________________________________________\\

	// ****************************************************************************
	// In a DUT with only one bus, selecting a bus with number > 0 will raise a 
  	// bus select error bit, but, will default to using the existing bus 0.
	// Create random verification transactions initiating this particular flow.
	// ****************************************************************************
	virtual function void generate_random_bus_error_flow(int qty, bit change_busses);
		i2c_rand_data_transaction rand_trans;

		for(int i = 0; i<qty;++i) begin // (i2c_trans[i]) begin
			$cast(rand_trans,ncsu_object_factory::create("i2c_rand_data_transaction"));
			rand_trans.randomize();
			if(rand_trans.selected_bus == 0) rand_trans.selected_bus = 1;
			i2c_trans.push_back(rand_trans);
			convert_rand_i2c_trans(rand_trans, 1, 1);
		end
	endfunction

	// ****************************************************************************
	// Create a series of random transactions, overriding randomization of bus 
	// selection to validate correct-bus-selection on a single bus DUT.
	// ****************************************************************************
	virtual function void generate_single_bus_random_base_flow(int qty, bit change_busses);
		i2c_rand_data_transaction rand_trans;

		for(int i = 0; i<qty;++i) begin
			$cast(rand_trans,ncsu_object_factory::create("i2c_rand_data_transaction"));
			rand_trans.randomize();
			rand_trans.selected_bus = 0;
			i2c_trans.push_back(rand_trans);
			convert_rand_i2c_trans(rand_trans, 1, 1);
		end
	endfunction
endclass