class i2cmb_environment extends ncsu_component#(.T(i2c_transaction));

	i2cmb_env_configuration configuration;
	wb_agent         wb_agent_handle;
	i2c_agent		i2c_agent_handle;
	i2cmb_predictor         pred;
	i2cmb_predictor_regblock pred_reg;
	i2cmb_scoreboard        scbd;
	i2cmb_coverage          coverage;
	string trans_name;

	// ****************************************************************************
	// Construction, setters and getters
	// ****************************************************************************
	function new(string name = "", ncsu_component_base  parent = null);
		super.new(name,parent);
	endfunction

	function void set_configuration(i2cmb_env_configuration cfg);
		configuration = cfg;
	endfunction

	// ****************************************************************************
	// Build the environment and connect all subscribers 
	// ****************************************************************************
	virtual function void build();
		wb_agent_handle = new("wb_agent",this);
		wb_agent_handle.set_configuration(configuration.wb_agent_config);
		wb_agent_handle.build();
		i2c_agent_handle = new("i2c_agent",this);
		i2c_agent_handle.set_configuration(configuration.i2c_agent_config);
		i2c_agent_handle.build();
		if ( !$value$plusargs("GEN_TRANS_TYPE=%s", trans_name)) begin
				$display("FATAL: +GEN_TRANS_TYPE plusarg not found on command line");
				$fatal;
			end
		if(trans_name == "i2cmb_generator_test_reg") begin
			pred_reg = new("pred", this);
			pred = pred_reg;
		end 
		else pred  = new("pred", this);
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

	// ****************************************************************************
	// Start both environment agent run tasks when environment is run()
	// ****************************************************************************
	virtual task run();
		wb_agent_handle.run();
		i2c_agent_handle.run();
	endtask

endclass