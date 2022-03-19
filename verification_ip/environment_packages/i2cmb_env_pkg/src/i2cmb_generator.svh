	class generator extends ncsu_component#(.T(i2c_transaction));

		i2c_transaction transaction[10];
		wb_agent wb_agent_handle;
		i2c_agent i2c_agent_handle;
		string trans_name;

		function new(string name = "", ncsu_component_base  parent = null);
			super.new(name,parent);
			/*if ( !$value$plusargs("GEN_TRANS_TYPE=%s", trans_name)) begin
	$display("FATAL: +GEN_TRANS_TYPE plusarg not found on command line");
	$fatal;
end*/
			$display("%m found +GEN_TRANS_TYPE=%s", trans_name);
		endfunction

		virtual task run();
			foreach (transaction[i]) begin
				//	$cast(transaction[i],ncsu_object_factory::create(trans_name));
				//assert (transaction[i].randomize());
				//agent.bl_put(transaction[i]);
				//$display({get_full_name()," ",transaction[i].convert2string()});
			end
		endtask

		function void set_wb_agent(wb_agent agent);
			this.wb_agent_handle = agent;
		endfunction

		function void set_i2c_agent(i2c_agent agent);
			this.i2c_agent_handle = agent;
		endfunction

	endclass