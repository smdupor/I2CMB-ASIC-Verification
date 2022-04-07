class i2c_coverage extends ncsu_component#(.T(i2c_transaction));

    i2c_configuration configuration;
  		
	// i2c coverage
	logic [7:0] data;
	logic [7:0] address;
	i2c_op_t 	operation;

  covergroup i2c_transaction_cg;
  	option.per_instance = 1;
    option.name = get_full_name();


		// TODO: Missing Bus Select
	data: coverpoint data
	{
		//bins data = {8'h00:8'hff};
	}
	address: coverpoint address
	{
		//bins address = {8'h00:8'hff};
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
  endgroup

  function new(string name = "", ncsu_component #(T) parent = null); 
    super.new(name,parent);
    i2c_transaction_cg = new;
  endfunction

  function void set_configuration(i2c_configuration cfg);
    configuration = cfg;
  endfunction

  virtual function void nb_put(T trans);
	address = trans.address;
	operation = trans.rw;
	i2c_transaction_cg.sample();
	
	foreach(trans.data[i]) begin
		data = trans.data[i];
	    i2c_transaction_cg.sample();
	end
  endfunction

endclass

  	/*header_type:     coverpoint header_type
  	{
  	bins ROUTING_TABLE = {ROUTING_TABLE};
  	bins STATISTICS = {STATISTICS};
  	bins PAYLOAD = {PAYLOAD};
  	bins SECURE_PAYLOAD = {SECURE_PAYLOAD};
  	}

  	header_sub_type: coverpoint header_sub_type
  	{
  	bins CONTROL = {CONTROL};
  	bins DATA = {DATA};
  	bins RESET = {RESET};
  	}

  	trailer_type:    coverpoint trailer_type
  	{
  	bins ZEROS = {ZEROS};
  	bins ONES = {ONES};
  	bins SYNC = {SYNC};
  	bins PARITY = {PARITY};
  	bins ECC = {ECC};
  	bins CRC = {CRC};  	
  	} 

  	header_x_header_sub: cross header_type, header_sub_type
  	  {
  	   illegal_bins routing_table_sub_types_illegal = 
  	           binsof(header_type.ROUTING_TABLE) && 
  	           binsof(header_sub_type.DATA);
  	   illegal_bins payload_sub_types_illegal = 
  	           binsof(header_type.PAYLOAD) && 
  	           ( binsof(header_sub_type.CONTROL) || 
  	           	 binsof(header_sub_type.RESET));
  	   illegal_bins secure_payload_sub_types_illegal = 
  	           binsof(header_type.SECURE_PAYLOAD) && 
  	           binsof(header_sub_type.RESET);
  	  }

  	  header_x_trailer: cross header_type, trailer_type;*/