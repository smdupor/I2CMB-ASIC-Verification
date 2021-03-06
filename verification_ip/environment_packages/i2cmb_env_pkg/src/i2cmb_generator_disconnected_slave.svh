class i2cmb_generator_disconnected_slave extends i2cmb_generator;

`ncsu_register_object(i2cmb_generator_disconnected_slave);

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
		if(trans_name == "i2cmb_generator_disconnected_slave") begin
			trans_name = "i2c_rand_data_transaction";
		end
		else $fatal;
		verbosity_level = global_verbosity_level;
	endfunction

	// ****************************************************************************
	// Test DUT behavior in the presence of a "Disconnected" Slave, or an I2C slave
	// which never ACKs communications from the master as expected. Expect DUT to 
	// raise NACK bits when these disconnected transactions occur, but to complete
	//  (The ADDRESS and WRITE) transactions successfully, albeit with NACKs.
	// ****************************************************************************
	virtual task run();

		// Transaction to enable the DUT with interrupts enabled
		enable_dut_with_interrupt();

		// Ensure that addresses will be mismatched, so BFM does not respond (causing NACKs). 
		// Predictor will un-do the mismatched addresses by the same amount to confirm 
		// transactions are accurate.
		env_cfg.set_address_shift(1);
		env_cfg.expect_nacks = 1'b1;
		wb_agent_handle.expect_nacks(1'b1);

		generate_random_base_flow(50, 1);

		super.run();
	endtask
	
	//_____________________________________________________________________________________\\
	//                                TEST FLOW GENERATION                                 \\
	//_____________________________________________________________________________________\\

	virtual function void generate_random_base_flow(int qty, bit change_busses);
		int i,j,k,use_bus;
		i2c_rand_data_transaction rand_trans;
		use_bus = 0;

		for(int i = 0; i<qty;++i) begin // (i2c_trans[i]) begin
			$cast(rand_trans,ncsu_object_factory::create("i2c_rand_data_transaction"));

			rand_trans.randomize();
			rand_trans.rw = I2_WRITE;
			i2c_trans.push_back(rand_trans);
			convert_rand_i2c_trans(rand_trans, 1, 1);
		end
	endfunction

endclass