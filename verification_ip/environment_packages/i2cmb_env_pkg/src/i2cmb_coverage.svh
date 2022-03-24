	class coverage extends ncsu_component#(.T(ncsu_transaction));

		i2cmb_env_configuration     configuration;
		wb_transaction	 coverage_transaction;
		bit enable_display;
		/*header_type_t         header_type;
  bit                   loopback;
  bit                   invert;

  covergroup coverage_cg;
  	option.per_instance = 1;
    option.name = get_full_name();
    header_type: coverpoint header_type;
    loopback:    coverpoint loopback;
    invert:      coverpoint invert;
    header_x_loopback: cross header_type, loopback;
    header_x_invert:   cross header_type, invert;
  endgroup*/

		function void set_configuration(i2cmb_env_configuration cfg);
			configuration = cfg;
		endfunction

		function new(string name = "", ncsu_component_base  parent = null);
			super.new(name,parent);
			enable_display=1'b0;
			//coverage_cg = new;
		endfunction

		virtual function void nb_put(T trans);
			$cast(this.coverage_transaction, trans);
			if(enable_display) $display({get_full_name()," ",coverage_transaction.convert2string()});
			/*header_type = header_type_t'(trans.header[63:60]);
    loopback    = configuration.loopback;
    invert      = configuration.invert;
    coverage_cg.sample();*/
		endfunction

	endclass
	