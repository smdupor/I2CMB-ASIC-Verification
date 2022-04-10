class wb_configuration extends ncsu_configuration;
	bit collect_coverage;
	bit expect_nacks;
	bit expect_arb_loss;
	
	function new(string name="");
		super.new(name);
		this.collect_coverage=1'b0;
	endfunction

	virtual function string convert2string();
		return {super.convert2string};
	endfunction

endclass