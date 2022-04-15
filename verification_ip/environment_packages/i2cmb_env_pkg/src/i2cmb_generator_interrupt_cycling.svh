class i2cmb_generator_interrupt_cycling extends i2cmb_generator;
`ncsu_register_object(i2cmb_generator_interrupt_cycling);

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
		if(trans_name == "i2cmb_generator_interrupt_cycling") begin
			trans_name = "i2c_rand_data_transaction";
		end
		else $fatal;
		verbosity_level = global_verbosity_level;
	endfunction

	// ****************************************************************************
	//  Perform tests where the DUT is configured first to use interrupts, 
	//  then without interrupts, and switches between these modes, verifying that
	// 	interrupts are raised as expected, and not when not expected, and that 
	// 	switching of modes is successful.
	// ****************************************************************************
	virtual task run();

		// Do a small flow using interrupts
		enable_dut_with_interrupt();
		generate_random_base_flow(40, 1);
		disable_dut();

		// Do a small flow using interrupts
		enable_dut_with_interrupt();
		generate_random_base_flow(40, 1);
		disable_dut();

		// Do a small flow using polling		
		enable_dut_polling();
		generate_random_base_flow(40, 1);
		disable_dut();

		// Do a small flow using polling
		enable_dut_polling();
		generate_random_base_flow(40, 1);
		disable_dut();

		// Do a small flow using interrupts
		enable_dut_with_interrupt();
		generate_random_base_flow(40, 1);
		disable_dut();

		// Do a small flow using polling
		enable_dut_polling();
		generate_random_base_flow(40, 1);

		super.run();
	endtask

endclass