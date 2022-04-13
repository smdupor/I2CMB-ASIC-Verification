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
		// run the transaction generator; Create all transactions, then, pass trans-
		//		actions to agents, in order, in parallel. 
		// ****************************************************************************
		virtual task run();
		// Transaction to enable the DUT with interrupts enabled
			enable_dut_with_interrupt();
			generate_single_random_base_flow(75, 1);

			wb_agent_handle.expect_nacks(1'b0);
			wb_agent_handle.configuration.expect_bus_mismatch = 1'b0;
			// Iterate through all generated transactions, passing each down to respective agents.
			fork
				foreach(i2c_trans[i]) i2c_agent_handle.bl_put(i2c_trans[i]);
				foreach(wb_trans[i]) begin
					wb_agent_handle.bl_put(wb_trans[i]);
					if(wb_trans[i].en_printing) ncsu_info("",{get_full_name(),wb_trans[i].to_s_prettyprint},NCSU_HIGH); // Print only pertinent WB transactions per project spec.
				end
			join

			i2c_trans.delete();
			wb_trans.delete();

			generate_random_base_flow(75, 0);
		
			foreach(i2c_trans[i]) i2c_trans[i].selected_bus = 0;
			
			wb_agent_handle.configuration.expect_bus_mismatch = 1'b1;
			env_cfg.disable_bus_checking = 1'b1;
		
			
			// Iterate through all generated transactions, passing each down to respective agents.
			fork
				foreach(i2c_trans[i]) i2c_agent_handle.bl_put(i2c_trans[i]);
				foreach(wb_trans[i]) begin
					wb_agent_handle.bl_put(wb_trans[i]);
					if(wb_trans[i].en_printing) ncsu_info("",{get_full_name(),wb_trans[i].to_s_prettyprint},NCSU_HIGH); // Print only pertinent WB transactions per project spec.
				end
			join
		endtask

	virtual function void generate_random_base_flow(int qty, bit change_busses);
		int i,j,k,use_bus;
		i2c_rand_data_transaction rand_trans;
		use_bus = 0;

		for(int i = 0; i<qty;++i) begin // (i2c_trans[i]) begin
			$cast(rand_trans,ncsu_object_factory::create("i2c_rand_data_transaction"));

			rand_trans.randomize();
			if(rand_trans.selected_bus == 0) rand_trans.selected_bus = 1;
			i2c_trans.push_back(rand_trans);
			convert_rand_i2c_trans(rand_trans, 1, 1);
		end
	endfunction

		virtual function void generate_single_random_base_flow(int qty, bit change_busses);
		int i,j,k,use_bus;
		i2c_rand_data_transaction rand_trans;
		use_bus = 0;

		for(int i = 0; i<qty;++i) begin 
			$cast(rand_trans,ncsu_object_factory::create("i2c_rand_data_transaction"));

			rand_trans.randomize();
			rand_trans.selected_bus = 0;
			i2c_trans.push_back(rand_trans);
			convert_rand_i2c_trans(rand_trans, 1, 1);
		end
	endfunction
	endclass