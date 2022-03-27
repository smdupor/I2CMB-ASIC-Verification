class wb_monitor extends ncsu_component#(.T(wb_transaction));

	wb_configuration  configuration;
	virtual wb_if bus;

	T monitored_trans;
	ncsu_component #(T) agent;

	bit enable_transaction_viewing;

	// ****************************************************************************
	// Construction, setters, and getters
	// ****************************************************************************
	function new(input string name = "", ncsu_component_base  parent = null);
		super.new(name,parent);
	endfunction

	function void set_configuration(input wb_configuration cfg);
		configuration = cfg;
	endfunction

	function void set_agent(input ncsu_component#(T) agent);
		this.agent = agent;

	endfunction

	// ****************************************************************************
	// Continuously monitor wishbone bus and pass captured transactions up to the 
	// agent
	// ****************************************************************************
	virtual task run();
		static bit [2:0] adr_mon;
		static bit [7:0] dat_mon;
		static bit  we_mon;

		bus.wait_for_reset();

		forever begin
			monitored_trans = new("wb_mon_trans");
			this.bus.master_monitor(adr_mon, dat_mon, we_mon);
			monitored_trans.line = adr_mon;
			monitored_trans.word = dat_mon;
			monitored_trans.write = we_mon;

			agent.nb_put(monitored_trans);
		end

	endtask

endclass