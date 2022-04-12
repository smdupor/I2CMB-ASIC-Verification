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
		
		generate_random_base_flow(5, 1);
		//reworked_directed_project_2_test_transactions();
		//foreach(i2c_trans[i]) $display(i2c_trans[i].convert2string);
		wb_agent_handle.expect_nacks(1'b0);
		// Iterate through all generated transactions, passing each down to respective agents.
		fork
			foreach(i2c_trans[i]) i2c_agent_handle.bl_put(i2c_trans[i]);
			foreach(wb_trans[i]) begin
				wb_agent_handle.bl_put(wb_trans[i]);
				if(wb_trans[i].en_printing) ncsu_info("",{get_full_name(),wb_trans[i].to_s_prettyprint},NCSU_HIGH);	// Print only pertinent WB transactions per project spec.
			end
		join
	endtask
virtual function void reworked_directed_project_2_test_transactions();
		int i,j,k,use_bus;
		i2c_rand_data_transaction trns;
//		start_restart_trns();

		use_bus = 0;
		// trnsaction to enable the DUT with interrupts enabled
		enable_dut_with_interrupt();

		j=64;
		k=63;
		for(int i = 0; i<200;++i) begin// (i2c_trns[i]) begin
			$cast(trns,ncsu_object_factory::create("i2c_rand_data_transaction"));

			// pick  a bus, sequentially picking a new bus for each major transaction
			trns.selected_bus=use_bus;
			
			//select_I2C_bus(trns.selected_bus);

			++use_bus;
			if(use_bus > 15) use_bus = 0;

			// pick an address
			trns.address = (i % 126)+1;

			// WRITE ALL (Write 0 to 31 to remote Slave)
			if(i==0) begin
				rnd_create_explicit_data_series(trns,0, 31, i, I2_WRITE);
				trns.randomize();
		//		foreach(trns.tmp_data[i]) trns.data[i]=trns.tmp_data[i];
				i2c_trans.push_back(trns);
				convert_i2c_trans(trns, 1, 1);
				disable_dut();
				enable_dut_with_interrupt();
			end

			// READ ALL (Read 100 to 131 from remote slave)
			if(i==1) begin
				rnd_create_explicit_data_series(trns,100, 131, i, I2_READ);
				trns.randomize();
	//			foreach(trns.tmp_data[i])trns.data[i]=trns.tmp_data[i];
				i2c_trans.push_back(trns);
				convert_i2c_trans(trns, 1, 1);
				issue_wait(1);
				j=64;
			end

			// Alternation EVEN (Handle the Write step in Write/Read Alternating TF)
			if(i>1 && i % 2 == 0) begin // do a write
				rnd_create_explicit_data_series(trns,j, j, i, I2_WRITE);
				trns.randomize();
		//		foreach(trns.tmp_data[i])trns.data[i]=trns.tmp_data[i];
				i2c_trans.push_back(trns);
				convert_i2c_trans(trns, 1, 1);
				++j;
			end

			// Alternation ODD(Handle the Read step in Write/Read Alternating TF)
			else if (i>1 && i % 2 == 1) begin // do a write
				rnd_create_explicit_data_series(trns,k, k, i, I2_READ);
				trns.randomize();
	//			foreach(trns.tmp_data[i])trns.data[i]=trns.tmp_data[i];
				i2c_trans.push_back(trns);
				convert_i2c_trans(trns, 1, 1);
				--k;
			end
		end
		disable_dut();
		enable_dut_polling();
		disable_dut();

		enable_dut_with_interrupt();
		issue_wait(11);
		
		no_data_trans();
		
		issue_start_command();
		issue_stop_command();
		disable_dut();

	endfunction
endclass