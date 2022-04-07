class i2cmb_generator extends ncsu_component#(.T(i2c_transaction));

	i2c_transaction i2c_trans[130];
	wb_transaction wb_trans[$];
	wb_agent wb_agent_handle;
	i2c_agent i2c_agent_handle;
	string trans_name;

	// ****************************************************************************
	// Constructor, setters and getters
	// ****************************************************************************
	function new(string name = "", ncsu_component_base  parent = null);
		super.new(name,parent);
		if ( !$value$plusargs("GEN_TRANS_TYPE=%s", trans_name)) begin
			$display("FATAL: +GEN_TRANS_TYPE plusarg not found on command line");
			$fatal;
		end
		if(trans_name != "i2c_transaction") $fatal;
		$display("%m found +GEN_TRANS_TYPE=%s", trans_name);
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
		generate_directed_project_2_test_transactions();
		wb_agent_handle.expect_nacks(1'b0);
		// Iterate through all generated transactions, passing each down to respective agents.
		fork
			foreach(i2c_trans[i]) i2c_agent_handle.bl_put(i2c_trans[i]);
			foreach(wb_trans[i]) begin
				wb_agent_handle.bl_put(wb_trans[i]);
				if(wb_trans[i].en_printing) ncsu_info("",{get_full_name(),wb_trans[i].to_s_prettyprint},NCSU_MEDIUM);	// Print only pertinent WB transactions per project spec.
			end
		join
	endtask
	
 	// ****************************************************************************
	// Create all required transactions for the project 2 directed tests, 
	//  Including 	WRITE 0 -> 31
	//				READ 100 -> 131
	// 				WRITE/READ Alternating 64->127 interleave 63 -> 0 
	// ****************************************************************************
	function void generate_directed_project_2_test_transactions();
		int i,j,k;
		// Transaction to enable the DUT with interrupts enabled
		enable_dut_with_interrupt();

		j=64;
		k=63;
		foreach (i2c_trans[i]) begin
			$cast(i2c_trans[i],ncsu_object_factory::create(trans_name));

			// pick  a bus, sequentially picking a new bus for each major transaction
			i2c_trans[i].selected_bus=i % 15;
			select_I2C_bus(i2c_trans[i].selected_bus);

			// Send a start command
			issue_start_command();

			// pick an address
			i2c_trans[i].address = (i % 18)+1;

			// WRITE ALL (Write 0 to 31 to remote Slave)
			if(i==0) begin
				transmit_address_req_write(i2c_trans[i].address);
				for(j=0;j<=31;j++) write_data_byte(byte'(j));
				create_explicit_data_series(0, 31, i, I2_WRITE);
				issue_stop_command();
			end

			// READ ALL (Read 100 to 131 from remote slave)
			if(i==1) begin
				transmit_address_req_read(i2c_trans[i].address);
				for(j=100;j<=130;j++) read_data_byte_with_continue();
				read_data_byte_with_stop();
				create_explicit_data_series(100, 131, i, I2_READ);
				issue_stop_command();
				j=64;
			end

			// Alternation EVEN (Handle the Write step in Write/Read Alternating TF)
			if(i>1 && i % 2 == 0) begin // do a write
				transmit_address_req_write(i2c_trans[i].address);
				write_data_byte(byte'(j));
				create_explicit_data_series(j, j, i, I2_WRITE);
				++j;
				issue_stop_command();
			end
			// Alternation ODD(Handle the Read step in Write/Read Alternating TF)
			else if (i>1 && i % 2 == 1) begin // do a write
				transmit_address_req_read(i2c_trans[i].address);
				read_data_byte_with_stop();
				create_explicit_data_series(k, k, i, I2_READ);
				--k;
				issue_stop_command();
			end
		end
	endfunction


	//_____________________________________________________________________________________\\
	//                           DATASET CREATION ABSTRACTION                              \\
	//_____________________________________________________________________________________\\

 	// ****************************************************************************
	// Create a series of one or more bytes of data, from <start_value> to <end_value>,
	// and assign them  to the i2c transaction at <trans_index>, indicating whether
	// this transaction shall be an I2C_WRITE or I2C_READ based on <operation> enum.
	//
	// 		NB: Data values for "writes" are ultimately swallowed by the testbench,
	//			as they are not necessary on the I2C-Slave end of the bench.
	//			They are here initialized for a consistent interface between
	//			writes and reads, and used later in the generator to create 
	//			the requisite wb_transactions.
	// ****************************************************************************
	function void create_explicit_data_series(input int start_value, input int end_value, input int trans_index, input i2c_op_t operation);
		bit [7:0] init_data[$];
		init_data.delete();

		if(end_value >= start_value) begin
			for(int i=start_value;i<=end_value;i++) begin
				init_data.push_back(byte'(i));
			end
		end
		else begin
			for(int i=start_value;i>=end_value;i--) begin
				init_data.push_back(byte'(i));
			end
		end
		i2c_trans[trans_index].data=init_data;
		i2c_trans[trans_index].rw = operation;
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
		t.word=8'b0;
		t.cmd=NONE;
		t.wait_int_nack=1'b0;
		t.wait_int_ack=1'b0;
		t.stall_cycles=0;
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
		t.word=8'b0;
		t.wait_int_nack=1'b0;
		t.wait_int_ack=1'b0;
		t.stall_cycles=0;
		t.label("ENABLE DUT WITH INTERRUPT");
		wb_trans.push_back(t);
	endfunction

	// ****************************************************************************
	// Select desired I2C bus of DUT to use for transfers.
	// ****************************************************************************
	function void select_I2C_bus(input bit [7:0] selected_bus);
		//master_write(DPR, selected_bus);
		wb_transaction t = new("select_i2c_bus");
		t.write = 1'b1;
		t.line = DPR;
		t.word=selected_bus;
		t.cmd=NONE;
		t.wait_int_nack=1'b0;
		t.wait_int_ack=1'b0;
		t.stall_cycles=0;
		t.label("SELECT BUS");
		wb_trans.push_back(t);

		//master_write(CMDR, SET_I2C_BUS);
		t = new("trigger_selection_i2c_bus");
		t.write = 1'b1;
		t.line = CMDR;
		t.word=8'b0;
		t.cmd=SET_I2C_BUS;
		t.wait_int_nack=1'b0;
		t.wait_int_ack=1'b1;
		t.stall_cycles=0;
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
		t.word=8'b0;
		t.cmd=DISABLE_CORE;
		t.wait_int_nack=1'b0;
		t.wait_int_ack=1'b0;
		t.stall_cycles=2;
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
		t.line = CMDR;
		t.word=8'b0;
		t.cmd=I2C_START;
		t.wait_int_nack=1'b0;
		t.wait_int_ack=1'b1;
		t.stall_cycles=0;
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
		t.line = CMDR;
		t.word=8'b0;
		t.cmd=I2C_STOP;
		t.wait_int_nack=1'b0;
		t.wait_int_ack=1'b1;
		t.stall_cycles=0;
		t.label("SEND STOP");
		wb_trans.push_back(t);

		//wait_interrupt();
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
		addr[0]=1'b0;
		t.write = 1'b1;
		t.line = DPR;
		t.word=addr;
		t.cmd=NONE;
		t.wait_int_nack=1'b0;
		t.wait_int_ack=1'b0;
		t.stall_cycles=0;
		t.label("SEND ADDRESS REQ WRITE");
		wb_trans.push_back(t);


		//master_write(CMDR, I2C_WRITE);
		t = new("trigger_address_transmission");
		t.write = 1'b1;
		t.line = CMDR;
		t.word=8'b0;
		t.cmd=I2C_WRITE;
		t.wait_int_nack=1'b1;
		t.wait_int_ack=1'b0;
		t.stall_cycles=0;
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
		addr[0]=1'b1;
		t.write = 1'b1;
		t.line = DPR;
		t.word=addr;
		t.cmd=NONE;
		t.wait_int_nack=1'b0;
		t.wait_int_ack=1'b0;
		t.stall_cycles=0;
		t.label("SEND ADDRESS REQ READ");
		wb_trans.push_back(t);

		//master_write(CMDR, I2C_WRITE);
		t = new("trigger_address_transmission");
		t.write = 1'b1;
		t.line = CMDR;
		t.word=8'b0;
		t.cmd=I2C_WRITE;
		t.wait_int_nack=1'b1;
		t.wait_int_ack=1'b0;
		t.stall_cycles=0;
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
		t.word=data;
		t.cmd=NONE;
		t.wait_int_nack=1'b0;
		t.wait_int_ack=1'b0;
		t.stall_cycles=0;
		t.label("WRITE BYTE");
		wb_trans.push_back(t);


		//master_write(CMDR, I2C_WRITE);
		t = new("trigger_byte_write_trans");
		t.write = 1'b1;
		t.line = CMDR;
		t.word=8'b0;
		t.cmd=I2C_WRITE;
		t.wait_int_nack=1'b1;
		t.wait_int_ack=1'b0;
		t.stall_cycles=0;
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
		t.line = CMDR;
		t.word=8'b0;
		t.cmd=READ_WITH_ACK;
		t.wait_int_nack=1'b1;
		t.wait_int_ack=1'b0;
		t.stall_cycles=0;
		t.label("READ BYTE");
		wb_trans.push_back(t);

		//wait_interrupt_with_NACK();
		clear_interrupt();

		//master_read(DPR, iobuf);
		t = new("retrieve_data_post_read");
		t.write = 1'b0;
		t.line = DPR;
		t.word=8'b0;
		t.cmd=NONE;
		t.wait_int_nack=1'b0;
		t.wait_int_ack=1'b0;
		t.stall_cycles=0;
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
		t.line = CMDR;
		t.word=8'b0;
		t.cmd=READ_WITH_NACK;
		t.wait_int_nack=1'b1;
		t.wait_int_ack=1'b0;
		t.stall_cycles=0;
		t.label("READ BYTE");
		wb_trans.push_back(t);

		//wait_interrupt_with_NACK();
		clear_interrupt();

		//	master_read(DPR, iobuf);
		t = new("retrieve_data_post_read");
		t.write = 1'b0;
		t.line = DPR;
		t.word=8'b0;
		t.cmd=NONE;
		t.wait_int_nack=1'b0;
		t.wait_int_ack=1'b0;
		t.stall_cycles=0;
		wb_trans.push_back(t);
	endfunction

endclass