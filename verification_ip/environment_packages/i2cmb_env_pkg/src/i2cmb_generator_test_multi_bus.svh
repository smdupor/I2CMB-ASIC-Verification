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
	// Base Multi-bus test flow: Test randomized transactions in a 16-bus DUT
	// ****************************************************************************
	virtual task run();
		enable_dut_with_interrupt();
		generate_random_base_flow(300, 1);
		generate_directed_targets();
		wb_agent_handle.expect_nacks(1'b0);
		super.run();
	endtask

	//_____________________________________________________________________________________\\
	//                                TEST FLOW GENERATION                                 \\
	//_____________________________________________________________________________________\\

	// Target several specific scenarios needing coverage in the multi-bus base configuration
	function void generate_directed_targets();
		i2c_rand_data_transaction rand_trans;

		$cast(rand_trans,ncsu_object_factory::create("i2c_rand_data_transaction"));

		rand_trans.randomize();
		rand_trans.selected_bus = 3;
		rand_trans.address = 37;
		rand_trans.rw = I2_READ;
		i2c_trans.push_back(rand_trans);
		convert_rand_i2c_trans(rand_trans, 1, 0);

		$cast(rand_trans,ncsu_object_factory::create("i2c_rand_data_transaction"));

		rand_trans.randomize();
		rand_trans.selected_bus = 3;
		rand_trans.address = 41;
		rand_trans.rw = I2_READ;
		i2c_trans.push_back(rand_trans);
		convert_rand_i2c_trans(rand_trans, 0, 0);

		$cast(rand_trans,ncsu_object_factory::create("i2c_rand_data_transaction"));

		rand_trans.randomize();
		rand_trans.selected_bus = 3;
		rand_trans.address = 59;
		rand_trans.rw = I2_READ;
		i2c_trans.push_back(rand_trans);
		convert_rand_i2c_trans(rand_trans, 0, 1);
		
		$cast(rand_trans,ncsu_object_factory::create("i2c_rand_data_transaction"));

		rand_trans.randomize();
		rand_trans.selected_bus = 3;
		rand_trans.address = 108;
		rand_trans.rw = I2_WRITE;
		i2c_trans.push_back(rand_trans);
		convert_rand_i2c_trans(rand_trans, 0, 1);

		$cast(rand_trans,ncsu_object_factory::create("i2c_rand_data_transaction"));

		rand_trans.randomize();
		rand_trans.selected_bus = 3;
		rand_trans.address = 33;
		rand_trans.rw = I2_READ;
		i2c_trans.push_back(rand_trans);
		convert_rand_i2c_trans(rand_trans, 0, 1);
	endfunction
endclass