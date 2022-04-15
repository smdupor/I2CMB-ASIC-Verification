class i2cmb_generator_test_multi_bus extends i2cmb_generator;
`ncsu_register_object(i2cmb_generator_test_multi_bus);

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
		if(trans_name == "i2cmb_generator_test_multi_bus") begin
			trans_name = "i2c_rand_data_transaction";
		end
		else $fatal;
		verbosity_level = global_verbosity_level;
	endfunction

	// ****************************************************************************
	// run the transaction generator; Create all transactions, then, pass trans-
	//		actions to agents, in order, in parallel. 
	// ****************************************************************************
	virtual task run();
		enable_dut_with_interrupt();
		generate_random_base_flow(250, 1);
		generate_directed_targets();
		wb_agent_handle.expect_nacks(1'b0);
		super.run();
	endtask

	// Target several specific scenarios needing cover
	function void generate_directed_targets();
		i2c_rand_data_transaction rand_trans;

		$cast(rand_trans,ncsu_object_factory::create("i2c_rand_data_transaction"));

		rand_trans.randomize();
		rand_trans.selected_bus = 3;
		rand_trans.address = 3;
		rand_trans.rw = I2_READ;
		i2c_trans.push_back(rand_trans);
		convert_rand_i2c_trans(rand_trans, 1, 0);

		$cast(rand_trans,ncsu_object_factory::create("i2c_rand_data_transaction"));

		rand_trans.randomize();
		rand_trans.selected_bus = 3;
		rand_trans.address = 65;
		rand_trans.rw = I2_READ;
		i2c_trans.push_back(rand_trans);
		convert_rand_i2c_trans(rand_trans, 0, 0);

		$cast(rand_trans,ncsu_object_factory::create("i2c_rand_data_transaction"));

		rand_trans.randomize();
		rand_trans.selected_bus = 3;
		rand_trans.address = 9;
		rand_trans.rw = I2_READ;
		i2c_trans.push_back(rand_trans);
		convert_rand_i2c_trans(rand_trans, 0, 1);
	endfunction
endclass