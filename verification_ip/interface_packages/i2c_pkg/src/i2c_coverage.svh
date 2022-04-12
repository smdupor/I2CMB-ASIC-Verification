class i2c_coverage extends ncsu_component#(.T(i2c_transaction));

    i2c_configuration configuration;
  		
	// i2c coverage
	logic [7:0] data;
	logic [7:0] address;
	i2c_op_t 	operation;
	int  bus_sel;
	int stretch_qty;
	int msg_size;
	logic is_restart;

  covergroup i2c_transaction_cg;
  	option.per_instance = 1;
    option.name = get_full_name();


	bus_sel:	coverpoint bus_sel
	{
		bins SELECTED[] = {[0:15]};
	}
	
	data: coverpoint data
	{
		bins data_nibbles[64] = {[0:255]};
	}
	address: coverpoint address
	{
		bins address[] = {[0:127]};
	}
	operation: coverpoint operation
	{
		bins I2_WRITE = {I2_WRITE};
		bins I2_READ = {I2_READ};
	}
	operation_x_address: cross operation, address
	{

	}
	operation_x_data: cross operation, data
	{

	}

	msg_size:	coverpoint msg_size
	{
		bins NO_DATA = {0};
		bins SINGLE_BYTE = {1};
		bins MULTI_BYTE = {[2:$]};
	}

	msg_size_x_operation: 	cross msg_size, operation
	{
		illegal_bins I2_READ_NODATA =  binsof(msg_size.NO_DATA) && 
  	           binsof(operation.I2_READ);
	}

  endgroup

	 covergroup clockstretch_cg;
		option.per_instance = 1;
    	option.name = get_full_name();
	i2c_stretch_delay:	coverpoint stretch_qty
	{
		bins DISABLED = {0};
		bins SHORT = {[1000:5000]};
		bins MEDIUM = {[5001:10000]};
		bins LONG = {[10001:20000]};
	}

	bus_select: coverpoint bus_sel
	{
		bins BUSSES[] = {[0:15]};
	}
	stretch_x_bus_sel: cross i2c_stretch_delay, bus_select;

  endgroup

  function new(string name = "", ncsu_component #(T) parent = null); 
    super.new(name,parent);
    i2c_transaction_cg = new;
	clockstretch_cg = new;
  endfunction

  function void set_configuration(i2c_configuration cfg);
    configuration = cfg;
  endfunction

  virtual function void nb_put(T trans);
	address = trans.address;
	operation = trans.rw;
	stretch_qty = trans.clock_stretch_qty;
	bus_sel = trans.selected_bus;
	msg_size = trans.data.size();
	is_restart = trans.is_restart;

	i2c_transaction_cg.sample();
	clockstretch_cg.sample();
	
	foreach(trans.data[i]) begin
		data = trans.data[i];
	    i2c_transaction_cg.sample();
	end
  endfunction

endclass

