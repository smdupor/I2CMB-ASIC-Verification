class wb_configuration extends ncsu_configuration;
	bit collect_coverage;
	bit expect_nacks;
	bit expect_arb_loss;
	string dut_select;
	
	function new(string name="");
		super.new(name);
		dut_select="tst.env.wb_agent_16_max";
		this.collect_coverage=1'b0;
		expect_nacks = 1'b0;
	endfunction

	virtual function string convert2string();
		return {super.convert2string};
	endfunction

endclass