class i2cmb_generator_test_resets extends i2cmb_generator;
`ncsu_register_object(i2cmb_generator_test_resets);

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
		if(trans_name == "i2cmb_generator_test_resets") begin
			trans_name = "i2c_transaction";
		end
		else $fatal;
		verbosity_level = global_verbosity_level;
	endfunction


	// Start progress:
	//94.62, 83.87, 87.59

	// ****************************************************************************
	// Base Multi-bus test flow: Test randomized transactions in a 16-bus DUT
	// ****************************************************************************
	virtual task run();
		enable_dut_with_interrupt();

		issue_start_command_w_hard_reset(8);	//start a
		
		generate_directed_targets();

		enable_dut_with_interrupt();
		issue_start_command_w_hard_reset(117);	//start b
		
		generate_directed_targets();

		generate_directed_targets();
		reset_write_flow_with_hard_reset(7'b1111_1111, 58);
		
		generate_directed_targets();
		reset_write_flow_with_hard_reset(7'b000_0000, 90);

		generate_directed_targets();
		reset_write_flow_with_hard_reset(7'b111_1111, 194);
		
		generate_directed_targets();
		reset_write_flow_with_hard_reset(7'b111_1111, 260);
		
		generate_directed_targets();

		reset_write_flow_with_hard_reset_intr(7'b111_1111, 200);		// rw E
		generate_directed_targets();

		disable_dut();
		generate_directed_targets_restart();
		issue_start_command_w_hard_reset(300);	//start b
		disable_dut();
		enable_dut_with_interrupt();
		generate_directed_targets();
		generate_directed_targets_restart();
		issue_start_command_w_hard_reset(400);	//start b
		generate_directed_targets();
		generate_directed_targets_restart();
		issue_stop_command_w_wait(117);

		generate_directed_targets();
		generate_directed_targets_restart();
		issue_stop_command_w_wait(58);
		
		generate_directed_targets();
		generate_directed_targets_restart();
		issue_stop_command_w_wait(90);
		
		generate_directed_targets();
		generate_directed_targets_restart();
	
		wb_agent_handle.expect_nacks(1'b0);
		//foreach(i2c_trans[i]) $display(i2c_trans[i].convert2string());
		super.run();
	endtask

	//_____________________________________________________________________________________\\
	//                                TEST FLOW GENERATION                                 \\
	//_____________________________________________________________________________________\\


  // ****************************************************************************
  // Send a stop command to I2C Nets via DUT
  // ****************************************************************************
  function void issue_stop_command_w_wait(int wait_cyc);
    //master_write(CMDR, I2C_STOP); // Stop the transaction/Close connection
    wb_transaction t = new("send_stop_command");
    t.write = 1'b1;
    t.line  = CMDR;
    t.word  = 8'b0;
    t.cmd   = I2C_STOP;
      t.wait_int_nack = 1'b0;
      t.wait_int_ack  = 1'b0;
      t.stall_cycles  = wait_cyc;

    t.label("SEND STOP");
    wb_trans.push_back(t);

	issue_hard_reset();
    //wait_interrupt();
   // clear_interrupt();
  endfunction
  // ****************************************************************************
  // Send a start command to I2C nets via DUT
  // ****************************************************************************
  function void issue_start_command_w_hard_reset(int wait_cyc);
	wb_transaction t ;
	i2c_transaction u;
	
	$cast(u, ncsu_object_factory::create("i2c_transaction"));
	u.is_hard_reset = 1'b1;
	u.address = 13;
	u.rw = I2_WRITE;
	u.selected_bus = 0;
	
	t = new("send_start_command");
    t.write = 1'b1;
    t.line  = CMDR;
    t.word  = 8'b0;
    t.cmd   = I2C_START;
      t.wait_int_nack = 1'b0;
      t.wait_int_ack  = 1'b0;
      t.stall_cycles  = wait_cyc;

    t.label("SEND START");
    wb_trans.push_back(t);
	i2c_trans.push_back(u);

  issue_hard_reset();
  endfunction


	function reset_write_flow_with_hard_reset(bit [6:0] adr, int cyc_wait);
	i2c_transaction t;
	int address;
	$cast(t, ncsu_object_factory::create("i2c_transaction"));
	t.is_hard_reset = 1'b1;
	t.address = adr;
	t.rw = I2_WRITE;
	t.selected_bus = 0;
	address = t.address;

     // Send the start command
    issue_start_command();

    // Send the address request, and subsequent data, if applicable for a READ or a WRITE.
    if (t.rw == I2_WRITE) begin
      rst_transmit_address_req_write(address, cyc_wait);
    end else begin
     rst_transmit_address_req_write(address, cyc_wait);
    end
	issue_hard_reset();
	i2c_trans.push_back(t);
	endfunction

function void issue_hard_reset();
    wb_transaction t = new("hard_reset");
	t.is_hard_reset = 1'b1;
    
    wb_trans.push_back(t);
endfunction

function reset_write_flow_with_hard_reset_intr(bit [6:0] adr, int cyc_wait);
	i2c_transaction t;
	int address;
	$cast(t, ncsu_object_factory::create("i2c_transaction"));
	t.is_hard_reset = 1'b1;
	t.address = adr;
	t.rw = I2_WRITE;
	t.selected_bus = 0;
	
	
	
	address = t.address;

     // Send the start command
    issue_start_command();

    // Send the address request, and subsequent data, if applicable for a READ or a WRITE.
    if (t.rw == I2_WRITE) begin
      transmit_address_req_write(address);
	  
      /*foreach (t.data[i]) begin
        write_data_byte(byte'(t.data[i]));
      end*/
    end else begin
     transmit_address_req_write(address);
     // for (int i = 0; i < t.data.size - 1; i++) read_data_byte_with_continue();
      //read_data_byte_with_stop();
    end
	issue_hard_reset();
    // If we are testing RE-starts, do not add a stop transaction, otherwise if busses are changing, must add a STOP.
   // if (add_stop) issue_stop_command();
	i2c_trans.push_back(t);
	endfunction




  // ****************************************************************************
  // Format incoming address byte and set R/W bit to request a WRITE.
  // Transmit this formatted address byte on the I2C bus
  // ****************************************************************************
  function void rst_transmit_address_req_write(input bit [7:0] addr, int pause);
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
      t.wait_int_nack = 1'b0;
      t.wait_int_ack  = 1'b0;
      t.stall_cycles  = pause;

    wb_trans.push_back(t);

    //wait_interrupt_with_NACK(); // In case of a down/unresponsive slave, we'd get a nack	
   // clear_interrupt();
  endfunction


	// Target several specific scenarios needing coverage in the multi-bus base configuration
	function void generate_directed_targets();
		i2c_rand_data_transaction rand_trans;

		$cast(rand_trans,ncsu_object_factory::create("i2c_rand_data_transaction"));
		enable_dut_with_interrupt();
		rand_trans.randomize();
		rand_trans.selected_bus = 0;
		rand_trans.address = 3;
		rand_trans.rw = I2_READ;
		i2c_trans.push_back(rand_trans);
		convert_rand_i2c_trans(rand_trans, 0, 0);

		$cast(rand_trans,ncsu_object_factory::create("i2c_rand_data_transaction"));

		rand_trans.randomize();
		rand_trans.selected_bus = 0;
		rand_trans.address = 65;
		rand_trans.rw = I2_READ;
		i2c_trans.push_back(rand_trans);
		convert_rand_i2c_trans(rand_trans, 0, 0);

		$cast(rand_trans,ncsu_object_factory::create("i2c_rand_data_transaction"));

		rand_trans.randomize();
		rand_trans.selected_bus = 0;
		rand_trans.address = 9;
		rand_trans.rw = I2_READ;
		i2c_trans.push_back(rand_trans);
		convert_rand_i2c_trans(rand_trans, 0, 1);
	endfunction

		// Target several specific scenarios needing coverage in the multi-bus base configuration
	function void generate_directed_targets_restart();
		i2c_rand_data_transaction rand_trans;

		$cast(rand_trans,ncsu_object_factory::create("i2c_rand_data_transaction"));
		enable_dut_with_interrupt();
		rand_trans.randomize();
		rand_trans.selected_bus = 0;
		rand_trans.address = 3;
		rand_trans.rw = I2_READ;
		i2c_trans.push_back(rand_trans);
		convert_rand_i2c_trans(rand_trans, 0, 0);

		$cast(rand_trans,ncsu_object_factory::create("i2c_rand_data_transaction"));

		rand_trans.randomize();
		rand_trans.selected_bus = 0;
		rand_trans.address = 65;
		rand_trans.rw = I2_READ;
		i2c_trans.push_back(rand_trans);
		convert_rand_i2c_trans(rand_trans, 0, 0);

		$cast(rand_trans,ncsu_object_factory::create("i2c_rand_data_transaction"));

		rand_trans.randomize();
		rand_trans.selected_bus = 0;
		rand_trans.address = 9;
		rand_trans.rw = I2_READ;
		i2c_trans.push_back(rand_trans);
		convert_rand_i2c_trans(rand_trans, 0, 0);
	endfunction
endclass