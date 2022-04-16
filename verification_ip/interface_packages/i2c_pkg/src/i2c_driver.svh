class i2c_driver extends ncsu_component #(
    .T(i2c_transaction)
);

  virtual i2c_if bus;
  i2c_configuration configuration;
  i2c_transaction i2c_trans;
  i2c_rand_cs_transaction i2c_rand_cs;
  i2c_arb_loss_transaction i2c_arb_loss;
  i2c_rand_data_transaction i2c_rand_dat;
  bit arb_loss_complete;

  function new(string name = "", ncsu_component_base parent = null);
    super.new(name, parent);
  endfunction

  function void set_configuration(i2c_configuration cfg);
    configuration = cfg;
  endfunction

  virtual task bl_put(T trans);
    bit [7:0] i2c_driver_buffer[];
    bit transfer_complete;

    if (trans != null) begin
      i2c_trans = trans;
      bus.configure(i2c_trans.address, i2c_trans.selected_bus);
      configuration.flush_next_transaction = i2c_trans.is_hard_reset;
    end

    if (!$cast(i2c_arb_loss, trans)) begin
      if ($cast(i2c_rand_cs, trans)) begin
        if (i2c_rand_cs.rw == I2_WRITE) bus.stretch_qty = i2c_rand_cs.clock_stretch_qty;
        else bus.read_stretch_qty = i2c_rand_cs.clock_stretch_qty;
        ncsu_info("", {get_full_name(), $sformatf(" ---- CLOCK WAS STRETCHED BY %0d SYSTEM CYCLES. ", i2c_rand_cs.clock_stretch_qty)}, NCSU_LOW);
      end
      if ($cast(i2c_rand_dat, trans)) begin
        fork
          bus.wait_for_i2c_transfer(i2c_rand_dat.rw, i2c_driver_buffer);
          if (i2c_trans.rw == I2_READ) bus.provide_read_data(i2c_rand_dat.data, transfer_complete);
        join
        return;
      end


      if (trans != null) begin
        fork
          begin bus.wait_for_i2c_transfer(i2c_trans.rw, i2c_driver_buffer);
           // if(trans.is_hard_reset) bus.wait_for_num_clocks(14);
          end
          begin
          if (i2c_trans.rw == I2_READ) bus.provide_read_data(i2c_trans.data, transfer_complete);
         // if(trans.is_hard_reset) bus.wait_for_num_clocks(14);
          end
        join
      end
    end else begin
      if (i2c_arb_loss.on_read) begin
       // $display("REACHED IN THE DRIVER");
        bus.enable_read_arb = 1'b1;
        fork
          bus.wait_for_i2c_transfer(i2c_arb_loss.rw, i2c_driver_buffer);
          bus.provide_read_data(i2c_arb_loss.data, transfer_complete);
        join_any
        bus.enable_read_arb = 1'b0;
      //  $display("Exiting driver");
      end else if (i2c_arb_loss.on_start) begin
       // $display("DDRIVER START");
        bus.force_arbitration_loss_start();
      //  $display("DDRIVER DONE");
      end else bus.force_arbitration_loss();
    end
  endtask

endclass
