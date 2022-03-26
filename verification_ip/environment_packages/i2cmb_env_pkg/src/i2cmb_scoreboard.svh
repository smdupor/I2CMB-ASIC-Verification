class i2cmb_scoreboard extends ncsu_component#(.T(ncsu_transaction));
	function new(string name = "", ncsu_component_base  parent = null);
		super.new(name,parent);
	endfunction

	i2c_transaction lhs_trans_in[$], rhs_trans_in[$];
	i2c_transaction passes[$], fails[$];
	i2c_transaction trans_in;
	T trans_out;

	virtual function void nb_transport(input T input_trans, output T output_trans);

		$cast(this.trans_in, input_trans);
		lhs_trans_in.push_back(trans_in);
		output_trans = trans_out;
		check();
	endfunction

	virtual function void nb_put(T trans);
		i2c_transaction chk;

		$cast(chk, trans);
		rhs_trans_in.push_back(chk);
		check();
	endfunction

	function void check();
		i2c_transaction lhs, rhs;
		if(lhs_trans_in.size==0 || rhs_trans_in.size==0) return; // Have arrived at this branch before the other transaction to-be-compared

		lhs=lhs_trans_in.pop_front();
		rhs=rhs_trans_in.pop_front();
		ncsu_info("",{get_full_name()," nb_transport: expected transaction ",lhs.convert2string()},NCSU_LOW);
		ncsu_info("",{get_full_name()," nb_put:       actual   transaction ",rhs.convert2string()},NCSU_LOW);
		if ( lhs.compare(rhs) ) begin
			passes.push_front(lhs);
			ncsu_info("",{get_full_name()," transaction MATCH!"},NCSU_LOW);
		end
		else begin
			ncsu_warning("",{get_full_name()," transaction MISMATCH!","\n nb_transport: expected transaction ",lhs.convert2string(),
				"\n nb_put:       actual   transaction ",rhs.convert2string()});
			fails.push_front(lhs);
		end
	endfunction

	function void report_test_stats();
		display_h_lowbar();

		if(fails.size == 0) $display("\t\tALL TESTS PASSED, %0d tests cases checked.", passes.size);
		else				$display("\t\tTESTS FAILED! %d tests cases failing. TESTS FAILED!", fails.size);

		display_h_lowbar();
	endfunction
endclass