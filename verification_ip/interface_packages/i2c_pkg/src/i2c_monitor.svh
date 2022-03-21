class i2c_monitor extends ncsu_component#(.T(i2c_transaction));


	i2c_configuration  conf;
	virtual i2c_if bus;

	T monitored_trans;
	ncsu_component #(T) agent;

	function new(input string name = "", ncsu_component_base  parent = null);
		super.new(name,parent);
	endfunction

	function void set_configuration(input i2c_configuration cfg);
		conf = cfg;
	endfunction

	function void set_agent(input ncsu_component#(T) agent);
		this.agent = agent;

	endfunction

	virtual task run ();
		bit[7:0] i2mon_addr;
		i2c_op_t i2mon_op;
		bit [7:0] i2mon_data [];
		int i2cmon_bus;
		string s,temp;
		int counter;

		s = "";
		forever begin
			// Request transfer info from i2c BFM
			bus.monitor(i2mon_addr, i2mon_op, i2mon_data, i2cmon_bus);

			monitored_trans = new({"i2c_trans:", $sformatf("%d",counter)});
			monitored_trans.set(i2mon_addr, i2mon_data,i2mon_op,i2cmon_bus);
			counter +=1;

			agent.nb_put(monitored_trans);

			print_local_transaction;

			// TODO SEND TRANSACTION TO SUBSCRIBERS


		end
	endtask

	function void print_local_transaction();
		$display(monitored_trans.convert2string_legacy());

		// In the case of a multi-line transfer, print a horizontal rule to make clear where 
		// this transfer transcript message ends
		if(monitored_trans.convert2string_legacy().len>60) display_hrule;

	endfunction

endclass