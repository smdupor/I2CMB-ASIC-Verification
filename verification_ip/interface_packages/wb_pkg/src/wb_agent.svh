class wb_agent extends ncsu_component#(.T(wb_transaction));
	parameter int WB_ADDR_WIDTH = 2;
	parameter int WB_DATA_WIDTH = 8;

	wb_configuration configuration;
	wb_transaction_arb_loss arb_trans;
	wb_coverage		 coverage;
	wb_driver        driver;
	wb_monitor       monitor;
	ncsu_component subscribers[$];
	virtual wb_if  bus;
	virtual wb_if  bus1;

	// ****************************************************************************
	// Construction, Setters, and getters
	// ****************************************************************************
	function new(string name = "", ncsu_component_base  parent = null);
		super.new(name,parent);
		if ( !(ncsu_config_db#(virtual wb_if)::get("tst.env.wb_agent", this.bus))) begin;
			$display("wb_agent::ncsu_config_db::get() call for BFM handle failed for name: %s ",get_full_name());
			$finish;
		end
		if ( !(ncsu_config_db#(virtual wb_if)::get("tst.env.wb_agent_1", this.bus1))) begin;
			$display("wb_agent::ncsu_config_db::get() call for BFM handle failed for name: %s ",get_full_name());
			$finish;
		end
	endfunction

	function void set_configuration(wb_configuration cfg);
		configuration = cfg;
	endfunction

	virtual function void build();
		driver = new("driver",this);
		driver.set_configuration(configuration);
		driver.build();
		driver.bus = this.bus;
		driver.bus_1 = this.bus1;
		monitor = new("monitor",this);
		monitor.set_configuration(configuration);
		monitor.set_agent(this);
		monitor.enable_transaction_viewing = 0;
		monitor.build();
		monitor.bus = this.bus;
		coverage=new();
		coverage.set_configuration(configuration);
		connect_subscriber(coverage);
	endfunction

	// ****************************************************************************
	// Handle transactions coming from the monitor and pass to all subscriber
	// ****************************************************************************
	virtual function void nb_put(T trans);
		foreach (subscribers[i]) subscribers[i].nb_put(trans);
	endfunction

	// ****************************************************************************
	// Handle transactions from generator and pass to driver
	// ****************************************************************************
	virtual task bl_put(T trans);
		if($cast(arb_trans, trans)) begin
			fork 
				driver.bl_put(arb_trans);
		 	join_none
		end
		else driver.bl_put(trans);
	endtask

	// ****************************************************************************
	// Observer subscriber management
	// ****************************************************************************
	virtual function void connect_subscriber(ncsu_component subscriber);
		subscribers.push_back(subscriber);
	endfunction

	// ****************************************************************************
	// Fork off the monitor task to monitor bus
	// ****************************************************************************
	virtual task run();
		fork monitor.run(); join_none
	endtask

	function void expect_nacks(bit expectation);
		configuration.expect_nacks = expectation;
	endfunction

endclass


