class i2cmb_predictor extends ncsu_component;

	ncsu_component scoreboard;
	ncsu_transaction transport_trans;
	i2cmb_env_configuration configuration;

	function new(string name = "", ncsu_component_base  parent = null);
		super.new(name,parent);
	endfunction

	function void set_configuration(i2cmb_env_configuration cfg);
		configuration = cfg;
	endfunction

	virtual function void set_scoreboard(ncsu_component scoreboard);
		this.scoreboard = scoreboard;
	endfunction

	virtual function void nb_put(ncsu_transaction trans);
		wb_transaction itrans;
		i2c_transaction predicted;
		predicted = new;
		$cast(itrans, trans);
		$display({get_full_name()," ",itrans.convert2string()});


		predicted.address =itrans.address;
		predicted.data =itrans.data;
		predicted.rw =itrans.rw;

		scoreboard.nb_transport(predicted, transport_trans);
	endfunction

endclass
