class coverage extends ncsu_component#(.T(ncsu_transaction));

	i2cmb_env_configuration     configuration;
	wb_transaction	 coverage_transaction;
	bit enable_display;

	function void set_configuration(i2cmb_env_configuration cfg);
		configuration = cfg;
	endfunction

	function new(string name = "", ncsu_component_base  parent = null);
		super.new(name,parent);
		enable_display=1'b0;
	endfunction

	virtual function void nb_put(T trans);
		$cast(this.coverage_transaction, trans);
		if(enable_display) $display({get_full_name()," ",coverage_transaction.convert2string()});
	endfunction

endclass
