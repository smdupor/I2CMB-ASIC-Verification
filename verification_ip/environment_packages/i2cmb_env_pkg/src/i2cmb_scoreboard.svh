class i2cmb_scoreboard extends ncsu_component;
	function new(string name = "", ncsu_component_base  parent = null);
		super.new(name,parent);
	endfunction

	i2c_transaction trans_in;
	ncsu_transaction trans_out;

	virtual function void nb_transport(input ncsu_transaction input_trans, output ncsu_transaction output_trans);
		$display({get_full_name()," nb_transport: expected transaction ",input_trans.convert2string()});
		$cast(this.trans_in, input_trans);
		output_trans = trans_out;
	endfunction

	virtual function void nb_put(ncsu_transaction trans);
		i2c_transaction chk;
		$display({get_full_name()," nb_put: actual transaction ",trans.convert2string()});
		$cast(chk, trans);
		if ( this.trans_in.compare(chk) ) $display({get_full_name()," abc_transaction MATCH!"});
		else                                $display({get_full_name()," abc_transaction MISMATCH!"});
	endfunction
endclass