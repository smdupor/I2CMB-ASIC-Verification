class wb_coverage extends ncsu_component #(
    .T(wb_transaction)
);

  wb_configuration configuration;

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

  covergroup wb_stretch_cg;
    option.per_instance = 1;
    option.name = get_full_name();

    wb_stretch_delay: coverpoint wb_str_del {
      bins NONE_0_CYCLES = {0};
      bins SHORT_1_to_100_CYCLES = {[1 : 100]};
      bins LONG_gt_101_CYCLES = {[101 : $]};
    }
    endgroup

  function new(string name = "", ncsu_component#(T) parent = null);
    super.new(name, parent);
   wb_stretch_cg = new;

  endfunction

  function void set_configuration(wb_configuration cfg);
    configuration = cfg;
    expect_nacks  = configuration.expect_nacks;
  endfunction

  virtual function void nb_put(T trans);
      reg_type = trans.line;
    expect_nacks = configuration.expect_nacks;
    if (trans.cmd == I2C_WRITE || trans.cmd == READ_WITH_ACK || trans.cmd == READ_WITH_NACK) begin
      data_type = trans.word;
      cmd_type = NONE;
      nacks = 1'bx;
    end else begin
      cmd_type = trans.word;
      if (trans.line == CMDR && !trans.write) nacks = trans.word[6];
      else nacks = 1'bx;
      data_type = NONE;
    end
    we = trans.write;

    if (configuration.collect_coverage) wb_stretch_cg.sample();
    wb_str_del = 0;
  endfunction

endclass
