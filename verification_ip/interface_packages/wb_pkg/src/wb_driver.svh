class wb_driver extends ncsu_component #(
    .T(wb_transaction)
);

  function new(string name = "", ncsu_component_base parent = null);
    super.new(name, parent);
  endfunction

  virtual wb_if bus;
  wb_configuration configuration;
  wb_transaction wb_trans;
  wb_transaction_arb_loss wb_arb_trans;
  bit dut_enable;
  logic [7:0] tf_buffer;

  // ****************************************************************************
  //  Construction, Setters and Getters
  // ****************************************************************************
  function void set_configuration(wb_configuration cfg);
    configuration = cfg;
  endfunction


  // ****************************************************************************
  // Issue a received transaction to the DUT 
  // ****************************************************************************
  virtual task bl_put(T trans);
    bit [7:0] buffer;
    wb_trans = trans;
    bus.wait_for_reset();

    if ($cast(wb_arb_trans, trans)) begin
      ncsu_info("\n", {"Reached Arbitration Loss transaction ", trans.convert2string()}, NCSU_HIGH);
      bl_arb_put(wb_arb_trans);
      return;
    end

    //Enable assertion detecting NO Interrupt signal when disabled
    if (wb_trans.write && wb_trans.line == CSR && wb_trans.word[7] == 1'b0)
      bus.disable_interrupts = 1'b1;
    else bus.disable_interrupts = 1'b0;

    ncsu_info("\n", {get_full_name(), " ", trans.convert2string()}, NCSU_HIGH);

    if (wb_trans.write) begin
      if (wb_trans.line == CMDR || wb_trans.line == CSR)
        bus.master_write(wb_trans.line, wb_trans.cmd);
      if (wb_trans.line == DPR || wb_trans.line == FSMR)
        bus.master_write(wb_trans.line, wb_trans.word);
      if (wb_trans.wait_int_ack) bus.wait_interrupt();
      if (wb_trans.wait_int_nack) bus.wait_interrupt();
      if (wb_trans.stall_cycles > 0) bus.wait_for_num_clocks(wb_trans.stall_cycles);
    end else begin
      if (wb_trans.line == CMDR || wb_trans.line == CSR) bus.master_read(wb_trans.line, buffer);
      if (wb_trans.line == DPR || wb_trans.line == FSMR) bus.master_read(wb_trans.line, buffer);
      if (wb_trans.wait_int_ack) bus.wait_interrupt();
      if (wb_trans.wait_int_nack) bus.wait_interrupt();
      if (wb_trans.stall_cycles > 0) bus.wait_for_num_clocks(wb_trans.stall_cycles);

    end
  endtask

  // Test Arbitration LOSS condition
  task bl_arb_put(wb_transaction_arb_loss wb_arb);
    bit [7:0] buffer;
    assert (wb_arb.write);

    if (wb_arb.line == CMDR || wb_arb.line == CSR) bus.master_write(wb_arb.line, wb_arb.cmd);
    if (wb_arb.line == DPR) bus.master_write(wb_arb.line, wb_arb.word);
    #250 while (buffer[7:5] == 3'b000) #50 bus.master_read(CMDR, buffer);
    assert_require_arb_loss_bit :
    assert (buffer[5] == 1'b1)
    else $error("Assertion assert_require_arb_loss_bit failed with %b!", buffer);

    if (buffer[5])
      ncsu_info("\n", {
                get_full_name(),
                $sformatf(
                    " ARBITRATION LOSS ATTEMPTED: CMDR REPORTED: %b : ARBITRATION WAS LOST", buffer
                )
                }, NCSU_LOW);

    bus.master_read(CSR, buffer);
    assert_bb_during_transaction :
    assert (buffer[5] == 1'b1)  // Bus Busy during transaction
    else $error("Assertion assert_bb_during_transaction failed!");
  endtask
endclass
