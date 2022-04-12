class i2cmb_generator extends ncsu_component#(.T(i2c_transaction));

	i2c_transaction i2c_trans[$];
	i2c_rand_data_transaction i2c_rand_trans[$];
	i2c_transaction trans;
	wb_transaction wb_trans[$];
	wb_agent wb_agent_handle;
	i2c_agent i2c_agent_handle;
	string trans_name;

	// ****************************************************************************
	// Constructor, setters and getters
	// ****************************************************************************
	function new(string name = "", ncsu_component_base  parent = null);
		super.new(name,parent);
		verbosity_level = global_verbosity_level;
	endfunction

	virtual function void set_wb_agent(wb_agent agent);
		this.wb_agent_handle = agent;
	endfunction

	virtual function void set_i2c_agent(i2c_agent agent);
		this.i2c_agent_handle = agent;
	endfunction

 	// ****************************************************************************
	// run the transaction generator; Create all transactions, then, pass trans-
	//		actions to agents, in order, in parallel. 
	// ****************************************************************************
	virtual task run();

	endtask

virtual function void convert_i2c_trans(i2c_transaction t, bit add_bus_sel, bit add_stop);
	if(add_bus_sel) select_I2C_bus(t.selected_bus);
	issue_start_command();
	if(t.rw == I2_WRITE) begin
		transmit_address_req_write(t.address);
		foreach(t.data[i]) write_data_byte(byte'(t.data[i]));
	end 
	else begin
		transmit_address_req_read(t.address);
		for(int i=0;i<t.data.size-1;i++) read_data_byte_with_continue();
		read_data_byte_with_stop();
	end
	if(add_stop) issue_stop_command();
endfunction

virtual function void convert_rand_i2c_trans(i2c_rand_data_transaction t, bit add_bus_sel, bit add_stop);
	if(add_bus_sel) select_I2C_bus(t.selected_bus);
	issue_start_command();
	if(t.rw == I2_WRITE) begin
		transmit_address_req_write(t.address);
		foreach(t.data[i]) begin 
			write_data_byte(byte'(t.data[i]));
		end
	end 
	else begin
		transmit_address_req_read(t.address);
		for(int i=0;i<t.data.size-1;i++) read_data_byte_with_continue();
		read_data_byte_with_stop();
	end
	if(add_stop) issue_stop_command();
endfunction

virtual function void generate_random_base_flow(int qty, bit change_busses);
		int i,j,k,use_bus;
		i2c_rand_data_transaction rand_trans;
		use_bus = 0;
		// Transaction to enable the DUT with interrupts enabled
		enable_dut_with_interrupt();

		for(int i = 0; i<qty;++i) begin// (i2c_trans[i]) begin
			$cast(rand_trans,ncsu_object_factory::create("i2c_rand_data_transaction"));

			// pick  a bus, sequentially picking a new bus for each major transaction
			//rand_trans.selected_bus=use_bus;
			
			//select_I2C_bus(trans.selected_bus);

			
			
			rand_trans.randomize();
			
				i2c_rand_trans.push_back(rand_trans);

				if(change_busses) 	convert_rand_i2c_trans(rand_trans, 1, 1);
				else begin
				//	rand_trans.selected_bus = use_bus;
					convert_rand_i2c_trans(rand_trans, 1, 1); // Effectively, a restart
				end
		end
	endfunction


function void no_data_trans();
	$cast(trans,ncsu_object_factory::create("i2c_transaction"));

			// pick  a bus, sequentially picking a new bus for each major transaction
			trans.selected_bus=0;
			select_I2C_bus(trans.selected_bus);
		

			// pick  a bus, sequentially picking a new bus for each major transaction
			trans.selected_bus=0;
			trans.address = (36)+1;
			issue_start_command();
				transmit_address_req_write(trans.address);
			issue_stop_command();
			i2c_trans.push_back(trans);
endfunction

function void start_restart_trans();
int j;
		enable_dut_with_interrupt();
		issue_wait(6);
		$cast(trans,ncsu_object_factory::create("i2c_transaction"));

			// pick  a bus, sequentially picking a new bus for each major transaction
			trans.selected_bus=0;
			select_I2C_bus(trans.selected_bus);
			

			// pick  a bus, sequentially picking a new bus for each major transaction
			trans.selected_bus=0;
			trans.address = (36)+1;


			issue_start_command();
				transmit_address_req_write(trans.address);
				for(j=0;j<=31;j++) write_data_byte(byte'(j));
				write_data_byte_with_stall(byte'(j), 10);
				j=64;
			i2c_trans.push_back(trans);
			$cast(trans,ncsu_object_factory::create("i2c_transaction"));
						// Send a start command
			issue_start_command();

			// pick an address
			trans.address = (36)+1;

			// WRITE ALL (Write 0 to 31 to remote Slave)
				transmit_address_req_read(trans.address);
				for(j=100;j<=130;j++) read_data_byte_with_continue();
				read_data_byte_with_stop();
				create_explicit_data_series(100, 131, j, I2_READ);

				// Send a start command
		i2c_trans.push_back(trans);

		$cast(trans,ncsu_object_factory::create("i2c_transaction"));
						// Send a start command
			issue_start_command();

			// pick an address
			trans.address = (36)+1;

			transmit_address_req_write(trans.address);
				for(j=0;j<=31;j++) write_data_byte(byte'(j));
				write_data_byte_with_stall(byte'(j), 101);
			i2c_trans.push_back(trans);

		disable_dut();
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
	virtual function void create_explicit_data_series(input int start_value, input int end_value, input int trans_index, input i2c_op_t operation);
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
		trans.data=init_data;
		trans.rw = operation;
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
		t.stall_cycles=1000;
		t.label("ENABLE DUT WITH INTERRUPT");
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
		t.word=8'b0;
		t.wait_int_nack=1'b0;
		t.wait_int_ack=1'b0;
		t.stall_cycles=1000;
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

	function void arb_loss_select_bus(input bit [7:0] selected_bus);
		//master_write(DPR, selected_bus);
		wb_transaction t = new("select_i2c_bus");
		wb_transaction_arb_loss u;
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
		u = new("trigger_selection_i2c_bus-ARB_ARB");
		u.write = 1'b1;
		u.line = CMDR;
		u.word=8'b0;
		u.cmd=SET_I2C_BUS;
		u.wait_int_nack=1'b0;
		u.wait_int_ack=1'b0;
		u.stall_cycles=0;
		wb_trans.push_back(u);

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
		t.stall_cycles=120;
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

		function void arb_loss_start();
		//master_write(CMDR, I2C_START);
		wb_transaction_arb_loss t = new("send_start_command");
		t.write = 1'b1;
		t.line = CMDR;
		t.word=8'b0;
		t.cmd=I2C_START;
		t.wait_int_nack=1'b0;
		t.wait_int_ack=1'b0;
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
	function void issue_wait(int ms);
		//master_write(DPR, addr);
		wb_transaction t = new("emplace_wait_time");
		t.write = 1'b1;
		t.line = DPR;
		t.word=byte'(ms);
		t.cmd=NONE;
		t.wait_int_nack=1'b0;
		t.wait_int_ack=1'b0;
		t.stall_cycles=0;
		t.label("WAIT TIIME");
		wb_trans.push_back(t);


		//master_write(CMDR, I2C_WRITE);
		t = new("trigger_wait_transaction");
		t.write = 1'b1;
		t.line = CMDR;
		t.word=8'b0;
		t.cmd=WB_WAIT;
		t.wait_int_nack=1'b1;
		t.wait_int_ack=1'b0;
		t.stall_cycles=0;
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

		function void arb_loss_address_req_write(input bit [7:0] addr);
		//master_write(DPR, addr);
		wb_transaction_arb_loss u;
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
		u = new("trigger_address_transmission_arb");
		u.write = 1'b1;
		u.line = CMDR;
		u.word=8'b0;
		u.cmd=I2C_WRITE;
		u.wait_int_nack=1'b1;
		u.wait_int_ack=1'b0;
		u.stall_cycles=0;
		wb_trans.push_back(u);

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
	// Write a single byte of data to a previously-addressed I2C Slave
	// Check to ensure we didn't get a NACK/ Got the ACK from the slave.
	// ****************************************************************************
	function void write_data_byte_with_stall(input bit [7:0] data, int stll);
		//master_write(DPR, data);
		wb_transaction t = new("emplace_data_for_write");
		t.write = 1'b1;
		t.line = DPR;
		t.word=data;
		t.cmd=NONE;
		t.wait_int_nack=1'b0;
		t.wait_int_ack=1'b0;
		t.stall_cycles=stll;
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