class i2cmb_generator_test_multi_bus_ranged extends i2cmb_generator;

`ncsu_register_object(i2cmb_generator_test_multi_bus_ranged);

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
		if(trans_name == "i2cmb_generator_test_multi_bus_ranged") begin
			trans_name = "i2c_rand_data_transaction";
		end
		else $fatal;
		verbosity_level = global_verbosity_level;
	endfunction

	// ****************************************************************************
	// Test randomized transactions in the presence of a DUT with 16 Busses, 
	//    	each of which has been instantiated to a different speed, ranging from
	//     400kHz (Maximum) at bus 0 to 32kHz at bus 15.
	// ****************************************************************************
	virtual task run();
		enable_dut_with_interrupt();

		generate_random_base_flow(200, 1);

		super.run();
	endtask

endclass