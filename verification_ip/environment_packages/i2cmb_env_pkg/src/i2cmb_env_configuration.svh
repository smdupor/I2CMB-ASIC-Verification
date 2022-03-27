class i2cmb_env_configuration extends ncsu_configuration;

	wb_configuration wb_agent_config;
	i2c_configuration i2c_agent_config;

	// ****************************************************************************
	//	Constructor, setters and getters 
	// ****************************************************************************
	function new(string name="");
		super.new(name);
		wb_agent_config = new("wb_agent_config");
		i2c_agent_config = new("i2c_agent_config");
	endfunction

	// ****************************************************************************
	// Environment Coverage management
	// ****************************************************************************
	function void sample_coverage();
		// TODO: Sample coverage once coverage is implemented
	endfunction

endclass