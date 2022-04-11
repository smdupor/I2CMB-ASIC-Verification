class i2cmb_generator_arb_loss extends i2cmb_generator;

`ncsu_register_object(i2cmb_generator_arb_loss);

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
		if(trans_name == "i2cmb_generator_arb_loss") begin
			trans_name="i2c_arb_loss_transaction";
		end
		else if(trans_name != "i2cmb_test_multi_bus_range" || trans_name == "i2c_arb_loss_transaction") begin $fatal; end
		else begin
			trans_name = "i2c_rand_cs_transaction";
		end
		verbosity_level = global_verbosity_level;
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
	
	function void generate_arb_loss_flow();
		int j=64;
		int k=63;
		int i=0;
		
			$cast(i2c_trans[i],ncsu_object_factory::create(trans_name));
		// Transaction to enable the DUT with interrupts enabled
		enable_dut_with_interrupt();
			
			// pick  a bus, sequentially picking a new bus for each major transaction
			i2c_trans[i].selected_bus=0;
			//arb_loss_select_bus
			select_I2C_bus(i2c_trans[i].selected_bus);
			
			// Send a start command
			//arb_loss_start();
			issue_start_command();
			// pick an address
			i2c_trans[i].address = 127;

			// WRITE ALL (Write 0 to 31 to remote Slave)
			if(i==0) begin
				//transmit_address_req_write(i2c_trans[i].address);
				//for(j=0;j<=31;j++) write_data_byte(byte'(j));
				//create_explicit_data_series(0, 31, i, I2_WRITE);
				arb_loss_address_req_write(i2c_trans[i].address);
				issue_stop_command();
			end
	endfunction

endclass