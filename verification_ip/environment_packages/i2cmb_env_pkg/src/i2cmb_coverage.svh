class i2cmb_coverage extends ncsu_component#(.T(ncsu_transaction));

	i2cmb_env_configuration     configuration;
	wb_transaction	 coverage_transaction;
	bit enable_display;
	int wb_str_del;

	covergroup coverage_cg;
  		option.per_instance = 1;
    	option.name = get_full_name();
  	endgroup

	  covergroup clockstretch_cg;
		option.per_instance = 1;
    	option.name = get_full_name();
	wb_stretch_delay:	coverpoint wb_str_del;


	  endgroup

	// ****************************************************************************
	// Construction, setters and getters
	// ****************************************************************************
	function void set_configuration(i2cmb_env_configuration cfg);
		configuration = cfg;
	endfunction

	function new(string name = "", ncsu_component_base  parent = null);
		super.new(name,parent);
		coverage_cg = new;
		clockstretch_cg = new;
		enable_display=1'b0;
	endfunction

 	// ****************************************************************************
	// Capture incoming transaction from wb agent (monitor) to manage coverage
	// ****************************************************************************
	virtual function void nb_put(T trans);
		$cast(this.coverage_transaction, trans);
		if(enable_display) $display({get_full_name()," ",coverage_transaction.convert2string()});

	endfunction

endclass
