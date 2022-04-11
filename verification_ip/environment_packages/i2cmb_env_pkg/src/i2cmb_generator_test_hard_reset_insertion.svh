class i2cmb_generator_test_hard_reset_insertion extends i2cmb_generator;
`ncsu_register_object(i2cmb_generator_test_hard_reset_insertion);
	// ****************************************************************************
	// Constructor, setters and getters
	// ****************************************************************************
	function new(string name = "", ncsu_component_base  parent = null);
		super.new(name,parent);
		$finish;
		if ( !$value$plusargs("GEN_TRANS_TYPE=%s", trans_name)) begin
			$display("FATAL: +GEN_TRANS_TYPE plusarg not found on command line");
			$fatal;
		end
		
		$display("%m found +GEN_TRANS_TYPE=%s", trans_name);
		if(trans_name == "i2c_arb_loss_transaction") begin

		end
		else if(trans_name != "i2cmb_test_multi_bus_range" || trans_name == "i2c_arb_loss_transaction") begin $fatal; end
		else begin
			trans_name = "i2c_rand_cs_transaction";
		end
		verbosity_level = global_verbosity_level;
	endfunction

	function void set_wb_agent(wb_agent agent);
		this.wb_agent_handle = agent;
	endfunction

	function void set_i2c_agent(i2c_agent agent);
		this.i2c_agent_handle = agent;
	endfunction

 	// ****************************************************************************
	// run the transaction generator; Create all transactions, then, pass trans-
	//		actions to agents, in order, in parallel. 
	// ****************************************************************************
	virtual task run();
		if(trans_name == "i2c_arb_loss_transaction") begin
			generate_arb_loss_flow();
			wb_agent_handle.configuration.expect_arb_loss = 1'b1;
		end
		else begin
		generate_directed_project_2_test_transactions();
		wb_agent_handle.expect_nacks(1'b0);
		end
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