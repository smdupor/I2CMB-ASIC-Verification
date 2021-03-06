class i2cmb_env_configuration extends ncsu_configuration;

	wb_configuration wb_agent_config;
	i2c_configuration i2c_agent_config;
	string trans_name;
	bit disable_bus_checking;
	bit disable_interrupts;
	int address_shift;
	bit expect_nacks;
	bit disable_predictor;
	bit disable_scoreboard;
	bit enable_error_testing;
	bit collect_coverage;
	bit expect_bus_mismatch;
    bit register_testing;
	bit expect_arb_loss;
	
	
	// ****************************************************************************
	//	Constructor, setters and getters 
	// ****************************************************************************
	function new(string name="");
		super.new(name);

		if ( !$value$plusargs("GEN_TRANS_TYPE=%s", trans_name)) begin
			$display("FATAL: +GEN_TRANS_TYPE plusarg not found on command line");
			$fatal;
		end

		wb_agent_config = new("wb_agent_config");
		if(trans_name == "i2cmb_generator_test_multi_bus_ranged") begin
			wb_agent_config.dut_select="tst.env.wb_agent_16_ranged";
		end else if(trans_name == "i2cmb_generator_test_single_bus") begin
			wb_agent_config.dut_select="tst.env.wb_agent_1_max";
			wb_agent_config.expect_bus_mismatch = 1'b1;
		end

		address_shift=0;
		i2c_agent_config = new("i2c_agent_config");
		collect_coverage = 1'b1;
    	expect_bus_mismatch = 1'b0;
    	register_testing = 1'b0;
	endfunction

	function void disable_coverage();
		wb_agent_config.collect_coverage = 1'b0;
		this.collect_coverage = 1'b0;
		disable_scoreboard = 1'b1;
	endfunction

	function void enable_register_testing();
		wb_agent_config.register_testing = 1'b1;
	endfunction

	// ****************************************************************************
	// Environment Coverage management
	// ****************************************************************************
	function void sample_coverage();
		// TODO: Sample coverage once coverage is implemented
	endfunction
	function void set_address_shift(int s);
		this.address_shift = s;
	endfunction
	function int get_address_shift();
		return this.address_shift;
	endfunction

endclass