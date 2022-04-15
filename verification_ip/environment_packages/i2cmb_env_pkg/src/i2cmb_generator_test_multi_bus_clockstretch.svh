class i2cmb_generator_test_multi_bus_clockstretch extends i2cmb_generator;

`ncsu_register_object(i2cmb_generator_test_multi_bus_clockstretch);
	i2c_rand_cs_transaction rnd_trans;
	// ****************************************************************************
	// Constructor, setters and getters
	// ****************************************************************************
	function new(string name = "", ncsu_component_base parent = null);
		super.new(name, parent);
		trans_name = "i2c_rand_cs_transaction";
		verbosity_level = global_verbosity_level;


	endfunction

	// ****************************************************************************
	// Perform tests of CLOCK-STRETCHING functionality, using starts and re-starts,
	// burst and single byte transactions, writes and reads, ALL OF WHICH must  be 
	// clockstretched by the I2C SLAVE BFM on a randomized range from ZERO stretching
	// up to 3x stretching.
	// ****************************************************************************
	virtual task run();
		// Transaction to enable the DUT with interrupts enabled
		enable_dut_with_interrupt();

		// Starts and restarts in presence of clockstretching
		start_restart_with_explicit_waits();

		// Burst and single byte transactions in presence of clockstretching
		burst_burst_alternating_directed_flow();

		// Cover an edge case in this test scenario
		edge_case_clockstretch_scenario();

		// Perform a soft reset
		disable_dut();
		enable_dut_with_interrupt();

		// Issue a LONG explicit wait to cover the LONG edge case.
		issue_wait(4);

		// Issue a transaction with an address match But NO DATA
		no_data_trans();

		// Issue a transaction with NO address and NO data
		issue_start_command();
		issue_stop_command();
		disable_dut();

		// Configure agents and coverage to sample clockstretching values.
		wb_agent_handle.expect_nacks(1'b0);
		i2c_agent_handle.configuration.sample_clockstretch_coverage = 1'b1;

		super.run();
	endtask

	//_____________________________________________________________________________________\\
	//                                TEST FLOW GENERATION                                 \\
	//_____________________________________________________________________________________\\

	// ****************************************************************************
	//  Create a test flow inspired by prior tests, with data bursts as well as 
	//  single bytes, for which clocks may be
	//  NOT Stretched
	//  Stretched slightly      (<25% Longer)
	//  Stretched Significantly (25%-100% Longer)
	//  Stretched Extremely     (>100% Longer, Eg. a 400kHz clock will be reduced below Default (<100kHz))
	// ****************************************************************************
	function void burst_burst_alternating_directed_flow();
		int i,j,k, use_bus;
		use_bus = 0;

		enable_dut_with_interrupt();

		j = 64;
		k = 63;
		for (int i = 0; i < 200; ++i) begin // (i2c_trans[i]) begin
			$cast(trans, ncsu_object_factory::create("i2c_rand_cs_transaction"));

			// pick  a bus, sequentially picking a new bus for each major transaction
			trans.selected_bus = use_bus++;

			//++use_bus;
			if (use_bus > 15) use_bus = 0;

			// pick an address
			trans.address = (i % 126) + 1;

			// Start with a WRITE BURST, randomly clockstretched.
			if (i == 0) begin
				create_explicit_data_series(0, 31, i, I2_WRITE);
				trans.randomize();
				i2c_trans.push_back(trans);
				convert_i2c_trans(trans, 1, 1);
				disable_dut();
				enable_dut_with_interrupt();
			end

			// THEN, perform a READ BURST, randomly clockstretched.
			if (i == 1) begin
				create_explicit_data_series(100, 131, i, I2_READ);
				trans.randomize();
				i2c_trans.push_back(trans);
				convert_i2c_trans(trans, 1, 1);
				issue_wait(6);
				j = 64;
			end

			// THEN, perform alternating actions, randomly clockstretched.
			if (i > 1 && i % 2 == 0) begin // do a write
				create_explicit_data_series(j, j, i, I2_WRITE);
				trans.randomize();
				i2c_trans.push_back(trans);
				convert_i2c_trans(trans, 1, 1);
				++j;
			end
			else if (i > 1 && i % 2 == 1) begin // do a read
				create_explicit_data_series(k, k, i, I2_READ);
				trans.randomize();
				i2c_trans.push_back(trans);
				convert_i2c_trans(trans, 1, 1);
				--k;
			end
		end
	endfunction

	// ****************************************************************************
	// Cover any specific edge cases not caught by prior randomized transactions,
	// With clockstretching enabled.
	// ****************************************************************************
	function edge_case_clockstretch_scenario();

		// Directed test, specific scenario
		$cast(rnd_trans, ncsu_object_factory::create("i2c_rand_cs_transaction"));
		$cast(trans, ncsu_object_factory::create("i2c_transaction"));
		// pick  a bus, sequentially picking a new bus for each major transaction
		rnd_trans.selected_bus = 11;

		// pick an address
		rnd_trans.set_address(106);
		rnd_trans.set_op(I2_WRITE);
		rnd_trans.randomize();
		rnd_trans.set_clock_stretch_qty(1800);
		create_explicit_data_series(36, 38, 0, I2_WRITE);
		rnd_trans.data=trans.data;
		i2c_trans.push_back(rnd_trans);
		convert_i2c_trans(rnd_trans, 1, 1);

		// Directed test, specific scenario
		$cast(rnd_trans, ncsu_object_factory::create("i2c_rand_cs_transaction"));
		$cast(trans, ncsu_object_factory::create("i2c_transaction"));
		// pick  a bus, sequentially picking a new bus for each major transaction
		rnd_trans.selected_bus = 4;

		// pick an address
		rnd_trans.set_address(50);
		rnd_trans.set_op(I2_WRITE);
		rnd_trans.randomize();
		rnd_trans.set_clock_stretch_qty(8500);
		create_explicit_data_series(101, 103,0, I2_WRITE);
		rnd_trans.data=trans.data;
		i2c_trans.push_back(rnd_trans);
		convert_i2c_trans(rnd_trans, 1, 1);

		// Directed test, specific scenario
		$cast(rnd_trans, ncsu_object_factory::create("i2c_rand_cs_transaction"));
		$cast(trans, ncsu_object_factory::create("i2c_transaction"));
		// pick  a bus, sequentially picking a new bus for each major transaction
		rnd_trans.selected_bus = 4;

		// pick an address
		rnd_trans.set_address(50);
		rnd_trans.set_op(I2_WRITE);
		rnd_trans.randomize();
		rnd_trans.set_clock_stretch_qty(12000);
		create_explicit_data_series(101, 103,0, I2_WRITE);
		rnd_trans.data=trans.data;
		i2c_trans.push_back(rnd_trans);
		convert_i2c_trans(rnd_trans, 1, 1);


		// Directed test, specific scenario
		$cast(rnd_trans, ncsu_object_factory::create("i2c_rand_cs_transaction"));
		$cast(trans, ncsu_object_factory::create("i2c_transaction"));
		// pick  a bus, sequentially picking a new bus for each major transaction
		rnd_trans.selected_bus = 4;

		// pick an address
		rnd_trans.set_address(67);
		rnd_trans.set_op(I2_WRITE);
		rnd_trans.randomize();
		rnd_trans.set_clock_stretch_qty(13000);
		create_explicit_data_series(101, 103,0, I2_WRITE);
		rnd_trans.data=trans.data;
		i2c_trans.push_back(rnd_trans);
		convert_i2c_trans(rnd_trans, 1, 1);
	endfunction

	// ****************************************************************************
	//  Cover a start-restart transactions in the presence of clockstretching, with
	// Explicit WAIT commands also performed.
	// ****************************************************************************
	function void start_restart_with_explicit_waits();
		int j;
		enable_dut_with_interrupt();

		// INJECT AN EXPLICIT WAIT HERE of MEDIUM SIZE.
		issue_wait(1);

		// Perform start-restart transactions
		$cast(trans, ncsu_object_factory::create("i2c_transaction"));

		trans.selected_bus = 14;
		trans.address = 37;

		create_explicit_data_series(0, 31, 0, I2_WRITE);
		i2c_trans.push_back(trans);
		convert_i2c_trans(trans, 1, 0);

		// Do A simple re-start on the same bus
		$cast(trans, ncsu_object_factory::create("i2c_transaction"));
		trans.selected_bus = 14;
		trans.address = 50;

		create_explicit_data_series(100, 131, 0, I2_READ);
		i2c_trans.push_back(trans);
		convert_i2c_trans(trans, 0, 0);

		// Do another restart transaction BUT ADD AN WISHBONE END UPSTREAM STALL
		$cast(trans, ncsu_object_factory::create("i2c_transaction"));
		// Send a start command
		issue_start_command();

		trans.selected_bus = 14;

		// pick an address
		trans.address = (36) + 1;

		transmit_address_req_write(trans.address);
		for (j = 0; j <= 31; j++) write_data_byte(byte'(j));
		write_data_byte_with_stall(byte'(j), 101);
		i2c_trans.push_back(trans);
		issue_stop_command();
		disable_dut();
	endfunction
endclass
	