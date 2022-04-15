class i2cmb_coverage extends ncsu_component #(
    .T(ncsu_transaction)
);

  i2cmb_env_configuration configuration;
  wb_transaction          coverage_transaction;
  bit                     enable_display;
  
  
  // Wb coverage
  logic [7:0] cmd_type;
  bit [1:0] reg_type;
  bit we;
  logic nacks;
  logic expect_nacks;
  int wb_str_del;

  //wb_mon_t mon_type;
  logic [7:0] data_type;
  logic [3:0] wait_time;

covergroup wb_transaction_cg;
    option.per_instance = 1;
    option.name = get_full_name();

    configuration_nacks: coverpoint expect_nacks {
      bins SLAVE_CONNECTED = {1'b0}; bins SLAVE_DISCONNECTED = {1'b1};
    }


    nacks: coverpoint nacks {bins ACKS = {1'b0}; bins NACKS = {1'b1};}

    config_x_nacks: cross configuration_nacks, nacks{
      illegal_bins CONNECTED_NACKS_SLV_MUST_ALWAYS_ACK = binsof(configuration_nacks.SLAVE_CONNECTED) && binsof(nacks.NACKS);
    }

    cmd_type: coverpoint cmd_type {
      bins ENABLE_CORE_INTERRUPT = {8'b11000000};
      bins ENABLE_CORE_POLLING = {8'b10000000};
      bins DISABLE_CORE = {8'b0000_0000};
      bins SET_I2C_BUS = {8'b0000_0110};
      bins I2C_START = {8'b0000_0100};
      bins I2C_STOP = {8'b0000_0101};
      bins I2C_WRITE = {8'b0000_0001};
      bins READ_WITH_ACK = {8'b0000_0011};
      bins READ_WITH_NACK = {8'b0000_0010};
      bins WAIT_COMMAND = {8'b0000_0000};
    }

    reg_type: coverpoint reg_type {bins CSR = {CSR}; bins DPR = {DPR}; bins CMDR = {CMDR};}

    we: coverpoint we {bins I2_WRITE = {1'b1}; bins I2_READ = {1'b0};}

    data_type: coverpoint data_type {bins DATA_NIBBLES[64] = {[0 : 255]};}

    we_x_reg: cross we, reg_type{}
  endgroup



  // ****************************************************************************
  // Construction, setters and getters
  // ****************************************************************************
  function void set_configuration(i2cmb_env_configuration cfg);
    configuration = cfg;
  endfunction

  function new(string name = "", ncsu_component_base parent = null);
    super.new(name, parent);
    nacks = 1'bx;
    wb_transaction_cg = new;
    //collect_coverage = 1'b1;
    expect_nacks = 1'b0;

  endfunction

  // ****************************************************************************
  // Capture incoming transaction from wb agent (monitor) to manage coverage
  // ****************************************************************************
  virtual function void nb_put(T trans);
    
    $cast(coverage_transaction, trans);
      reg_type = coverage_transaction.line;
    expect_nacks = configuration.expect_nacks;
    if (coverage_transaction.cmd == I2C_WRITE || coverage_transaction.cmd == READ_WITH_ACK || coverage_transaction.cmd == READ_WITH_NACK) begin
      data_type = coverage_transaction.word;
      cmd_type = NONE;
      nacks = 1'bx;
    end else begin
      cmd_type = coverage_transaction.word;
      if (coverage_transaction.line == CMDR && !coverage_transaction.write) nacks = coverage_transaction.word[6];
      else nacks = 1'bx;
      data_type = NONE;
    end
    we = coverage_transaction.write;

    if(configuration.collect_coverage) wb_transaction_cg.sample();
    wb_str_del = 0;
  endfunction

endclass
