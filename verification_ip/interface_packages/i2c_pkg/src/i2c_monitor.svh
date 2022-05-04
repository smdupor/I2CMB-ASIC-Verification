class i2c_monitor extends ncsu_component #(
    .T(i2c_transaction)
);
  i2c_configuration conf;
  virtual i2c_if bus;

  T monitored_trans;
  ncsu_component #(T) agent;

  bit enable_transaction_viewing;

  // ****************************************************************************
  // Construction, setters and getters
  // ****************************************************************************
  function new(input string name = "", ncsu_component_base parent = null);
    super.new(name, parent);
  endfunction

  function void set_configuration(input i2c_configuration cfg);
    conf = cfg;
  endfunction

  function void set_agent(input ncsu_component#(T) agent);
    this.agent = agent;
  endfunction

  // ****************************************************************************
  // Continuously monitor the I2C Bus, capturing transactions and passing to the 
  // 		agent when a complete transaction is detected
  // ****************************************************************************
  virtual task run();
    bit [7:0] i2mon_addr;
    i2c_op_t i2mon_op;
    bit [7:0] i2mon_data[];
    int i2cmon_bus;
    string s, temp;
    int counter;
    bit nack;
    bit rst;

    s = "";
    forever begin
      // Request transfer info from i2c BFM
      bus.monitor(i2mon_addr, i2mon_op, i2mon_data, i2cmon_bus, nack,rst);
      monitored_trans = new({"i2c_trans(", itoalpha(counter), ")"});  //$sformatf("%0d",counter)});
      monitored_trans.measured_clock = bus.measured_clock[0];
      monitored_trans.contained_nack = nack;
      i2cmon_bus = 15 - i2cmon_bus;
      monitored_trans.set(i2mon_addr, i2mon_data, i2mon_op, i2cmon_bus);
      if (bus.stretch_qty > 0) monitored_trans.clock_stretch_qty = bus.stretch_qty;
      else if (bus.read_stretch_qty > 0) monitored_trans.clock_stretch_qty = bus.read_stretch_qty;
      counter += 1;
      if(!rst) agent.nb_put(monitored_trans); // If not a HARD RESET, send to agent
      print_local_transaction;
    end
  endtask

  // ****************************************************************************
  // Print contents of detected transaction for debug purposes
  // ****************************************************************************
  function void print_local_transaction();
    if (enable_transaction_viewing) begin
      $display(monitored_trans.convert2string_legacy());

      // In the case of a multi-line transfer, print a horizontal rule to make clear where 
      // this transfer transcript message ends
      if (monitored_trans.convert2string_legacy().len > 60) display_hrule;
    end
  endfunction

endclass
