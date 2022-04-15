class i2cmb_predictor extends ncsu_component;

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
  bit capture_next_read, expect_i2c_address, transaction_in_progress;
  int transaction_counter;
  int most_recent_wait;             // From an explicit WAIT command
  i2c_op_t cov_op;                  // This I2C Operation for coverage purposes
  logic is_restart;                 // Whether this operation was a START or RESTART
  int selected_bus;                 // The bus of this I2C Transaction
  bit is_write;                     // bit-formatted I2C Operation

  //Coverage switches
  bit disable_bus_checking;         // Bus addresses from WB **WILL** be purposely mismatched, correct when enabled.
  bit disable_intr;                 // DUT Configured with Interrupts OFF

  // Cover wait values here, as the main Coverage module cannot "remember" past states
  // in an effective manner such that it can monitor the values from WAIT commands
  covergroup wait_cg;
    option.per_instance = 1;
    option.name = get_full_name();
    explicit_wait_times: coverpoint most_recent_wait {
      bins SHORT_1_to_2ms = {[1 : 2]};
      bins MED_3ms_to_5ms = {[3 : 5]};
      bins LONG_6s_to_8ms = {[6 : 8]};
    }
  endgroup

  // Cover operations vs start/restarts here, because the main coverage module
  // does not have "oracle" knowledge of whether the past transaction was 
  // concluded with a STOP (hence, this is a START) or, concluded
  // without sending STOP, hence this is a RE-START.
  covergroup predictor_cg;
    option.per_instance = 1;
    option.name = get_full_name();
    operation: coverpoint cov_op {bins I2_WRITE = {I2_WRITE}; bins I2_READ = {I2_READ};}
    start_or_restart: coverpoint is_restart {bins START = {0}; bins RESTART = {1};}
    restart_x_operation: cross operation, start_or_restart;
  endgroup

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

  // ****************************************************************************
  // Handle any actions passed to the (Command Register), CDMDR
  // ****************************************************************************
  virtual function void process_cmdr_transaction();
    if (is_write) begin
      if (dat_mon[2:0] == M_WB_WAIT) begin  // Handle injected wait commands regardless of FSM state
        most_recent_wait = last_dpr;
        wait_cg.sample();
      end
      case (state)
        RESET: begin // Illegal Write
        end
        DISABLED: begin // Illegal Write
        end
        IDLE: begin  // DUT ENABLED AND IDLE
          if (dat_mon[2:0] == M_I2C_START) begin
            process_start_transaction();          // Incoming trans indicated START
            state = START_ISSUED_WAIT_DONE;
          end

          if (dat_mon[2:0] == M_WB_WAIT) begin
            most_recent_wait = last_dpr;          //Incoming trans indicated WAIT
            wait_cg.sample();
            state = EXPLICIT_WAIT_WAITING;
          end
         if (dat_mon[2:0] == M_SET_I2C_BUS) begin selected_bus = last_dpr; // A bus select was run without first emplacing a new bus num
          state = BUS_SEL_WAIT_DONE; 
          end
        end
        BUS_NUM_EMPLACED: begin  
          if (dat_mon[2:0] == M_SET_I2C_BUS) selected_bus = last_dpr;   // A  bus select is being executed
          state = BUS_SEL_WAIT_DONE;
        end
        BUS_SEL_WAIT_DONE: begin  // Illegal write
        end
        START_ISSUED_WAIT_DONE: begin  // Illegal write
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
        ADDRESS_WAIT_DONE: begin // Illegal Write
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
        WRITE_WAIT_DONE: begin  // Illegal Write
        end
        READ_ACK_WAIT_DONE: begin  // Illegal	Write
        end
        READ_NACK_WAIT_DONE: begin  // Illegal Write
        end
        READ_DATA_READY: begin // A Legal action, but will destroy the data in the DPR that was just received from a remote slave.
        end
        EXPLICIT_WAIT_WAITING: begin // Illegal Write
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
          if (dat_mon[DONE]) begin                                        // An explict WAIT has completed, ensure that the 
            wait_cg.sample();                                             // value of this WAIT is sampled, and clear the 
            most_recent_wait = 0;                                         // Long-term storage value
            state = IDLE;
          end
        end
      endcase
  endfunction

  // ****************************************************************************
  // Handle any actions passed to the (Control Status Register) CSR
  // ****************************************************************************
  virtual function void process_csr_transaction();
    if (is_write) begin
      if (dat_mon[ENBL]) begin                        // CSR has been written to enable/disable the DUT
        state = IDLE;
        disable_intr = dat_mon[INTR];                 // Decide whether or not to use interrupts or poll the DONE bit.
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

  // ****************************************************************************
  // Handle any actions passed to the (Data/Parameter Register), CDMDR
  // ****************************************************************************
  virtual function void process_dpr_transaction();
    if (is_write) begin
      last_dpr = dat_mon;
      case (state)
        RESET: begin  // Initial State
          // illegal		
        end
        DISABLED: begin  // DUT Manually disabled
          // illegal
        end
        IDLE: begin  // DUT ENABLED AND IDLE
          selected_bus = dat_mon;
          state   = BUS_NUM_EMPLACED;
        end
        BUS_NUM_EMPLACED: begin  
          selected_bus = dat_mon;
          state   = BUS_NUM_EMPLACED;
        end
        BUS_SEL_WAIT_DONE: begin  
          // Illegal
        end
        START_ISSUED_WAIT_DONE: begin  
          // Illegal										
        end
        START_DONE: begin  
          monitored_trans.address = last_dpr[7:1];  // Extract the Address
          monitored_trans.address += configuration.get_address_shift();
          if (monitored_trans.address > 127)
            monitored_trans.address = 0 + configuration.get_address_shift() - 1;
          if (last_dpr[0] == 1'b0) begin
            monitored_trans.rw = I2_WRITE;  // Address Transmit was requesting a write
            state = ADDRESS_EMPLACED_WRITE;
          end else begin
            monitored_trans.rw = I2_READ;  // Address Transmit was requesting a read
            state              = ADDRESS_EMPLACED_READ;
          end
          //expect_i2c_address = 1'b0;								// Indicate that the address has been captured and next transaction will carry data
          cov_op = monitored_trans.rw;
        end
        ADDRESS_EMPLACED_READ: begin  //Write after Write
          monitored_trans.address = last_dpr[7:1];  // Extract the Address
          if (last_dpr[0] == 1'b0) begin
            monitored_trans.rw = I2_WRITE;  // Address Transmit was requesting a write
            state = ADDRESS_EMPLACED_WRITE;
          end else begin
            monitored_trans.rw = I2_READ;  // Address Transmit was requesting a read
            state              = ADDRESS_EMPLACED_READ;
          end
          //expect_i2c_address = 1'b0;								// Indicate that the address has been captured and next transaction will carry data
          cov_op = monitored_trans.rw;
        end

        ADDRESS_EMPLACED_WRITE: begin  // Write after write
          monitored_trans.address = last_dpr[7:1];  // Extract the Address
          if (last_dpr[0] == 1'b0) begin
            monitored_trans.rw = I2_WRITE;  // Address Transmit was requesting a write
            state = ADDRESS_EMPLACED_WRITE;
          end else begin
            monitored_trans.rw = I2_READ;  // Address Transmit was requesting a read
            state              = ADDRESS_EMPLACED_READ;
          end
          //expect_i2c_address = 1'b0;								// Indicate that the address has been captured and next transaction will carry data
          cov_op = monitored_trans.rw;
        end

        ADDRESS_WAIT_DONE: begin  
          // Illegal				
        end
        TRANSACTION_IN_PROG_IDLE: begin	// Transaction is happening, but a complete address is done or a complete read/write is done.
          state = BYTE_EMPLACED_WRITE;
        end
        BYTE_EMPLACED_WRITE: begin  
          state = BYTE_EMPLACED_WRITE;
        end
        WRITE_WAIT_DONE: begin  
          // Illegal
        end
        READ_ACK_WAIT_DONE: begin  
          // Illegal							
        end
        READ_NACK_WAIT_DONE: begin  
          // Illegal			
        end
        READ_DATA_READY: begin
          // Legal But data destructive
        end
        EXPLICIT_WAIT_WAITING: begin  //TBD
          // Illegal							
        end
      endcase
    end else  // THIS IS A READ TO DPR
      case (state)
        RESET: begin  // Initial State
          // DEFAULT Value check							
        end
        DISABLED: begin  // DUT Manually disabled
          // DEFAULT Value check	
        end
        IDLE: begin  // DUT ENABLED AND IDLE
          // Value check	
        end
        BUS_NUM_EMPLACED: begin  
          // Value check	
        end
        BUS_SEL_WAIT_DONE: begin  
          // Value check	
        end
        START_ISSUED_WAIT_DONE: begin  
          // Value check		
        end
        START_DONE: begin  
          // Value check		
        end
        ADDRESS_EMPLACED_READ: begin  
          // Value check					
        end
        ADDRESS_EMPLACED_WRITE: begin  
          // Value check				
        end
        ADDRESS_WAIT_DONE: begin  
          // Value check		
        end
        TRANSACTION_IN_PROG_IDLE: begin	// Transaction is happening, but a complete address is done or a complete read/write is done.
          // Value check		
        end
        BYTE_EMPLACED_WRITE: begin  
          // Value check		
        end
        WRITE_WAIT_DONE: begin  
          // Value check	
        end
        READ_ACK_WAIT_DONE: begin  
          // Value check							
        end
        READ_NACK_WAIT_DONE: begin  
          // Value check					
        end
        READ_DATA_READY: begin

          words_transferred.push_back(
              dat_mon);  // Which Contains data write action, capture the data
          state = TRANSACTION_IN_PROG_IDLE;
        end
        EXPLICIT_WAIT_WAITING: begin  //TBD
          // Value check									
        end
      endcase

  endfunction

  // ****************************************************************************
  // Handle a START or a RE-START action 
  // ****************************************************************************
  function void process_start_transaction();
    is_restart = 1'b0;
    if (transaction_in_progress) begin
      is_restart           = 1'b1;  // Detect a re-start condition,
      monitored_trans.data = words_transferred;  // conclude last transaction 
      words_transferred.delete();
      predictor_cg.sample();
      wait_cg.sample();
      //most_recent_wait = 0;						// and pass data from it to scoreboard
      scoreboard.nb_transport(monitored_trans, transport_trans);
    end
    // Then, Create a new Transaction
    monitored_trans = new({"i2c_trans(", itoalpha(transaction_counter++), ")"});
    monitored_trans.selected_bus = selected_bus;
    //if(most_recent_wait > 0) begin
    //monitored_trans.explicit_wait_ms = most_recent_wait;
    //most_recent_wait = 0;
    //	end
    transaction_in_progress = 1'b1;  // Advise state machine that a transaction is now in progress
    expect_i2c_address = 1'b1; 									// Advise state machine that the next transaction should contain an I2C address
  endfunction

  // ****************************************************************************
  // Handle a STOP action 
  // ****************************************************************************
  function void process_stop_transaction();
    transaction_in_progress = 1'b0;  // Advise state machine that transactions are concluded.
    monitored_trans.data = words_transferred;  // Copy complete dataset into monitored transaction
    words_transferred.delete();
    predictor_cg.sample();
    wait_cg.sample();
    most_recent_wait = 0;  // Clear predictor buffer
    scoreboard.nb_transport(monitored_trans,
                            transport_trans);  // Send completed transaction to scoreboard
  endfunction

  // ****************************************************************************
  // Handle an action dealing with an I2C Address and the expected operation 
  // (I2C_READ or I2C_WRITE)
  // ****************************************************************************
  function void process_address_transaction();
    monitored_trans.address = last_dpr[7:1];  // Extract the Address
    if (last_dpr[0] == 1'b0)
      monitored_trans.rw = I2_WRITE;  // Address Transmit was requesting a write
    else monitored_trans.rw = I2_READ;  // Address Transmit was requesting a read
    expect_i2c_address = 1'b0;									// Indicate that the address has been captured and next transaction will carry data
    cov_op = monitored_trans.rw;
  endfunction


  // ****************************************************************************
  // Handle any actions passed to the (Control Status Register), eg DUT Enable/Disables 
  // ****************************************************************************
  virtual function void assert_csr_expected_values();
    if (we_mon == 1'b0) begin
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
      if (transaction_in_progress) begin
        assert_csr_bc_captured :
        assert (dat_mon[4] == 1'b1)
        else $error("Asssertion assert_bc_captured failed with %b", dat_mon);
        assert_csr_bb_busy :
        assert (dat_mon[5] == 1'b1)
        else $error("Asssertion assert_bb_bus_busy busy failed with %b", dat_mon);
      end else if (!configuration.disable_bus_checking) begin
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
    end else begin
      disable_intr = dat_mon[6];    // IMPORTANT! We have received a DUT Enable, capture whether
    end                             // It was configured to use interrupts or not.
  endfunction

  // ****************************************************************************
  // Handle any actions on the State Register
  // ****************************************************************************
  virtual function void process_fsmr_register_transaction();
    // SWALLOW reads of the debug state register
  endfunction

endclass
