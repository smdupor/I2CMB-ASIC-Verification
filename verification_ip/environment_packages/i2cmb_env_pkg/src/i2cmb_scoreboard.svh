class i2cmb_scoreboard extends ncsu_component;
	function new(string name = "", ncsu_component_base  parent = null);
		super.new(name,parent);
	endfunction

	i2c_transaction lhs_trans_in[$], rhs_trans_in[$];
	i2c_transaction trans_in;
	ncsu_transaction trans_out;

	virtual function void nb_transport(input ncsu_transaction input_trans, output ncsu_transaction output_trans);
		$display({get_full_name()," nb_transport: expected transaction ",input_trans.convert2string()});
		$cast(this.trans_in, input_trans);
		lhs_trans_in.push_back(trans_in);
		output_trans = trans_out;
		check();
	endfunction

	virtual function void nb_put(ncsu_transaction trans);
		i2c_transaction chk;
		$display({get_full_name()," nb_put: actual transaction ",trans.convert2string()});
		$cast(chk, trans);
		rhs_trans_in.push_back(chk);
		check();
	endfunction

	function void check();
		i2c_transaction lhs, rhs;
		if(lhs_trans_in.size==0 || rhs_trans_in.size==0) return;
		lhs=lhs_trans_in.pop_front();
		rhs=rhs_trans_in.pop_front();
		if ( lhs.compare(rhs) ) $display({get_full_name()," transaction MATCH!"});
		else                                $display({get_full_name()," transaction MISMATCH!"});
	endfunction
endclass