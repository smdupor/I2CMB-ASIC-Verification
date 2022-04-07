class i2cmb_test extends ncsu_component#(.T(i2c_transaction));

	i2cmb_env_configuration  cfg;
	i2cmb_environment        env;
	i2cmb_generator        	 gen;

	// ****************************************************************************
	// Create test members (configuration, environment, generator)
	// ****************************************************************************
	function new(string name = "", ncsu_component_base parent = null);
		super.new(name,parent);
		cfg = new("cfg");
		cfg.sample_coverage();
		env = new("env",this);
		env.set_configuration(cfg);
		env.build();
		gen = new("gen",this);
		gen.set_wb_agent(env.get_wb_agent());
		gen.set_i2c_agent(env.get_i2c_agent());
	endfunction

 	// ****************************************************************************
	// Start run() of environment members 
	// ****************************************************************************
	virtual task run();
		env.run();
		gen.run();
		env.scbd.report_test_stats();
	endtask

endclass