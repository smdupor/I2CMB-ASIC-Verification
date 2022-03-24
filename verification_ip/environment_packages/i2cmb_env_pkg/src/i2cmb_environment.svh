class i2cmb_environment extends ncsu_component#(.T(i2c_transaction));

	i2cmb_env_configuration configuration;
	wb_agent         wb_agent_handle;
	i2c_agent		i2c_agent_handle;
	i2cmb_predictor         pred;
	i2cmb_scoreboard        scbd;
	coverage          coverage;

	function new(string name = "", ncsu_component_base  parent = null);
		super.new(name,parent);
	endfunction

	function void set_configuration(i2cmb_env_configuration cfg);
		configuration = cfg;
	endfunction

	virtual function void build();
		wb_agent_handle = new("wb_agent",this);
		wb_agent_handle.set_configuration(configuration.wb_agent_config);
		wb_agent_handle.build();
		i2c_agent_handle = new("i2c_agent",this);
		i2c_agent_handle.set_configuration(configuration.i2c_agent_config);
		i2c_agent_handle.build();
		pred  = new("pred", this);
		pred.set_configuration(configuration);
		pred.build();
		scbd  = new("scbd", this);
		scbd.build();
		coverage = new("coverage", this);
		coverage.set_configuration(configuration);
		coverage.build();
		wb_agent_handle.connect_subscriber(coverage);
		wb_agent_handle.connect_subscriber(pred);
		pred.set_scoreboard(scbd);
		i2c_agent_handle.connect_subscriber(scbd);
	endfunction

	function wb_agent get_wb_agent();
		return wb_agent_handle;
	endfunction

	function i2c_agent get_i2c_agent();
		return i2c_agent_handle;
	endfunction

	virtual task run();
		wb_agent_handle.run();
		i2c_agent_handle.run();
	endtask

endclass