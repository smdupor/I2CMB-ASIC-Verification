class wb_coverage extends ncsu_component#(.T(wb_transaction));

    wb_configuration configuration;
  		
	// Wb coverage
	wb_cmd_t cmd_type;
	wb_reg_t reg_type;
	bit we;
	wb_mon_t mon_type;
	logic [7:0] data;

  covergroup wb_transaction_cg;
  	option.per_instance = 1;
    option.name = get_full_name();

	cmd_type:	coverpoint cmd_type
	{
		bins ENABLE_CORE_INTERRUPT = {ENABLE_CORE_INTERRUPT};
		bins ENABLE_CORE_POLLING = {ENABLE_CORE_POLLING};
		bins DISABLE_CORE = {DISABLE_CORE};
		bins SET_I2C_BUS = {SET_I2C_BUS};
		bins I2C_START = {I2C_START};
		bins I2C_STOP = {I2C_STOP};
		bins I2C_WRITE = {I2C_WRITE};
		bins READ_WITH_ACK = {READ_WITH_ACK};
		bins READ_WITH_NACK = {READ_WITH_NACK};
	}

	reg_type:	coverpoint reg_type
	{
		bins CSR = {CSR};
		bins DPR = {DPR};
		bins CMDR = {CMDR};
		bins STATE = {STATE;
	}

	we:		coverpoint we
	{
		bins we;
	}

	data: 	coverpoint data
	{
		bins data = {8'h00:8'hff};
	}
  endgroup

  function new(string name = "", ncsu_component #(T) parent = null); 
    super.new(name,parent);
    wb_transaction_cg = new;
  endfunction

  function void set_configuration(abc_configuration cfg);
    configuration = cfg;
  endfunction

  virtual function void nb_put(T trans);
	reg_type = trans.line;
	if(trans.cmd == I2C_WRITE || trans.cmd == READ_WITH_ACK ||
		 trans.cmd == READ_WITH_NACK) begin 
			 data_type = trans.word;
			 cmd_type = NONE;
		 end
	else begin 
		cmd_type = trans.word;
		data_type = NONE;
	end
	we = trans.we;

    wb_transaction_cg.sample();
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