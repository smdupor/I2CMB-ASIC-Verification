class i2cmb_generator_test_multi_bus_clockstretch extends i2cmb_generator;

  `ncsu_register_object(i2cmb_generator_test_multi_bus_clockstretch);


  // ****************************************************************************
  // Constructor, setters and getters
  // ****************************************************************************
  function new(string name = "", ncsu_component_base parent = null);
    super.new(name, parent);
    trans_name = "i2c_rand_cs_transaction";
    verbosity_level = global_verbosity_level;
  
	
  endfunction

  // ****************************************************************************
  // run the transaction generator; Create all transactions, then, pass trans-
  //		actions to agents, in order, in parallel. 
  // ****************************************************************************
  virtual task run();
    // Transaction to enable the DUT with interrupts enabled
    enable_dut_with_interrupt();

    clockstretch_directed_flow();

    wb_agent_handle.expect_nacks(1'b0);
    i2c_agent_handle.configuration.sample_clockstretch_coverage = 1'b1;

    // Iterate through all generated transactions, passing each down to respective agents.
    fork
      foreach (i2c_trans[i]) i2c_agent_handle.bl_put(i2c_trans[i]);
      foreach (wb_trans[i]) begin
        wb_agent_handle.bl_put(wb_trans[i]);
        if (wb_trans[i].en_printing)
          ncsu_info("", {get_full_name(), wb_trans[i].to_s_prettyprint},
                    NCSU_HIGH);  // Print only pertinent WB transactions per project spec.
      end
    join
  endtask

  // ****************************************************************************
  // Create all required transactions for the project 2 directed tests, 
  //  Including 	WRITE 0 -> 31
  //				READ 100 -> 131
  // 				WRITE/READ Alternating 64->127 interleave 63 -> 0 
  // ****************************************************************************
  virtual function void clockstretch_directed_flow();
    int i, j, k, use_bus;

    start_restart_with_explicit_waits();

    use_bus = 0;
    // Transaction to enable the DUT with interrupts enabled
    enable_dut_with_interrupt();

    j = 64;
    k = 63;
    for (int i = 0; i < 200; ++i) begin  // (i2c_trans[i]) begin
      $cast(trans, ncsu_object_factory::create("i2c_rand_cs_transaction"));

      // pick  a bus, sequentially picking a new bus for each major transaction
      trans.selected_bus = use_bus;

      //select_I2C_bus(trans.selected_bus);

      ++use_bus;
      if (use_bus > 15) use_bus = 0;

      // pick an address
      trans.address = (i % 126) + 1;

      // WRITE ALL (Write 0 to 31 to remote Slave)
      if (i == 0) begin
        create_explicit_data_series(0, 31, i, I2_WRITE);
        trans.randomize();
        i2c_trans.push_back(trans);
        convert_i2c_trans(trans, 1, 1);
        disable_dut();
        enable_dut_with_interrupt();
      end

      // READ ALL (Read 100 to 131 from remote slave)
      if (i == 1) begin
        create_explicit_data_series(100, 131, i, I2_READ);
        trans.randomize();
        i2c_trans.push_back(trans);
        convert_i2c_trans(trans, 1, 1);
        issue_wait(1);
        j = 64;
      end

      // Alternation EVEN (Handle the Write step in Write/Read Alternating TF)
      if (i > 1 && i % 2 == 0) begin  // do a write
        create_explicit_data_series(j, j, i, I2_WRITE);
        trans.randomize();
        i2c_trans.push_back(trans);
        convert_i2c_trans(trans, 1, 1);
        ++j;
      end  // Alternation ODD(Handle the Read step in Write/Read Alternating TF)
      else if (i > 1 && i % 2 == 1) begin  // do a write
        create_explicit_data_series(k, k, i, I2_READ);
        trans.randomize();
        i2c_trans.push_back(trans);
        convert_i2c_trans(trans, 1, 1);
        --k;
      end
    end

    // Directed test, specific scenario
    $cast(trans, ncsu_object_factory::create("i2c_rand_cs_transaction"));

    // pick  a bus, sequentially picking a new bus for each major transaction
    trans.selected_bus = 7;

    // pick an address
    trans.address = 36;
    create_explicit_data_series(36, 38, i, I2_WRITE);
    trans.randomize();
    trans.clock_stretch_qty = 4500;
    i2c_trans.push_back(trans);
    convert_i2c_trans(trans, 1, 1);

    // Directed test, specific scenario
    $cast(trans, ncsu_object_factory::create("i2c_rand_cs_transaction"));

    // pick  a bus, sequentially picking a new bus for each major transaction
    trans.selected_bus = 5;

    // pick an address
    trans.address = 42;
    create_explicit_data_series(101, 103, i, I2_WRITE);
    trans.randomize();
    trans.clock_stretch_qty = 1800;
    i2c_trans.push_back(trans);
    convert_i2c_trans(trans, 1, 1);

    disable_dut();

    enable_dut_with_interrupt();
    issue_wait(11);

    no_data_trans();

    issue_start_command();
    issue_stop_command();
    disable_dut();

  endfunction


function void start_restart_with_explicit_waits();
    int j;
    enable_dut_with_interrupt();
    issue_wait(6);
    $cast(trans, ncsu_object_factory::create("i2c_transaction"));

    // pick  a bus, sequentially picking a new bus for each major transaction
    trans.selected_bus = 0;
    select_I2C_bus(trans.selected_bus);


    // pick  a bus, sequentially picking a new bus for each major transaction
    trans.selected_bus = 0;
    trans.address = (36) + 1;


    issue_start_command();
    transmit_address_req_write(trans.address);
    for (j = 0; j <= 31; j++) write_data_byte(byte'(j));
    write_data_byte_with_stall(byte'(j), 10);
    j = 64;
    i2c_trans.push_back(trans);
    $cast(trans, ncsu_object_factory::create("i2c_transaction"));
    // Send a start command
    issue_start_command();

    // pick an address
    trans.address = (36) + 1;

    // WRITE ALL (Write 0 to 31 to remote Slave)
    transmit_address_req_read(trans.address);
    for (j = 100; j <= 130; j++) read_data_byte_with_continue();
    read_data_byte_with_stop();
    create_explicit_data_series(100, 131, j, I2_READ);

    // Send a start command
    i2c_trans.push_back(trans);

    $cast(trans, ncsu_object_factory::create("i2c_transaction"));
    // Send a start command
    issue_start_command();

    // pick an address
    trans.address = (36) + 1;

    transmit_address_req_write(trans.address);
    for (j = 0; j <= 31; j++) write_data_byte(byte'(j));
    write_data_byte_with_stall(byte'(j), 101);
    i2c_trans.push_back(trans);

    disable_dut();
  endfunction
endclass
