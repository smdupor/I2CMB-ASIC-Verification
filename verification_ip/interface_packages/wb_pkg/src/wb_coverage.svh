class wb_coverage extends ncsu_component#(.T(wb_transaction));

    wb_configuration configuration;
  		
	// Wb coverage
	logic[7:0] cmd_type;
	bit[1:0] reg_type;
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

	wb_stretch_delay:	coverpoint wb_str_del
	{
		bins NONE_0_CYCLES = {0};
		bins SHORT_1_to_100_CYCLES = {[1:100]};
		bins LONG_gt_101_CYCLES = {[101:$]};
	}

	configuration_nacks: coverpoint expect_nacks
	{
		bins SLAVE_CONNECTED = {1'b0};
		bins SLAVE_DISCONNECTED = {1'b1};
	}
	

	nacks:	coverpoint nacks
	{
		bins ACKS = {1'b0};
		bins NACKS = {1'b1};
	}
	
	config_x_nacks:	cross configuration_nacks, nacks
	{

	}

	cmd_type:	coverpoint cmd_type
	{
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

	reg_type:	coverpoint reg_type
	{
		bins CSR = {CSR};
		bins DPR = {DPR};
		bins CMDR = {CMDR};
		bins STATE = {STATE};
	}

	we:		coverpoint we
	{
		bins I2_WRITE = {1'b1};
		bins I2_READ = {1'b0};
	}

	data_type: 	coverpoint data_type
	{
		bins DATA_NIBBLES[64] = {[0:255]};
	}

	we_x_reg: cross we, reg_type
	{
		illegal_bins writes_to_state_illegal = 
  	           binsof(we.I2_WRITE) && 
  	           binsof(reg_type.STATE);
		
	}
  endgroup

  function new(string name = "", ncsu_component #(T) parent = null); 
    super.new(name,parent);
    wb_transaction_cg = new;
	nacks = 1'bx;
	
  endfunction

  function void set_configuration(wb_configuration cfg);
    configuration = cfg;
	expect_nacks = configuration.expect_nacks;
  endfunction

  virtual function void nb_put(T trans);
	reg_type = trans.line;
	expect_nacks = configuration.expect_nacks;
	if(trans.cmd == I2C_WRITE || trans.cmd == READ_WITH_ACK ||
		 trans.cmd == READ_WITH_NACK) begin 
			 data_type = trans.word;
			 cmd_type = NONE;
			 nacks = 1'bx;
		 end
	else begin 
		cmd_type = trans.word;
		if(trans.line==CMDR && !trans.write) nacks = trans.word[6];
		else nacks = 1'bx;
		data_type = NONE;
	end
	we = trans.write;

    wb_transaction_cg.sample();
	wb_str_del = 0;
  endfunction

endclass
