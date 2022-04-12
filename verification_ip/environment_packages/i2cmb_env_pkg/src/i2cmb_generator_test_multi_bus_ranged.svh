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
	// run the transaction generator; Create all transactions, then, pass trans-
	//		actions to agents, in order, in parallel. 
	// ****************************************************************************
	virtual task run();
		
		generate_random_base_flow(200, 1);
		
		// Iterate through all generated transactions, passing each down to respective agents.
		fork
			foreach(i2c_trans[i]) i2c_agent_handle.bl_put(i2c_trans[i]);
			foreach(wb_trans[i]) begin
				wb_agent_handle.bl_put(wb_trans[i]);
				if(wb_trans[i].en_printing) ncsu_info("",{get_full_name(),wb_trans[i].to_s_prettyprint},NCSU_HIGH);	// Print only pertinent WB transactions per project spec.
			end
		join
	endtask

endclass