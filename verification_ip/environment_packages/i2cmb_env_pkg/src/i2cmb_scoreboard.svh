class i2cmb_scoreboard extends ncsu_component #(
    .T(ncsu_transaction)
);
  i2c_transaction lhs_trans_in[$], rhs_trans_in[$];
  i2c_transaction passes[$], fails[$];
  i2c_transaction trans_in;
  T trans_out;
  int count_pred, count_bfm;

  function new(string name = "", ncsu_component_base parent = null);
    super.new(name, parent);
    verbosity_level = global_verbosity_level;
    count_pred = 0;
    count_bfm = 0;
  endfunction

  // ****************************************************************************
  // Called from the Predictor, to capture predicted transactions
  // ****************************************************************************
  virtual function void nb_transport(input T input_trans, output T output_trans);
    $cast(this.trans_in, input_trans);
    lhs_trans_in.push_back(trans_in);  // Catch transaction and store it for checking
    output_trans = trans_out;
    check();  // Pass control to checker
  endfunction

  // ****************************************************************************
  // Called from the I2C Monitor, to capture actual DUT transactions 
  // ****************************************************************************
  virtual function void nb_put(T trans);
    i2c_transaction chk;
    $cast(chk, trans);
    rhs_trans_in.push_back(chk);  // Catch transaction and store it for checking
    check();  // Pass control to checker
  endfunction

  // ****************************************************************************
  // Check whether received transactions are matching (test pass) or not (test fail)
  // Only run checks when transactions have been received from both ends of the 
  //		testbench.
  // ****************************************************************************
  function void check();
    i2c_transaction lhs, rhs;
    if (lhs_trans_in.size == 0 || rhs_trans_in.size == 0)
      return;  // Guard against arrived at this branch before the other transaction to-be-compared

    // Check the match on the transactions
    lhs = lhs_trans_in.pop_front();
    rhs = rhs_trans_in.pop_front();
    ncsu_info("", {get_full_name(), " nb_transport: expected transaction ", lhs.convert2string()},
              NCSU_MEDIUM);
    ncsu_info("", {get_full_name(), " nb_put:       actual   transaction ", rhs.convert2string()},
              NCSU_MEDIUM);

    // Check Passed
    if (lhs.compare(rhs)) begin
      passes.push_front(lhs);
      ncsu_info("", {get_full_name(), " transaction MATCH!"}, NCSU_MEDIUM);
    end  // Check Failed
    else begin
      ncsu_error("", {
                 get_full_name(),
                 " transaction MISMATCH!",
                 "\n nb_transport: expected transaction ",
                 lhs.convert2string(),
                 "\n nb_put:       actual   transaction ",
                 rhs.convert2string()
                 });
      fails.push_front(lhs);
    end
  endfunction

  // ****************************************************************************
  // Print report of pass/fail rate across all test cases in entire simulation run. 
  // ****************************************************************************
  function void report_test_stats();
    display_h_lowbar();
    if (passes.size == 0 && fails.size == 0)
      $display("\t\tTests complete. There were NO scoreboarded transactions this run.");
    else if (fails.size == 0)
      $display("\t\tALL TESTS PASSED, %0d tests cases checked.", passes.size);
    else $display("\t\tTESTS FAILED! %d tests cases failing. TESTS FAILED!", fails.size);

    display_h_lowbar();
  endfunction
endclass
