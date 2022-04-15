class i2cmb_predictor extends ncsu_component;
  //_____________________________________________________________________________________\\
	//                         STATES and BIT VECTOR LOCATIONS                             \\
	//_____________________________________________________________________________________\\
  typedef enum int {
    RESET,                     // Initial State (on hard reset)
    DISABLED,                  // DUT Manually disabled (a soft reset)
    IDLE,                      // DUT ENABLED AND IDLE
    BUS_NUM_EMPLACED,          // The requested bus number has been written to the DPR      
    BUS_SEL_WAIT_DONE,         // The command to set bus has been issued, poll for DONE or interrupt.
    START_ISSUED_WAIT_DONE,    // A start command has been sent, poll for DONE or interrupt.
    START_DONE,                // The start is complete, the bus is captured, ready for new commands.
    ADDRESS_EMPLACED_READ,     // The address for a READ has been written to the DPR
    ADDRESS_EMPLACED_WRITE,    // The address for a WRITE has been written to the DPR
    ADDRESS_WAIT_DONE,         // The transmit address command has been sent, poll for DONE or interrupt.
    TRANSACTION_IN_PROG_IDLE,  // An address (or prior data) has been transmitted sucessfully, ready to send more data.
    BYTE_EMPLACED_WRITE,       // A byte for a I2C WRITE has been written to the DPR
    WRITE_WAIT_DONE,           // The write command has been executed, poll for DONE or interrupt.
    READ_ACK_WAIT_DONE,        // The read command with ACK has been executed , poll for DONE or interrupt.
    READ_NACK_WAIT_DONE,       // The read command with NACK has been executed, poll for DONE or interrupt.
    READ_DATA_READY,           // Read Data is read in the DPR.
    EXPLICIT_WAIT_WAITING      // An explicit WAIT command has been executed, poll for DONE or interrupt.
  } pred_states;

  enum int {DONE = 7, ARB  = 6, NACK = 5, ERR  = 4} cmdr_bit_locs;  // Bit vector locations of key status bits in CMDR
  enum int {ENBL = 7, INTR = 6} csr_bit_locs;                       // Bit vector locations of key status bits is CSR

  //_____________________________________________________________________________________\\
	//                           CLASS-WIDE VARIABLES                                      \\
	//_____________________________________________________________________________________\\
  // Connections to other testbench components
  ncsu_component scoreboard;
  ncsu_transaction transport_trans;
  i2cmb_env_configuration configuration;


  // Internal persistent Storage Buffers modeling the input wires to the Register File
  pred_states state;
  i2c_transaction monitored_trans;
  bit [7:0] last_dpr;
  bit [2:0] adr_mon;
  bit [7:0] dat_mon;
  bit we_mon;

  // Persistent storage of data across an entire I2c Transaction
  bit [7:0] words_transferred[$];

  // Counters and multi-state behavioural flags
  bit capture_next_read, transaction_in_progress;
  int transaction_counter;
  int most_recent_wait;             // From an explicit WAIT command
  i2c_op_t cov_op;                  // This I2C Operation for coverage purposes
  logic is_restart;                 // Whether this operation was a START or RESTART
  int selected_bus;                 // The bus of this I2C Transaction
  bit is_write;                     // bit-formatted I2C Operation

  //Coverage switches
  bit disable_bus_checking;         // Bus addresses from WB **WILL** be purposely mismatched, correct when enabled.
  bit disable_intr;                 // DUT Configured with Interrupts OFF

  //_____________________________________________________________________________________\\
	//                                COVERAGE ITEMS                                       \\
	//_____________________________________________________________________________________\\

  // ****************************************************************************
  // Cover wait values here, as the main Coverage module cannot "remember" past states
  // in an effective manner such that it can monitor the values from WAIT commands
  // ****************************************************************************
  covergroup wait_cg;
    option.per_instance = 1;
    option.name = get_full_name();
    explicit_wait_times: coverpoint most_recent_wait {
      bins SHORT_1_to_2ms = {[1 : 2]};
      bins MED_3ms_to_5ms = {[3 : 5]};
      bins LONG_6s_to_8ms = {[6 : 8]};
    }
  endgroup

  // ****************************************************************************
  // Cover operations vs start/restarts here, because the main coverage module
  // does not have "oracle" knowledge of whether the past transaction was 
  // concluded with a STOP (hence, this is a START) or, concluded
  // without sending STOP, hence this is a RE-START.
  // ****************************************************************************
  covergroup predictor_cg;
    option.per_instance = 1;
    option.name = get_full_name();
    operation: coverpoint cov_op {bins I2_WRITE = {I2_WRITE}; bins I2_READ = {I2_READ};}
    start_or_restart: coverpoint is_restart {bins START = {0}; bins RESTART = {1};}
    restart_x_operation: cross operation, start_or_restart;
  endgroup

  //_____________________________________________________________________________________\\
	//                                CONSTRUCTION AND ACCESS                              \\
	//_____________________________________________________________________________________\\
  // ****************************************************************************
  // Construction, setters, and getters 
  // ****************************************************************************
  function new(string name = "", ncsu_component_base parent = null);
    super.new(name, parent);
    predictor_cg = new();
    wait_cg = new();
    state = DISABLED;
    verbosity_level = global_verbosity_level;
  endfunction

  function void set_configuration(i2cmb_env_configuration cfg);
    configuration = cfg;
  endfunction

  virtual function void set_scoreboard(ncsu_component scoreboard);
    this.scoreboard = scoreboard;
  endfunction

  //_____________________________________________________________________________________\\
	//                     MODEL OF THE REGBLOCK PORT                                      \\
	//_____________________________________________________________________________________\\

  // ****************************************************************************
  // Called from wb_agent, process all incoming monitored wb transactions.
  //
  // For THIS PREDICTOR, nb_put models the register block in the DUT. Based on the
  // address of the WB Transaction, the transaction is passed to the approprate
  // register handler.
  // ****************************************************************************
  virtual function void nb_put(ncsu_transaction trans);
    wb_transaction itrans;
    if (configuration.disable_predictor) return;  // Guard against disabled predictor for directed tests.

    $cast(itrans, trans);  // Grab incoming transaction 

    // Copy incoming transaction data into persistent data structure
    adr_mon  = itrans.line;
    dat_mon  = itrans.word;
    we_mon   = itrans.write;
    is_write = itrans.write;

    //Based on REGISTER Address of received transaction, process transaction by passing it to appropriate register handler
    case (adr_mon)
      CSR:  process_csr_transaction();            // Caught a CSR (Control Status Register) Transaction
      DPR:  process_dpr_transaction();            // Caught a DPR (Data / Parameter Register) Transaction
      CMDR: process_cmdr_transaction();           // Caught a CMDR (Command Register) Transaction
      FSMR: process_fsmr_register_transaction();  // Caught a state debug register transaction
    endcase

  endfunction

  //_____________________________________________________________________________________\\
	//                         MODEL THE PORTS TO THE CMDR                                 \\
	//_____________________________________________________________________________________\\

  // ****************************************************************************
  // Handle any actions passed to the (Command Register), CDMDR
  // ****************************************************************************
  virtual function void process_cmdr_transaction();
    if (is_write) begin                             // THIS IS A WRITE TO THE CMDR
      if (dat_mon[2:0] == M_WB_WAIT) begin
        most_recent_wait = last_dpr;                // Handle injected wait commands regardless of FSM state
        wait_cg.sample();
      end
      case (state)                                  // HANDLE WRITES FOR EACH MACHINE STATE
        RESET: begin                                // Illegal Write
        end
        DISABLED: begin                             // Illegal Write
        end
        IDLE: begin                                 // DUT ENABLED AND IDLE
          if (dat_mon[2:0] == M_I2C_START) begin
            process_start_transaction();             // Incoming trans indicated START, send to the start processor and wait for DONE/intr
            state = START_ISSUED_WAIT_DONE;
          end

          if (dat_mon[2:0] == M_WB_WAIT) begin
            state = EXPLICIT_WAIT_WAITING;            //Incoming trans indicated WAIT, wait for DONE/intr
          end
         if (dat_mon[2:0] == M_SET_I2C_BUS) begin selected_bus = last_dpr; // A bus select was run without first emplacing a new bus num
          state = BUS_SEL_WAIT_DONE; 
          end
        end
        BUS_NUM_EMPLACED: begin  
          if (dat_mon[2:0] == M_SET_I2C_BUS) selected_bus = last_dpr;   // A  bus select is being executed
          state = BUS_SEL_WAIT_DONE;
        end
        BUS_SEL_WAIT_DONE: begin                        // Illegal write
        end
        START_ISSUED_WAIT_DONE: begin                   // Illegal write
        end
        START_DONE: begin           
          if (dat_mon[2:0] == M_I2C_STOP) begin         // Start issued then immediate stop (No adress No Data transaction)
            process_stop_transaction();
            state = IDLE;
          end
          if (dat_mon[2:0] == M_I2C_WRITE) begin        // Writing an address (to the default value, and it's an I2c write)
            last_dpr = 8'b0;                            // by not previously setting address properly.
            process_address_transaction();  		
            state = ADDRESS_WAIT_DONE;
          end
        end
        ADDRESS_EMPLACED_READ: begin  
          if (dat_mon[2:0] == M_I2C_WRITE) begin
            process_address_transaction();              // Address has been placed for a READ, execute the transmission		
            state = ADDRESS_WAIT_DONE;
          end
        end
        ADDRESS_EMPLACED_WRITE: begin  
          if (dat_mon[2:0] == M_I2C_WRITE) begin
            process_address_transaction();               // Address has been placed for a WRITE, execute the transmission	
            state = ADDRESS_WAIT_DONE;
          end
        end
        ADDRESS_WAIT_DONE: begin                        // Illegal Write
        end
        TRANSACTION_IN_PROG_IDLE: begin	// Transaction is happening, and a complete address is done or a complete read/write is done.
          if (dat_mon[2:0] == M_I2C_STOP) begin
            process_stop_transaction();                   // STOP command executed, end the transaction
            state = IDLE;
          end
          if (dat_mon[2:0] == M_I2C_START) begin
            process_start_transaction();                  //	Re-Start command executed, close this transaction and start a new one.
            state = START_ISSUED_WAIT_DONE;
          end
          if (dat_mon[2:0] == M_I2C_WRITE) begin
            words_transferred.push_back(last_dpr);        // Exectue the Write a Byte of data to a remote slave.
            state = WRITE_WAIT_DONE;
          end
          if (dat_mon[2:0] == M_READ_WITH_ACK) state = READ_ACK_WAIT_DONE;    // Expect a byte to be read from a remote slave, wait for intr/DONE.
          if (dat_mon[2:0] == M_READ_WITH_NACK) state = READ_NACK_WAIT_DONE;  // Expect a byte to be read from a remote slave, wait for intr/DONE.
        end
        BYTE_EMPLACED_WRITE: begin  
          if (dat_mon[2:0] == M_I2C_WRITE) begin
            words_transferred.push_back(last_dpr);
            state = WRITE_WAIT_DONE;
          end
        end
        WRITE_WAIT_DONE: begin                            // Illegal Write
        end
        READ_ACK_WAIT_DONE: begin                         // Illegal	Write
        end
        READ_NACK_WAIT_DONE: begin                        // Illegal Write
        end
        READ_DATA_READY: begin                            // A write here is a Legal action, but will destroy 
        end                                               //      the data in the DPR that was just received from a remote slave.
        EXPLICIT_WAIT_WAITING: begin                      // Illegal Write
        end
      endcase
    end 
    
    else  // THIS IS A READ TO CMDR. Any non-functional reads will be for debug only, swallow them.
      case (state)
        BUS_SEL_WAIT_DONE: begin  
          if (dat_mon[DONE]) state = IDLE;        // An Interrupt Clear, return to idle state after bus selection
        end
        START_ISSUED_WAIT_DONE: begin  
          if (dat_mon[DONE]) state = START_DONE;  // An Interrupt Clear, start command was issued successfully, go to START_DONE  
        end
        ADDRESS_WAIT_DONE: begin  
          if (dat_mon[DONE]) state = TRANSACTION_IN_PROG_IDLE;             // An Interrupt Clear, the address was sent
          if (configuration.expect_nacks) begin                            // If we expect remote slave to respond (most cases)
            assert_adr_nacks_when_expected :                               // Verify that we did not receive a NACK
            assert (dat_mon[6] == configuration.expect_nacks)              // Only when testing unresponsive slaves, should we
            else $error("Assertion assert_adr_nacks_when_expected failed!");// See a NACK
            if (dat_mon[6]) monitored_trans.contained_nack = 1'b1;
            state = TRANSACTION_IN_PROG_IDLE;
          end
        end
        WRITE_WAIT_DONE: begin                                            // An interrupt clear, we are done writing. check that 
          if (dat_mon[DONE]) state = TRANSACTION_IN_PROG_IDLE;            // remote slave sent an ACK/NACK
          if (configuration.expect_nacks) begin
            assert_dat_nacks_when_expected :
            assert (dat_mon[6] == configuration.expect_nacks)
            else $error("Assertion assert_dat_nacks_when_expected failed!");
            state = TRANSACTION_IN_PROG_IDLE;
          end
        end
        READ_ACK_WAIT_DONE: begin  
          if (dat_mon[DONE]) state = READ_DATA_READY;                     // The READ was completed and data is ready to be read from
        end                                                               // the DPR
        READ_NACK_WAIT_DONE: begin  
          if (dat_mon[DONE]) state = READ_DATA_READY;                     // The READ was completed and data is ready to be read from
        end                                                               // the DPR
        EXPLICIT_WAIT_WAITING: begin
          if (dat_mon[DONE]) begin                                        // An explict WAIT has completed, ensure that DONE was reached
            most_recent_wait = 0;                                         // and clear the long-term storage value
            state = IDLE;
          end
        end
      endcase
  endfunction

  //_____________________________________________________________________________________\\
	//                         MODEL THE PORT TO THE CSR                                   \\
	//_____________________________________________________________________________________\\

  // ****************************************************************************
  // Handle any actions passed to the (Control Status Register) CSR
  // ****************************************************************************
  virtual function void process_csr_transaction();
    if (is_write) begin // THIS IS A WRITE TO THE CSR
      if (dat_mon[ENBL]) begin                        // CSR has been written to enable/disable the DUT
        state = IDLE;
        disable_intr = dat_mon[INTR];                 // Decide whether to use interrupts or poll the DONE bit.
      end else state = DISABLED;
    end 
    else  // THIS IS A READ TO CSR
      case (state)
        RESET: begin                                // Swallow the DEFAULT VALUE CHECK
        end
        DISABLED: begin                              // Swallow the Manually Disabled value check
        end
        default: begin  
          assert_csr_expected_values();   // CSR is being read to verify Bus Busy, Bus Captured, and Bus Selected bits.
        end                               // Assert their correctness VS Predictor state.
      endcase
  endfunction


  //_____________________________________________________________________________________\\
	//                           MODEL THE PORT TO THE DPR                                 \\
	//_____________________________________________________________________________________\\
  // ****************************************************************************
  // Handle any actions passed to the (Data/Parameter Register), DPR
  // ****************************************************************************
  virtual function void process_dpr_transaction();
    if (is_write) begin //THIS IS A WRITE TO THE DPR
      last_dpr = dat_mon;   // Save the value of this write for use by other blocks in other states.
      case (state)
        RESET: begin  // Illegal write, swallow.
        end
        DISABLED: begin  // Illegal write, swallow.
        end
        IDLE: begin                                               // DUT Idle, this is most likely a Bus Number
          selected_bus = dat_mon;                                 // To be selected. For a WAIT millisecond value, 
          state   = BUS_NUM_EMPLACED;                             // it is captured at the top of this function.
        end
        BUS_NUM_EMPLACED: begin                                   // User has written a different Bus Number before
          selected_bus = dat_mon;                                 // Executing the bus select command, update our value.
          state   = BUS_NUM_EMPLACED;
        end
        BUS_SEL_WAIT_DONE: begin  // Illegal Write, swallow.
        end
        START_ISSUED_WAIT_DONE: begin  // Illegal Write, swallow.
        end
        START_DONE: begin  
          monitored_trans.address = last_dpr[7:1];             // Start is completed, next data will be the address.
          monitored_trans.address += configuration.get_address_shift();  // If we are doing disconnected slaves, counter the offset
          if (monitored_trans.address > 127)                                    // Wrap the offset
            monitored_trans.address = 0 + configuration.get_address_shift() - 1;
          if (last_dpr[0] == 1'b0) begin                        //For all normal transactions, check bit 0 and determine READ or WRITE
            monitored_trans.rw = I2_WRITE;                      // Address Transmit was requesting a write
            state = ADDRESS_EMPLACED_WRITE;
          end else begin
            monitored_trans.rw = I2_READ;                       // Address Transmit was requesting a read
            state              = ADDRESS_EMPLACED_READ;
          end
          cov_op = monitored_trans.rw;                          // Capture the operation for recording coverage
        end
        ADDRESS_EMPLACED_READ: begin                            // WAW Case, the user is changing addresses before issuing cmd
          monitored_trans.address = last_dpr[7:1];              // Extract the Address
          if (last_dpr[0] == 1'b0) begin
            monitored_trans.rw = I2_WRITE;                      // Address Transmit was requesting a write
            state = ADDRESS_EMPLACED_WRITE;
          end else begin
            monitored_trans.rw = I2_READ;                       // Address Transmit was requesting a read
            state              = ADDRESS_EMPLACED_READ;
          end
          cov_op = monitored_trans.rw;                          // Update coverage with WAW Value
        end

        ADDRESS_EMPLACED_WRITE: begin                           // WAW case, the user is changing addresses before issuing cmd
          monitored_trans.address = last_dpr[7:1];              // Extract the Address
          if (last_dpr[0] == 1'b0) begin
            monitored_trans.rw = I2_WRITE;                      // Address Transmit was requesting a write
            state = ADDRESS_EMPLACED_WRITE;
          end else begin
            monitored_trans.rw = I2_READ;                       // Address Transmit was requesting a read
            state              = ADDRESS_EMPLACED_READ;
          end
          cov_op = monitored_trans.rw;                          //Update coverage with WAW Value
        end

        ADDRESS_WAIT_DONE: begin  // Illegal Write, swallow.
        end
        TRANSACTION_IN_PROG_IDLE: begin	                        // A byte of data to be transmitted has been written to the DPR.
          state = BYTE_EMPLACED_WRITE;
        end
        BYTE_EMPLACED_WRITE: begin  	                        //WAW Case A byte of data to be transmitted has been re-written to the DPR.
          state = BYTE_EMPLACED_WRITE;
        end
        WRITE_WAIT_DONE: begin                                // Illegal write, swallow.
        end
        READ_ACK_WAIT_DONE: begin                             // Illegal write, swallow.
        end
        READ_NACK_WAIT_DONE: begin                            // Illegal write, swallow.
        end
        READ_DATA_READY: begin    // A legal action, but it will overwrite data in the DPR that was just received from a remote slave.
        end
        EXPLICIT_WAIT_WAITING: begin                          // Illegal write, swallow.
        end
      endcase
    end else  // THIS IS A READ TO DPR
      case (state)
                      // NB: READS to the DPR are legal in all states, but only have meaning in one: 
                      // When data is ready after a remote slave has sent us data from an I2C READ. Hence,
                      // We will swallow all other reads to the DPR.
        READ_DATA_READY: begin            
          words_transferred.push_back(dat_mon);                // Data from a remote read is ready, capture it.
          state = TRANSACTION_IN_PROG_IDLE;
        end
      endcase
  endfunction

  //_____________________________________________________________________________________\\
	//                       UTILITY FUNCTIONS FOR CERTAIN COMMANDS                        \\
	//_____________________________________________________________________________________\\

  // ****************************************************************************
  // Handle a START or a RE-START action 
  // ****************************************************************************
  function void process_start_transaction();
    is_restart = 1'b0;                                  // Assume this is NOT a re-start
    if (transaction_in_progress) begin                  // Detect a re-start condition,
      is_restart           = 1'b1;                      // Update is_restart to reflect that this IS a restart
      monitored_trans.data = words_transferred;         // conclude last transaction and record all data transmitted/received
      words_transferred.delete();                       // Flush  local data buffer
      predictor_cg.sample();                            // Sample coverages for the last transactions
      scoreboard.nb_transport(monitored_trans, transport_trans);  // Send completed transaction to predictor
    end

    // Then, Create a new Transaction
    monitored_trans = new({"i2c_trans(", 
          itoalpha(transaction_counter++), ")"});
    monitored_trans.selected_bus = selected_bus;        // Record the bus that was captured using this transaction
    transaction_in_progress = 1'b1;                     // Separate from machine states, note that an end-end transaction has started.
  endfunction

  // ****************************************************************************
  // Handle a STOP action 
  // ****************************************************************************
  function void process_stop_transaction();
    transaction_in_progress = 1'b0;                     // Advise state machine and assertion checker that the transaction is done.
    monitored_trans.data = words_transferred;           // Record all data transmitted/received during last transaction.
    words_transferred.delete();                         // Flush local data buffer.
    predictor_cg.sample();                              // Sample coverages from last transaction
    most_recent_wait = 0;                               // Flush most recent wait value, if not already done.
    scoreboard.nb_transport(monitored_trans,
                            transport_trans);           // Send completed transaction to scoreboard
  endfunction

  // ****************************************************************************
  // Handle an action dealing with an I2C Address and the expected operation 
  // (I2C_READ or I2C_WRITE)
  // ****************************************************************************
  function void process_address_transaction();
    monitored_trans.address = last_dpr[7:1];            // Extract the Address that we received and record it
    if (last_dpr[0] == 1'b0)                            // Extract the read/write bit and record it
      monitored_trans.rw = I2_WRITE;                    // Address Transmission was requesting a write
    else monitored_trans.rw = I2_READ;                  // Address Transmission was requesting a read
    cov_op = monitored_trans.rw;
  endfunction


  //_____________________________________________________________________________________\\
	//                    CSR ACCURACY VERIFICATION                                        \\
	//_____________________________________________________________________________________\\

  // ****************************************************************************
  // Handle any actions passed to the (Control Status Register), eg DUT Enable/Disables 
  // ****************************************************************************
  virtual function void assert_csr_expected_values();
    if (we_mon == 1'b1) begin   // THIS IS A WRITE TO THE CSR
      disable_intr = dat_mon[6];    // We have received a DUT Enable, capture whether interrupt assertions
                                    // Should expect interrupt mode or polling mode.
    end
     begin
      assert_csr_enabled :
      assert (dat_mon[7] == 1'b1)
      else $error("Asssertion assert_csr_enabled failed with %b", dat_mon);   // Expect DUT ENABLED High when In  use

      // Assert that interrupt bit set correctly VS issued wb-commands
      if (disable_intr) begin
        assert_interrupt_bit_high :
        assert (dat_mon[6] == 1'b1)
        else $error("Asssertion assert_interrupt_bit_high failed with %b", dat_mon);
      end else begin
        assert_interrupt_bit_low :
        assert (dat_mon[6] == 1'b0)
        else $error("Asssertion assert_interrupt_bit_low failed with %b", dat_mon);
      end

      // Assert that the Bus Captured and Bus Busy bits are low and high when these states are false and true.
      if (transaction_in_progress) begin    // Captured and busy when transaction in progress
        assert_csr_bc_captured :
        assert (dat_mon[4] == 1'b1)
        else $error("Asssertion assert_bc_captured failed with %b", dat_mon);
        assert_csr_bb_busy :
        assert (dat_mon[5] == 1'b1)
        else $error("Asssertion assert_bb_bus_busy busy failed with %b", dat_mon);
      end 
      else if (!configuration.disable_bus_checking) begin   // Captured -> free but busy as STOP action is resolving.
        assert_csr_bc_free :
        assert (dat_mon[4] == 1'b0)
        else $error("Asssertion assert_bc_free failed with %b", dat_mon);
        assert_csr_bb_free :
        assert (dat_mon[5] == 1'b1)
        else $error("Asssertion assert_bb_bus_busy_free failed with %b", dat_mon);
      end

      // Assert that the Bus Selected Bits are accurate vs the Bus which was selected with WB Commands.
      if (!configuration.disable_bus_checking)
        assert_csr_bus_sel_accuracy :
        assert (dat_mon[3:0] == selected_bus)
        else
          $error("Asssertion assert_csr_bus_sel_accuracy failed with %b vs %b", dat_mon, selected_bus);
    end                          
  endfunction

  //_____________________________________________________________________________________\\
	//                       MODEL THE PORT TO THE FSMR                                    \\
	//_____________________________________________________________________________________\\

  // ****************************************************************************
  // Handle any actions on the FSMR State Register
  // ****************************************************************************
  virtual function void process_fsmr_register_transaction();
    // SWALLOW reads of the debug FSM state register
  endfunction

endclass
