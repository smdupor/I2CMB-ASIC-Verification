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

		gen_creator();
	endfunction

 	// ****************************************************************************
	// Start run() of environment members 
	// ****************************************************************************
	virtual task run();
		env.scbd.verbosity_level = global_verbosity_level;
		gen.verbosity_level = global_verbosity_level;
		env.run();
		gen.run();
		env.scbd.report_test_stats();
	endtask

	function void gen_creator();
		string test_name;
		if ( !$value$plusargs("GEN_TRANS_TYPE=%s", test_name)) begin
			$display("FATAL: +GEN_TRANS_TYPE plusarg not found on command line");
			$fatal;
		end
		
		if(!$cast(gen,ncsu_object_factory::create(test_name))) begin
			$error("TESTNAME Not found by factory"); $fatal;
		end

		gen.set_wb_agent(env.get_wb_agent());
		gen.set_i2c_agent(env.get_i2c_agent());
	endfunction
endclass