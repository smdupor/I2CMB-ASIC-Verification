class i2cmb_generator extends ncsu_component #(.T(i2c_transaction));

  i2cmb_env_configuration env_cfg;
  i2c_transaction i2c_trans[$];
  i2c_rand_data_transaction i2c_rand_trans[$];
  i2c_transaction trans;
  wb_transaction wb_trans[$];
  wb_agent wb_agent_handle;
  i2c_agent i2c_agent_handle;
  string trans_name;
  i2cmb_predictor pd;

  //  POLLING DEFAULTS for 400kHz MAX SPEED busses
  const int sel_pause = 20;
  const int start_pause = 150;
  const int data_pause = 2500;
  const int stop_pause = 250;
  bit enable_polling;

  // ****************************************************************************
  // Constructor, setters and getters
  // ****************************************************************************
  function new(string name = "", ncsu_component_base parent = null);
    super.new(name, parent);
    verbosity_level = global_verbosity_level;
  endfunction

  virtual function void set_wb_agent(wb_agent agent);
    this.wb_agent_handle = agent;
  endfunction

  virtual function void set_i2c_agent(i2c_agent agent);
    this.i2c_agent_handle = agent;
  endfunction

  // ****************************************************************************
  //  Run the base generator: Send a series of transactions to the agents. 
  //
  // Transaction flows are created by child objects of this class.
  // ****************************************************************************
  virtual task run();
    fork
			foreach(i2c_trans[i]) i2c_agent_handle.bl_put(i2c_trans[i]);
			foreach(wb_trans[i]) begin
				wb_agent_handle.bl_put(wb_trans[i]);
				if(wb_trans[i].en_printing) ncsu_info("",{get_full_name(),wb_trans[i].to_s_prettyprint},NCSU_HIGH); // Print only pertinent WB transactions per project spec.
			end
		join
    wb_trans.delete();
    i2c_trans.delete();
  endtask

  //_____________________________________________________________________________________\\
	//                                TEST FLOW GENERATION                                 \\
	//_____________________________________________________________________________________\\

	// ****************************************************************************
	// Create a series of (qty) RANDOMIZED I2C Transactions, indicating whether
  // either the prior or subsequent transaction will take place on a different
  // bus, meaning: A bus selection action must take place AND each transaction
  // must conclude in a STOP action.
	// ****************************************************************************
  virtual function void generate_random_base_flow(int qty, bit change_busses);
    i2c_rand_data_transaction rand_trans;

    for (int i = 0; i < qty; ++i) begin  // (i2c_trans[i]) begin
      $cast(rand_trans, ncsu_object_factory::create("i2c_rand_data_transaction"));

      rand_trans.randomize();
      i2c_trans.push_back(rand_trans);
      convert_rand_i2c_trans(rand_trans, change_busses, change_busses);
    end
  endfunction


	// ****************************************************************************
	// Create a simple NO-DATA transaction, where a connection is opened, the 
  // address and operation are transmitted, then the connection is closed.
	// ****************************************************************************
  function void no_data_trans();
    $cast(trans, ncsu_object_factory::create("i2c_transaction"));
    // Select a bus for the no-data transaction
    trans.selected_bus = 0;
    select_I2C_bus(trans.selected_bus);

    // Send the start, send the address, then close the connection.
    trans.address = (36) + 1;
    issue_start_command();
    transmit_address_req_write(trans.address);
    issue_stop_command();
    i2c_trans.push_back(trans);
  endfunction

  //_____________________________________________________________________________________\\
	//                                TRANSACTION CONVERTERS                               \\
	//_____________________________________________________________________________________\\

	// ****************************************************************************
	// Convert a DIRECTED (non-random) I2C Transaction into the requisite Wishbone 
  // transactions to be executed on the wishbone end of the DUT
	// ****************************************************************************
  virtual function void convert_i2c_trans(i2c_transaction t, bit add_bus_sel, bit add_stop);
    int address = t.address;
    // Support address-mismatched (Slave Disconnected) Transactions
    if (env_cfg.get_address_shift() != 0) begin
      address -= env_cfg.get_address_shift();
      if (address < 0) address = 127 - env_cfg.get_address_shift() + 1;
    end

    // Select the bus, if a change of bus is desired
    if (add_bus_sel) select_I2C_bus(t.selected_bus);

     // Send the start command
    issue_start_command();

    // Send the address request, and subsequent data, if applicable for a READ or a WRITE.
    if (t.rw == I2_WRITE || env_cfg.get_address_shift() != 0) begin
      transmit_address_req_write(address);
      foreach (t.data[i]) begin
        write_data_byte(byte'(t.data[i]));
      end
    end else begin
      transmit_address_req_read(t.address);
      for (int i = 0; i < t.data.size - 1; i++) read_data_byte_with_continue();
      read_data_byte_with_stop();
    end

    // If we are testing RE-starts, do not add a stop transaction, otherwise if busses are changing, must add a STOP.
    if (add_stop) issue_stop_command();
  endfunction

	// ****************************************************************************
	// Convert a RANDOMIZED I2C Transaction into the requisite Wishbone transactions
  // to be executed on the wishbone end of the DUT
	// ****************************************************************************
  virtual function void convert_rand_i2c_trans(i2c_rand_data_transaction t, bit add_bus_sel,
                                               bit add_stop);
    int address = t.address;

    // Support address-mismatched (Slave Disconnected) Transactions
    if (env_cfg.get_address_shift() != 0) begin
      address -= env_cfg.get_address_shift();
      if (address < 0) address = 127 - env_cfg.get_address_shift() + 1;
    end

    // Select the bus, if a change of bus is desired
    if (add_bus_sel) select_I2C_bus(t.selected_bus);

    // Send the start command
    issue_start_command();

    // Send the address request, and subsequent data, if applicable for a READ or a WRITE.
    if (t.rw == I2_WRITE || env_cfg.get_address_shift() != 0) begin
      transmit_address_req_write(address);
      foreach (t.data[i]) begin
        write_data_byte(byte'(t.data[i]));
      end
    end else begin
      transmit_address_req_read(t.address);
      for (int i = 0; i < t.data.size - 1; i++) read_data_byte_with_continue();
      read_data_byte_with_stop();
    end

    // If we are testing RE-starts, do not add a stop transaction but do check the CSR values. 
    //Otherwise, if busses are changing, add a STOP.
    inject_csr_read();        //CSR Reads are used by the predictor to verify CSR values based on predictor state.
    if (add_stop) begin
      issue_stop_command();
      inject_csr_read();      //CSR Reads are used by the predictor to verify CSR values based on predictor state.
    end
  endfunction
  
  //_____________________________________________________________________________________\\
	//                           DATASET CREATION ABSTRACTION                              \\
	//_____________________________________________________________________________________\\

	// ****************************************************************************
	// Create a series of one or more bytes of data, from <start_value> to <end_value>,
	// and assign them  to the i2c transaction at <trans_index>, indicating whether
	// this transaction shall be an I2C_WRITE or I2C_READ based on <operation> enum.
		// ****************************************************************************
	virtual function void create_explicit_data_series(
      input int start_value, input int end_value, input int trans_index, input i2c_op_t operation);
    bit [7:0] init_data[$];
    init_data.delete();

    if (end_value >= start_value) begin
      for (int i = start_value; i <= end_value; i++) begin
        init_data.push_back(byte'(i));
      end
    end else begin
      for (int i = start_value; i >= end_value; i--) begin
        init_data.push_back(byte'(i));
      end
    end
    trans.data = init_data;
    trans.rw   = operation;
    init_data.delete();
  endfunction


	// ****************************************************************************
	// Inject a directed series of NON-RANDOMIZED data into a RANDOM transaction
  // such that specific, directed edge cases may be covered.	
	// ****************************************************************************
  virtual function void rnd_create_explicit_data_series(
      i2c_rand_data_transaction trns, input int start_value, input int end_value,
      input int trans_index, input i2c_op_t operation);
    bit [7:0] init_data[$];
    init_data.delete();

    if (end_value >= start_value) begin
      for (int i = start_value; i <= end_value; i++) begin
        init_data.push_back(byte'(i));
      end
    end else begin
      for (int i = start_value; i >= end_value; i--) begin
        init_data.push_back(byte'(i));
      end
    end
    trns.data = init_data;
    trns.rw   = operation;
    init_data.delete();
  endfunction


  //_____________________________________________________________________________________\\
	//                           WISHBONE TRANSACTION ABSTRACTIONS                         \\
	//_____________________________________________________________________________________\\

	// ****************************************************************************
	// Perform a read on the CMDR which clears an interrupt. Resultant data can also
	// 		Be used to determine system state/NACK rec'd/ARB Lost, etc.		
	// ****************************************************************************
	function void clear_interrupt();
    wb_transaction t = new("clear_interrupt");
    t.write = 1'b0;
    t.line = CMDR;
    t.word = 8'b0;
    t.cmd = NONE;
    t.wait_int_nack = 1'b0;
    t.wait_int_ack = 1'b0;
    t.stall_cycles = 0;
    wb_trans.push_back(t);
  endfunction

  // ****************************************************************************
  // Enable the DUT core. Effectively, a soft reset after a disable command
  // 		NB: Also sets the enable_interrupt bit of the DUT such that we can use
  // 			raised interrupts to determine DUT-ready rather than polling
  //			DUT registers for readiness.
  // ****************************************************************************
  function void enable_dut_with_interrupt();
    //master_write(CSR, ENABLE_CORE_INTERRUPT); // Enable DUT		
    wb_transaction t = new("DUT_Enable");
    t.write = 1'b1;
    t.line = CSR;
    t.cmd = ENABLE_CORE_INTERRUPT;
    t.word = 8'b0;
    t.wait_int_nack = 1'b0;
    t.wait_int_ack = 1'b0;
    t.stall_cycles = 100;
    t.label("ENABLE DUT INTERRUPT");
    wb_trans.push_back(t);
    enable_polling = 1'b0;
  endfunction


  // ****************************************************************************
  // Inject a CSR Read into the testflow. Permits checking for Bus Selection, 
  // Bus Busy/ Bus Captured Bit checking
  // ****************************************************************************
  function void inject_csr_read();
    //master_write(CSR, ENABLE_CORE_INTERRUPT); // Enable DUT		
    wb_transaction t = new("csr_read");
    t.write = 1'b0;
    t.line = CSR;
    t.cmd = ENABLE_CORE_INTERRUPT;
    t.word = 8'b0;
    t.wait_int_nack = 1'b0;
    t.wait_int_ack = 1'b0;
    t.stall_cycles = 0;
    t.label("CSR Read");
    wb_trans.push_back(t);
  endfunction

  // ****************************************************************************
  // Enable the DUT core. Effectively, a soft reset after a disable command
  // 		NB: Also sets the enable_interrupt bit of the DUT such that we can use
  // 			raised interrupts to determine DUT-ready rather than polling
  //			DUT registers for readiness.
  // ****************************************************************************
  function void enable_dut_polling();
    //master_write(CSR, ENABLE_CORE_INTERRUPT); // Enable DUT		
    wb_transaction t = new("DUT_Enable");
    t.write = 1'b1;
    t.line = CSR;
    t.cmd = ENABLE_CORE_POLLING;
    t.word = 8'b0;
    t.wait_int_nack = 1'b0;
    t.wait_int_ack = 1'b0;
    t.stall_cycles = 100;
    t.label("ENABLE DUT POLLING");
    wb_trans.push_back(t);
    enable_polling = 1'b1;
  endfunction

  // ****************************************************************************
  // Select desired I2C bus of DUT to use for transfers.
  // ****************************************************************************
  function void select_I2C_bus(input bit [7:0] selected_bus);
    //master_write(DPR, selected_bus);
    wb_transaction t = new("select_i2c_bus");
    t.write = 1'b1;
    t.line = DPR;
    t.word = selected_bus;
    t.cmd = NONE;
    t.wait_int_nack = 1'b0;
    t.wait_int_ack = 1'b0;
    t.stall_cycles = 0;
    t.label("SELECT BUS");
    wb_trans.push_back(t);

    //master_write(CMDR, SET_I2C_BUS);
    t = new("trigger_selection_i2c_bus");
    t.write = 1'b1;
    t.line = CMDR;
    t.word = 8'b0;
    t.cmd = SET_I2C_BUS;
    if (!enable_polling) begin
      t.wait_int_nack = 1'b0;
      t.wait_int_ack  = 1'b1;
      t.stall_cycles  = 0;
    end else begin
      t.wait_int_nack = 1'b0;
      t.wait_int_ack  = 1'b0;
      t.stall_cycles  = sel_pause;
    end
    wb_trans.push_back(t);

    //wait_interrupt();
    clear_interrupt();
  endfunction


  // ****************************************************************************
  // Disable the DUT and STALL for 2 system cycles
  // ****************************************************************************
  function void disable_dut();
    //master_write(CSR, DISABLE_CORE); // Enable DUT
    wb_transaction t = new("disable_dut");
    t.write = 1'b1;
    t.line = CSR;
    t.word = 8'b0;
    t.cmd = DISABLE_CORE;
    t.wait_int_nack = 1'b0;
    t.wait_int_ack = 1'b0;
    t.stall_cycles = 20;
    t.label("DISABLE DUT (SOFT RESET)");
    wb_trans.push_back(t);
  endfunction



  // ****************************************************************************
  // Send a start command to I2C nets via DUT
  // ****************************************************************************
  function void issue_start_command();
    //master_write(CMDR, I2C_START);
    wb_transaction t = new("send_start_command");
    t.write = 1'b1;
    t.line  = CMDR;
    t.word  = 8'b0;
    t.cmd   = I2C_START;
    if (!enable_polling) begin
      t.wait_int_nack = 1'b0;
      t.wait_int_ack  = 1'b1;
      t.stall_cycles  = 0;
    end else begin
      t.wait_int_nack = 1'b0;
      t.wait_int_ack  = 1'b0;
      t.stall_cycles  = start_pause;
    end
    t.label("SEND START");
    wb_trans.push_back(t);

    //wait_interrupt();
    clear_interrupt();
  endfunction

  // ****************************************************************************
  // Send a stop command to I2C Nets via DUT
  // ****************************************************************************
  function void issue_stop_command();
    //master_write(CMDR, I2C_STOP); // Stop the transaction/Close connection
    wb_transaction t = new("send_stop_command");
    t.write = 1'b1;
    t.line  = CMDR;
    t.word  = 8'b0;
    t.cmd   = I2C_STOP;
    if (!enable_polling) begin
      t.wait_int_nack = 1'b0;
      t.wait_int_ack  = 1'b1;
      t.stall_cycles  = 0;
    end else begin
      t.wait_int_nack = 1'b0;
      t.wait_int_ack  = 1'b0;
      t.stall_cycles  = stop_pause;
    end
    t.label("SEND STOP");
    wb_trans.push_back(t);

    //wait_interrupt();
    clear_interrupt();
  endfunction

  // ****************************************************************************
  // Issue an explicit WAIT command to the DUT, in milliseconds.
  // ****************************************************************************
  function void issue_wait(int ms);
    //master_write(DPR, addr);
    wb_transaction t = new("emplace_wait_time");
    t.write = 1'b1;
    t.line = DPR;
    t.word = byte'(ms);
    t.cmd = NONE;
    t.wait_int_nack = 1'b0;
    t.wait_int_ack = 1'b0;
    t.stall_cycles = 0;
    t.label("WAIT TIIME");
    wb_trans.push_back(t);


    //master_write(CMDR, I2C_WRITE);
    t = new("trigger_wait_transaction");
    t.write = 1'b1;
    t.line = CMDR;
    t.word = 8'b0;
    t.cmd = WB_WAIT;
    t.wait_int_nack = 1'b1;
    t.wait_int_ack = 1'b0;
    t.stall_cycles = 0;
    wb_trans.push_back(t);

    //wait_interrupt_with_NACK(); // In case of a down/unresponsive slave, we'd get a nack	
    clear_interrupt();
  endfunction

  // ****************************************************************************
  // Format incoming address byte and set R/W bit to request a WRITE.
  // Transmit this formatted address byte on the I2C bus
  // ****************************************************************************
  function void transmit_address_req_write(input bit [7:0] addr);
    //master_write(DPR, addr);
    wb_transaction t = new("emplace_address_req_write");
    addr = addr << 1;
    addr[0] = 1'b0;
    t.write = 1'b1;
    t.line = DPR;
    t.word = addr;
    t.cmd = NONE;
    t.wait_int_nack = 1'b0;
    t.wait_int_ack = 1'b0;
    t.stall_cycles = 0;
    t.label("SEND ADDRESS REQ WRITE");
    wb_trans.push_back(t);


    //master_write(CMDR, I2C_WRITE);
    t = new("trigger_address_transmission");
    t.write = 1'b1;
    t.line = CMDR;
    t.word = 8'b0;
    t.cmd = I2C_WRITE;
    if (!enable_polling) begin
      t.wait_int_nack = 1'b1;
      t.wait_int_ack  = 1'b0;
      t.stall_cycles  = 0;
    end else begin
      t.wait_int_nack = 1'b0;
      t.wait_int_ack  = 1'b0;
      t.stall_cycles  = data_pause;
    end
    wb_trans.push_back(t);

    //wait_interrupt_with_NACK(); // In case of a down/unresponsive slave, we'd get a nack	
    clear_interrupt();
  endfunction

  // ****************************************************************************
  // Format incoming address byte and set R/W bit to request a READ.
  // Transmit this formatted address byte on the I2C bus
  // ****************************************************************************
  function void transmit_address_req_read(input bit [7:0] addr);
    //master_write(DPR, data);
    wb_transaction t = new("emplace_address_req_read");
    addr = addr << 1;
    addr[0] = 1'b1;
    t.write = 1'b1;
    t.line = DPR;
    t.word = addr;
    t.cmd = NONE;
    t.wait_int_nack = 1'b0;
    t.wait_int_ack = 1'b0;
    t.stall_cycles = 0;
    t.label("SEND ADDRESS REQ READ");
    wb_trans.push_back(t);

    //master_write(CMDR, I2C_WRITE);
    t = new("trigger_address_transmission");
    t.write = 1'b1;
    t.line = CMDR;
    t.word = 8'b0;
    t.cmd = I2C_WRITE;
    if (!enable_polling) begin
      t.wait_int_nack = 1'b1;
      t.wait_int_ack  = 1'b0;
      t.stall_cycles  = 0;
    end else begin
      t.wait_int_nack = 1'b0;
      t.wait_int_ack  = 1'b0;
      t.stall_cycles  = data_pause;
    end
    wb_trans.push_back(t);

    //wait_interrupt_with_NACK(); // In case of a down/unresponsive slave, we'd get a nack
    clear_interrupt();
  endfunction

  // ****************************************************************************
  // Write a single byte of data to a previously-addressed I2C Slave
  // Check to ensure we didn't get a NACK/ Got the ACK from the slave.
  // ****************************************************************************
  function void write_data_byte(input bit [7:0] data);
    //master_write(DPR, data);
    wb_transaction t = new("emplace_data_for_write");
    t.write = 1'b1;
    t.line = DPR;
    t.word = data;
    t.cmd = NONE;
    t.wait_int_nack = 1'b0;
    t.wait_int_ack = 1'b0;
    t.stall_cycles = 0;
    t.label("WRITE BYTE");
    wb_trans.push_back(t);


    //master_write(CMDR, I2C_WRITE);
    t = new("trigger_byte_write_trans");
    t.write = 1'b1;
    t.line = CMDR;
    t.word = 8'b0;
    t.cmd = I2C_WRITE;
    if (!enable_polling) begin
      t.wait_int_nack = 1'b1;
      t.wait_int_ack  = 1'b0;
      t.stall_cycles  = 0;
    end else begin
      t.wait_int_nack = 1'b0;
      t.wait_int_ack  = 1'b0;
      t.stall_cycles  = data_pause;
    end
    wb_trans.push_back(t);

    //wait_interrupt_with_NACK();
    clear_interrupt();
  endfunction

  // ****************************************************************************
  // Write a single byte of data to a previously-addressed I2C Slave
  // Check to ensure we didn't get a NACK/ Got the ACK from the slave.
  // ****************************************************************************
  function void write_data_byte_with_stall(input bit [7:0] data, int stll);
    //master_write(DPR, data);
    wb_transaction t = new("emplace_data_for_write");
    t.write = 1'b1;
    t.line = DPR;
    t.word = data;
    t.cmd = NONE;
    t.wait_int_nack = 1'b0;
    t.wait_int_ack = 1'b0;
    t.stall_cycles = stll;
    t.label("WRITE BYTE");
    wb_trans.push_back(t);


    //master_write(CMDR, I2C_WRITE);
    t = new("trigger_byte_write_trans");
    t.write = 1'b1;
    t.line = CMDR;
    t.word = 8'b0;
    t.cmd = I2C_WRITE;
    if (!enable_polling) begin
      t.wait_int_nack = 1'b1;
      t.wait_int_ack  = 1'b0;
      t.stall_cycles  = 0;
    end else begin
      t.wait_int_nack = 1'b0;
      t.wait_int_ack  = 1'b0;
      t.stall_cycles  = data_pause;
    end
    wb_trans.push_back(t);

    //wait_interrupt_with_NACK();
    clear_interrupt();
  endfunction


  // ****************************************************************************
  // READ a single byte of data from a previously-addressed I2C Slave,
  //      Indicating that we are REQUESTING ANOTHER byte after this byte.
  // Check to ensure we didn't get a NACK/ Got the ACK from the slave.
  // ****************************************************************************
  function void read_data_byte_with_continue();
    //master_write(CMDR, READ_WITH_ACK);
    wb_transaction t = new("trigger_continuing_byte_read");
    t.write = 1'b1;
    t.line  = CMDR;
    t.word  = 8'b0;
    t.cmd   = READ_WITH_ACK;
    if (!enable_polling) begin
      t.wait_int_nack = 1'b1;
      t.wait_int_ack  = 1'b0;
      t.stall_cycles  = 0;
    end else begin
      t.wait_int_nack = 1'b0;
      t.wait_int_ack  = 1'b0;
      t.stall_cycles  = data_pause;
    end
    t.label("READ BYTE");
    wb_trans.push_back(t);

    //wait_interrupt_with_NACK();
    clear_interrupt();

    //master_read(DPR, iobuf);
    t = new("retrieve_data_post_read");
    t.write = 1'b0;
    t.line = DPR;
    t.word = 8'b0;
    t.cmd = NONE;
    t.wait_int_nack = 1'b0;
    t.wait_int_ack = 1'b0;
    t.stall_cycles = 0;
    wb_trans.push_back(t);
  endfunction

  // ****************************************************************************
  // READ a single byte of data from a previously-addressed I2C Slave,
  //      Indicating that this is the LAST BYTE of this transfer, and the next
  // 		bus action will be a STOP signal.
  // Check to ensure we didn't get a NACK/ Got the ACK from the slave.
  // ****************************************************************************
  function void read_data_byte_with_stop();
    //master_write(CMDR, READ_WITH_NACK);
    wb_transaction t = new("trigger_final_byte_read");
    t.write = 1'b1;
    t.line  = CMDR;
    t.word  = 8'b0;
    t.cmd   = READ_WITH_NACK;
    if (!enable_polling) begin
      t.wait_int_nack = 1'b1;
      t.wait_int_ack  = 1'b0;
      t.stall_cycles  = 0;
    end else begin
      t.wait_int_nack = 1'b0;
      t.wait_int_ack  = 1'b0;
      t.stall_cycles  = data_pause;
    end
    t.label("READ BYTE");
    wb_trans.push_back(t);

    //wait_interrupt_with_NACK();
    clear_interrupt();

    //	master_read(DPR, iobuf);
    t = new("retrieve_data_post_read");
    t.write = 1'b0;
    t.line = DPR;
    t.word = 8'b0;
    t.cmd = NONE;
    t.wait_int_nack = 1'b0;
    t.wait_int_ack = 1'b0;
    t.stall_cycles = 0;
    wb_trans.push_back(t);
  endfunction

endclass
