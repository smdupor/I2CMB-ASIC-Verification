class i2cmb_predictor extends ncsu_component;

	typedef enum int {RESET, 					// Initial State
						DISABLED,				// DUT Manually disabled
						IDLE, 					// DUT ENABLED AND IDLE
						BUS_NUM_EMPLACED,		//DPR WR
						BUS_SEL_WAIT_DONE,		// CMDR RD
						START_ISSUED_WAIT_DONE, //CMDR WR
						START_DONE,				//CMDR RD
						ADDRESS_EMPLACED_READ,	//DPR WR
						ADDRESS_EMPLACED_WRITE, 	//DPR WR
						ADDRESS_WAIT_DONE,        //CMDR RD
						TRANSACTION_IN_PROG_IDLE,	
						BYTE_EMPLACED_WRITE,		// DPR WR
						WRITE_WAIT_DONE,			//CMDR WR
						// TRANSACTION IN PROGRESS IDLE
						READ_ACK_WAIT_DONE,			//CMDR RD
						READ_NACK_WAIT_DONE, 		// CMDR RD
						READ_DATA_READY,
						// TRANSACTION IN PROGRESS IDLE
						EXPLICIT_WAIT_WAITING		//TBD
						 } pred_states;
	enum int {DONE=7, ARB=6, NACK=5, ERR=4} cmdr_bit_locs;
	enum int {ENBL=7, INTR=6} csr_bit_locs;

	ncsu_component scoreboard;
	ncsu_transaction transport_trans;
	i2cmb_env_configuration configuration;
	pred_states state;

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
	bit is_write;

	//Coverage switches
	bit disable_bus_checking;
	bit disable_intr;

	
	  covergroup wait_cg;
		option.per_instance = 1;
    	option.name = get_full_name();


		explicit_wait_times:	coverpoint most_recent_wait
		{
		
			bins SHORT_1_to_5ms = {[1:5]};
			bins MED_6ms_to_10ms = {[6:10]};
			bins LONG_11ms_to_15ms = {[11:15]};
		}
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
		state=DISABLED;
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
		is_write = itrans.write;

		//Based on REGISTER Address of received transaction, process transaction data accordingly
		case(adr_mon)
			CSR: fsm_process_csr_transaction(); 												// Caught a CSR (Control Status Register) Transaction
			DPR: fsm_process_dpr_transaction(); 												// Caught a DPR (Data / Parameter Register) Transaction
			CMDR: fsm_process_cmdr_transaction();
			/*begin 																	// Caught a CMDR (Command Register) Transaction
				if(dat_mon[2:0] == M_I2C_START && we_mon) process_start_transaction();		// 		Which indicated START
				if(dat_mon[2:0] == M_I2C_STOP && we_mon) process_stop_transaction();		//		Which indicated STOP
				if(dat_mon[2:0] == M_I2C_WRITE && we_mon && !expect_i2c_address) words_transferred.push_back(last_dpr); // Which Contains data write action, capture the data
				else if(dat_mon[2:0] == M_I2C_WRITE && we_mon) process_address_transaction(); 							// Which Contains an address transmit action
				if(dat_mon[2:0] == M_READ_WITH_ACK || dat_mon[2:0] == M_READ_WITH_NACK) capture_next_read = 1'b1; 		// Which is intrupt clear for a I2C_READ expected on next task call 
				if(dat_mon[2:0] == M_WB_WAIT) most_recent_wait = last_dpr;
				if(dat_mon[2:0] == M_SET_I2C_BUS) sel_bus = last_dpr;
			end*/
			default: process_state_register_transaction(); // Caught a state debug register transaction
		endcase

	endfunction

 	// ****************************************************************************
	// Handle any actions passed to the (Command Register), CDMDR
	// ****************************************************************************
	function void fsm_process_cmdr_transaction();
		if(is_write)
			case(state)
				RESET: begin					// Initial State
						// Illegal Write
						end
				DISABLED: begin 					// DUT Manually disabled
						// Illegal Write
						end
				IDLE: begin 						// DUT ENABLED AND IDLE
						if(dat_mon[2:0] == M_I2C_START) begin
							process_start_transaction();		// 		Which indicated START
							state = START_ISSUED_WAIT_DONE; end
						end
				BUS_NUM_EMPLACED: begin 			//DPR WR
						// Starting the bus select action
						if(dat_mon[2:0] == M_SET_I2C_BUS) sel_bus = last_dpr;
						state=BUS_SEL_WAIT_DONE;
						end
				BUS_SEL_WAIT_DONE: begin 			// CMDR RD
						// Illegal
						end
				START_ISSUED_WAIT_DONE: begin 	//CMDR WR
								// illegal		
					end
				START_DONE: begin					// Start issued then immediate stop
					if(dat_mon[2:0] == M_I2C_STOP) begin process_stop_transaction();		//		Which indicated STOP
						state = IDLE;
					end
					if(dat_mon[2:0] == M_I2C_WRITE) begin  // Writing an address to the default value (0)
						last_dpr = 8'b0;
						process_address_transaction(); 							// Which Contains an address transmit action			
						state=ADDRESS_WAIT_DONE;
					end	
				end
				ADDRESS_EMPLACED_READ: begin		//DPR WR
					if(dat_mon[2:0] == M_I2C_WRITE) begin
						process_address_transaction(); 							// Which Contains an address transmit action			
						state=ADDRESS_WAIT_DONE;
					end				
					end
				ADDRESS_EMPLACED_WRITE: begin 	//DPR WR
					if(dat_mon[2:0] == M_I2C_WRITE) begin
						process_address_transaction(); 							// Which Contains an address transmit action			
						state=ADDRESS_WAIT_DONE;
					end					
					end
				ADDRESS_WAIT_DONE: begin      	//CMDR RD
							// Illegal			
					end
				TRANSACTION_IN_PROG_IDLE: begin	// Transaction is happening, but a complete address is done or a complete read/write is done.
						if(dat_mon[2:0] == M_I2C_STOP) begin
							 process_stop_transaction();		//		Which indicated STOP
							 state = IDLE;
						end
						if(dat_mon[2:0] == M_I2C_WRITE) begin
							 words_transferred.push_back(last_dpr);
							state = WRITE_WAIT_DONE;
						end
						if(dat_mon[2:0] == M_READ_WITH_ACK) state = READ_ACK_WAIT_DONE;
						if(dat_mon[2:0] == M_READ_WITH_NACK) state = READ_NACK_WAIT_DONE; 	
					end
				BYTE_EMPLACED_WRITE: begin		// DPR WR
						if(dat_mon[2:0] == M_I2C_WRITE) begin
							 words_transferred.push_back(last_dpr);	
							state = WRITE_WAIT_DONE;
						end				
					end
				WRITE_WAIT_DONE: begin			//CMDR WR
						// Illegal				// TRANSACTION IN PROGRESS IDLE
					end																		
				READ_ACK_WAIT_DONE: begin			//CMDR RD
					// Illegal									
					end
				READ_NACK_WAIT_DONE: begin 		// CMDR RD
					if(dat_mon[2:0] == M_WB_WAIT) begin 
						most_recent_wait = last_dpr;											// TRANSACTION IN PROGRESS IDLE
						state = EXPLICIT_WAIT_WAITING;
					end
				end
				READ_DATA_READY: begin
					// Legal, but data destructive.
				end
				EXPLICIT_WAIT_WAITING: begin		//TBD
					// Illegal																	
					end
			endcase
		else // THIS IS A READ TO CMDR
			case(state)
				RESET: begin					// Initial State
						// Check Default CMDR
						end
				DISABLED: begin 					// DUT Manually disabled
						// Check Default CMDR
						end
				IDLE: begin 						// DUT ENABLED AND IDLE
						// Check Idle Values
						end
				BUS_NUM_EMPLACED: begin 			//DPR WR
						// Check Idle Values
						end
				BUS_SEL_WAIT_DONE: begin 			// CMDR RD
						// An Interrupt Clear
						if(dat_mon[DONE]) state = IDLE;
						end
				START_ISSUED_WAIT_DONE: begin 	//CMDR WR
					// An Interrupt Clear
						if(dat_mon[DONE]) state = START_DONE;
					end
				START_DONE: begin					//CMDR RD
					// Value Check
					end
				ADDRESS_EMPLACED_READ: begin		//DPR WR
					// Value Check
					end
				ADDRESS_EMPLACED_WRITE: begin 	//DPR WR
					// Value Check					
					end
				ADDRESS_WAIT_DONE: begin      	//CMDR RD
					// An Interrupt Clear
						if(dat_mon[DONE]) state = TRANSACTION_IN_PROG_IDLE;					
					end
				TRANSACTION_IN_PROG_IDLE: begin	// Transaction is happening, but a complete address is done or a complete read/write is done.
					// Value Check				
					end
				BYTE_EMPLACED_WRITE: begin		// DPR WR
					// Value Check		
					end
				WRITE_WAIT_DONE: begin			//CMDR WR
					// An Interrupt Clear
					if(dat_mon[DONE]) state = TRANSACTION_IN_PROG_IDLE;
					end																		
				READ_ACK_WAIT_DONE: begin			//CMDR RD
					// An Interrupt  Clear
					if(dat_mon[DONE]) state = READ_DATA_READY;
					end
				READ_NACK_WAIT_DONE: begin 		// CMDR RD
					// An Interrupt  Clear
					if(dat_mon[DONE]) state = READ_DATA_READY;
					end
				READ_DATA_READY: begin
					// Value Check
				end
				EXPLICIT_WAIT_WAITING: begin		//TBD
					// An Interrupt  Clear
					if(dat_mon[DONE]) state = IDLE;
					
					end
			endcase
	endfunction

	function void check_cmdr_default();

	endfunction


 	// ****************************************************************************
	// Handle any actions passed to the (Command Register), CDMDR
	// ****************************************************************************
	function void fsm_process_csr_transaction();
		if(is_write) begin
				if(dat_mon[ENBL]) begin 
						 state=IDLE;
						 disable_intr = dat_mon[INTR];
					end
					else state=DISABLED;
		end
		else // THIS IS A READ TO CSR
			case(state)
				RESET: begin					// Initial State
						// DEFAULT VALUE CHECK
						end
				DISABLED: begin 					// DUT Manually disabled
						// DISABLED VALUE  CHECK
						end
				default: begin 						// DUT ENABLED AND IDLE
						process_csr_transaction();
						end
			endcase
	endfunction

 	// ****************************************************************************
	// Handle any actions passed to the (Control Status Register), eg DUT Enable/Disables 
	// ****************************************************************************
	function void process_csr_transaction();
		if(we_mon == 1'b0) begin

			
			assert_csr_enabled: assert(dat_mon[7] == 1'b1)
			else $error("Asssertion assert_csr_enabled failed with %b", dat_mon);

			if(disable_intr) begin
			assert_interrupt_bit_high: assert(dat_mon[6] == 1'b1)
			else $error("Asssertion assert_interrupt_bit_high failed with %b", dat_mon);
			end
			else begin
			assert_interrupt_bit_low: assert(dat_mon[6] == 1'b0)
			else $error("Asssertion assert_interrupt_bit_low failed with %b", dat_mon);
			end

			if(transaction_in_progress) begin
			assert_csr_bc_captured: assert(dat_mon[4]==1'b1)
			else $error("Asssertion assert_bc_captured failed with %b", dat_mon);
			assert_csr_bb_busy: assert(dat_mon[5]==1'b1)
			else $error("Asssertion assert_bb_bus_busy busy failed with %b", dat_mon);
			end 
			
			else begin
			assert_csr_bc_free: assert(dat_mon[4]==1'b0)
			else $error("Asssertion assert_bc_free failed with %b", dat_mon);
			assert_csr_bb_free: assert(dat_mon[5]==1'b1)
			else $error("Asssertion assert_bb_bus_busy_free failed with %b", dat_mon);
			end

			if(!configuration.disable_bus_checking) assert_csr_bus_sel_accuracy: assert(dat_mon[3:0] == sel_bus)
			else $error("Asssertion assert_csr_bus_sel_accuracy failed with %b vs %b", dat_mon, sel_bus);

		end else begin
			disable_intr = dat_mon[6];
		end
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
	// Handle any actions passed to the (Command Register), CDMDR
	// ****************************************************************************
	function void fsm_process_dpr_transaction();
		if(is_write) begin
			last_dpr = dat_mon;
			case(state)
				RESET: begin					// Initial State
				// illegal		
						end
				DISABLED: begin 					// DUT Manually disabled
				// illegal
						end
				IDLE: begin 						// DUT ENABLED AND IDLE
					sel_bus = dat_mon;
					state = BUS_NUM_EMPLACED;
						end
				BUS_NUM_EMPLACED: begin 			//DPR WR
					sel_bus = dat_mon;
					state = BUS_NUM_EMPLACED;
						end
				BUS_SEL_WAIT_DONE: begin 			// CMDR RD
					// Illegal
						end
				START_ISSUED_WAIT_DONE: begin 	//CMDR WR
					// Illegal										
					end
				START_DONE: begin					//CMDR RD
					monitored_trans.address=last_dpr[7:1];						// Extract the Address
					if(last_dpr[0]==1'b0) begin
						 monitored_trans.rw = I2_WRITE; 		// Address Transmit was requesting a write
						 state = ADDRESS_EMPLACED_WRITE;
					end
					else begin
						 monitored_trans.rw = I2_READ; 							// Address Transmit was requesting a read
						 state = ADDRESS_EMPLACED_READ;
					end
					//expect_i2c_address = 1'b0;								// Indicate that the address has been captured and next transaction will carry data
					cov_op = monitored_trans.rw;
					end
				ADDRESS_EMPLACED_READ: begin		//Write after Write
					monitored_trans.address=last_dpr[7:1];						// Extract the Address
					if(last_dpr[0]==1'b0) begin
						 monitored_trans.rw = I2_WRITE; 		// Address Transmit was requesting a write
						 state = ADDRESS_EMPLACED_WRITE;
					end
					else begin
						 monitored_trans.rw = I2_READ; 							// Address Transmit was requesting a read
						 state = ADDRESS_EMPLACED_READ;
					end
					//expect_i2c_address = 1'b0;								// Indicate that the address has been captured and next transaction will carry data
					cov_op = monitored_trans.rw;
					end				

				ADDRESS_EMPLACED_WRITE: begin 	// Write after write
					monitored_trans.address=last_dpr[7:1];						// Extract the Address
					if(last_dpr[0]==1'b0) begin
						 monitored_trans.rw = I2_WRITE; 		// Address Transmit was requesting a write
						 state = ADDRESS_EMPLACED_WRITE;
					end
					else begin
						 monitored_trans.rw = I2_READ; 							// Address Transmit was requesting a read
						 state = ADDRESS_EMPLACED_READ;
					end
					//expect_i2c_address = 1'b0;								// Indicate that the address has been captured and next transaction will carry data
					cov_op = monitored_trans.rw;
					end					

				ADDRESS_WAIT_DONE: begin      	//CMDR RD
						// Illegal				
					end
				TRANSACTION_IN_PROG_IDLE: begin	// Transaction is happening, but a complete address is done or a complete read/write is done.
					state = BYTE_EMPLACED_WRITE;				
					end
				BYTE_EMPLACED_WRITE: begin		// DPR WR
					state = BYTE_EMPLACED_WRITE;				
					end
				WRITE_WAIT_DONE: begin			//CMDR WR
					// Illegal
					end																		
				READ_ACK_WAIT_DONE: begin			//CMDR RD
					// Illegal							
					end
				READ_NACK_WAIT_DONE: begin 		// CMDR RD
					// Illegal			
					end
				READ_DATA_READY: begin
					// Legal But data destructive
				end
				EXPLICIT_WAIT_WAITING: begin		//TBD
					// Illegal							
					end
			endcase
		end
		else // THIS IS A READ TO DPR
		case(state)
				RESET: begin					// Initial State
					// DEFAULT Value check							
						end
				DISABLED: begin 					// DUT Manually disabled
					// DEFAULT Value check	
						end
				IDLE: begin 						// DUT ENABLED AND IDLE
					// Value check	
						end
				BUS_NUM_EMPLACED: begin 			//DPR WR
					// Value check	
						end
				BUS_SEL_WAIT_DONE: begin 			// CMDR RD
					// Value check	
						end
				START_ISSUED_WAIT_DONE: begin 	//CMDR WR
					// Value check		
					end
				START_DONE: begin					//CMDR RD
					// Value check		
					end
				ADDRESS_EMPLACED_READ: begin		//DPR WR
					// Value check					
					end
				ADDRESS_EMPLACED_WRITE: begin 	//DPR WR
					// Value check				
					end
				ADDRESS_WAIT_DONE: begin      	//CMDR RD
					// Value check		
					end
				TRANSACTION_IN_PROG_IDLE: begin	// Transaction is happening, but a complete address is done or a complete read/write is done.
					// Value check		
					end
				BYTE_EMPLACED_WRITE: begin		// DPR WR
					// Value check		
					end
				WRITE_WAIT_DONE: begin			//CMDR WR
					// Value check	
					end																		
				READ_ACK_WAIT_DONE: begin			//CMDR RD
					// Value check							
					end
				READ_NACK_WAIT_DONE: begin 		// CMDR RD
					// Value check					
					end
				READ_DATA_READY: begin

				words_transferred.push_back(dat_mon); // Which Contains data write action, capture the data
				state = TRANSACTION_IN_PROG_IDLE;
				end
				EXPLICIT_WAIT_WAITING: begin		//TBD
					// Value check									
					end
			endcase
			
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
