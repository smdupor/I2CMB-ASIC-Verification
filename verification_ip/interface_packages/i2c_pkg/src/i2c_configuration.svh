class i2c_configuration extends ncsu_configuration;

  const int i2c_addr_width;
  const int i2c_data_width;
  bit sample_clockstretch_coverage;
  int override_bus_select;
  bit override_bus_enable;
  bit flush_next_transaction;

  function new(string name = "");
    super.new(name);
    i2c_addr_width = 8;
    i2c_data_width = 8;
  endfunction

  virtual function string convert2string();
    return {super.convert2string};
  endfunction

endclass
