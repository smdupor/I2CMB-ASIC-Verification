class i2c_agent extends ncsu_component#(.T(i2c_transaction));

	i2c_configuration configuration;
	i2c_coverage 		coverage;
	i2c_driver        driver;
	i2c_monitor       monitor;
	ncsu_component subscribers[$];
	virtual i2c_if    bus;

	// ****************************************************************************
	// Construction, setters and getters
	// ****************************************************************************
	function new(string name = "", ncsu_component_base  parent = null);
		super.new(name,parent);
		if ( !(ncsu_config_db#(virtual i2c_if)::get(get_full_name(), this.bus))) begin;
			$display("i2c_agent::ncsu_config_db::get() call for BFM handle failed for name: %s ",get_full_name());
			$finish;
		end
	endfunction

	function void set_configuration(i2c_configuration cfg);
		configuration = cfg;
	endfunction

	virtual function void build();
		driver = new("driver",this);
		driver.set_configuration(configuration);
		driver.build();
		driver.bus = this.bus;
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
		driver.bl_put(trans);
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

endclass


