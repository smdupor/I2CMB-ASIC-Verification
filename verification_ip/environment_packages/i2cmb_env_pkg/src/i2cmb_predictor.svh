class i2cmb_predictor extends ncsu_component;

	ncsu_component scoreboard;
	ncsu_transaction transport_trans;
	i2cmb_env_configuration configuration;
	
	// Internal persistent Storage Buffers
	i2c_transaction monitored_trans;
	bit capture_next_read, expect_i2c_address, transaction_in_progress;
	bit [7:0] last_dpr;
	bit [2:0] adr_mon;
	bit [7:0] dat_mon;
	bit  we_mon;
	bit [7:0] words_transferred[$];
	int counter;
	int most_recent_wait;
	i2c_op_t cov_op;
	logic is_restart;
	int sel_bus;

	
	  covergroup wait_cg;
		option.per_instance = 1;
    	option.name = get_full_name();


	explicit_wait_times:	coverpoint most_recent_wait
	{
		
		bins SHORT_1_to_5ms = {[1:5]};
		bins MED_6ms_to_10ms = {[6:10]};
		bins LONG_11ms_to_15ms = {[11:15]};
	}
	//wb_x_i2c_delay: 	cross wb_stretch_delay, clockstretch_cg.i2c_stretch_delay;

	  endgroup

  covergroup predictor_cg;
  	option.per_instance = 1;
    option.name = get_full_name();

		operation: coverpoint cov_op
	{
		bins I2_WRITE = {I2_WRITE};
		bins I2_READ = {I2_READ};
	}

		start_or_restart:	coverpoint is_restart
	{
		bins START = {0};
		bins RESTART = {1};
	}
	restart_x_operation: 	cross operation, start_or_restart;
  endgroup

	// ****************************************************************************
	// Construction, setters, and getters 
	// ****************************************************************************
	function new(string name = "", ncsu_component_base  parent = null);
		super.new(name,parent);
		predictor_cg = new();
		wait_cg = new();
		verbosity_level = global_verbosity_level;
	endfunction

	function void set_configuration(i2cmb_env_configuration cfg);
		configuration = cfg;
	endfunction

	virtual function void set_scoreboard(ncsu_component scoreboard);
		this.scoreboard = scoreboard;
	endfunction

 	// ****************************************************************************
	// Called from wb_agent, process all incoming monitored wb transactions.
	// ****************************************************************************
	virtual function void nb_put(ncsu_transaction trans);
		wb_transaction itrans;
		$cast(itrans, trans); // Grab incoming transaction process

		// Copy incoming transaction data into persistent data structure
		adr_mon = itrans.line;
		dat_mon = itrans.word;
		we_mon = itrans.write;

		//Based on REGISTER Address of received transaction, process transaction data accordingly
		case(adr_mon)
			CSR: process_csr_transaction(); 												// Caught a CSR (Control Status Register) Transaction
			DPR: process_dpr_transaction(); 												// Caught a DPR (Data / Parameter Register) Transaction
			CMDR: begin 																	// Caught a CMDR (Command Register) Transaction
				if(dat_mon[2:0] == M_I2C_START && we_mon) process_start_transaction();		// 		Which indicated START
				if(dat_mon[2:0] == M_I2C_STOP && we_mon) process_stop_transaction();		//		Which indicated STOP
				if(dat_mon[2:0] == M_I2C_WRITE && we_mon && !expect_i2c_address) words_transferred.push_back(last_dpr); // Which Contains data write action, capture the data
				else if(dat_mon[2:0] == M_I2C_WRITE && we_mon) process_address_transaction(); 							// Which Contains an address transmit action
				if(dat_mon[2:0] == M_READ_WITH_ACK || dat_mon[2:0] == M_READ_WITH_NACK) capture_next_read = 1'b1; 		// Which is intrupt clear for a I2C_READ expected on next task call 
				if(dat_mon[2:0] == M_WB_WAIT) most_recent_wait = last_dpr;
				if(dat_mon[2:0] == M_SET_I2C_BUS) sel_bus = last_dpr;
			end
			default: process_state_register_transaction(); // Caught a state debug register transaction
		endcase

	endfunction

 	// ****************************************************************************
	// Handle any actions passed to the (Control Status Register), eg DUT Enable/Disables 
	// ****************************************************************************
	function void process_csr_transaction();
				// For Now, simply SWALLOW CSR Transactions 
				//(Only used for DUT Enable/Disable at this time)
	endfunction

	// ****************************************************************************
	// Handle any actions on the (Data / Parameter Register), in particular, 
	// 		capturing data received from an I2C_READ.
	// ****************************************************************************
	function void process_dpr_transaction();
		last_dpr = dat_mon;
		if(capture_next_read) begin 								// The Predictor is expecting data from a READ transaction; 
			capture_next_read = 1'b0;								// Let Predictor know that the next transaction will be a command of some form.
			words_transferred.push_back(last_dpr);					// Capture the data
		end
	endfunction

	// ****************************************************************************
	// Handle a START or a RE-START action 
	// ****************************************************************************
	function void process_start_transaction();
			is_restart = 1'b0;
		if(transaction_in_progress) begin	
			is_restart = 1'b1;						// Detect a re-start condition,
			monitored_trans.data=words_transferred;					// conclude last transaction 
			words_transferred.delete();		
			predictor_cg.sample();
			wait_cg.sample();
			most_recent_wait = 0;						// and pass data from it to scoreboard
			scoreboard.nb_transport(monitored_trans,transport_trans);
		end
																	// Then, Create a new Transaction
		monitored_trans = new({"i2c_trans(", itoalpha(counter++),")"});
		monitored_trans.selected_bus = sel_bus;
		if(most_recent_wait > 0) begin
			monitored_trans.explicit_wait_ms = most_recent_wait;
			//most_recent_wait = 0;
		end
		transaction_in_progress = 1'b1; 							// Advise state machine that a transaction is now in progress
		expect_i2c_address = 1'b1; 									// Advise state machine that the next transaction should contain an I2C address
	endfunction

	// ****************************************************************************
	// Handle a STOP action 
	// ****************************************************************************
	function void process_stop_transaction();
		transaction_in_progress = 1'b0; 							// Advise state machine that transactions are concluded.
		monitored_trans.data=words_transferred; 					// Copy complete dataset into monitored transaction
		words_transferred.delete(); 
		predictor_cg.sample();	
					wait_cg.sample();
			most_recent_wait = 0;								// Clear predictor buffer
		scoreboard.nb_transport(monitored_trans,transport_trans);	// Send completed transaction to scoreboard
	endfunction

 	// ****************************************************************************
	// Handle an action dealing with an I2C Address and the expected operation 
	// (I2C_READ or I2C_WRITE)
	// ****************************************************************************
	function void process_address_transaction();
		monitored_trans.address=last_dpr[7:1];						// Extract the Address
		if(last_dpr[0]==1'b0) monitored_trans.rw = I2_WRITE; 		// Address Transmit was requesting a write
		else monitored_trans.rw = I2_READ; 							// Address Transmit was requesting a read
		expect_i2c_address = 1'b0;									// Indicate that the address has been captured and next transaction will carry data
		cov_op = monitored_trans.rw;
	endfunction

 	// ****************************************************************************
	// Handle any actions on the State Register
	// ****************************************************************************
	function void process_state_register_transaction();
		// SWALLOW reads of the debug state register
	endfunction

endclass
