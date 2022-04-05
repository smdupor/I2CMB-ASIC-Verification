class wb_monitor extends ncsu_component#(.T(wb_transaction));

	import wb_types_pkg::*;

	wb_configuration  configuration;
	virtual wb_if bus;

	T monitored_trans;
	T last_trans [2];
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
			last_trans[1] = last_trans[0];
			last_trans[0] = monitored_trans;
			monitored_trans = new("wb_mon_trans");
			this.bus.master_monitor(adr_mon, dat_mon, we_mon);
			monitored_trans.line = adr_mon;
			monitored_trans.word = dat_mon;
			monitored_trans.write = we_mon;
			
			if(last_trans.adr_mon == CMDR)
				
			agent.nb_put(monitored_trans);
		end

	endtask

	task check_command_assertions();
		static T temp;
		if(monitored_trans.adr == CMDR && monitored_trans.dat_mon[2:0] == M_I2C_START && monitored_trans.we == I2_READ) begin
				this.bus.master_read(STATE, temp.word);

				assert_fsm_byte_match_last_cmd: assert (temp.word[2:0]==monitored_trans.dat_mon[2:0])
				else $error("Assertion assert_fsm_byte_match failed!");
		end

	endtask
	/*
	assert_csr_done_on_intr

assert_bb_during_transaction
assert_bc_on_bus_capture
assert_bus_id_match

assert_csr_intr_disable
assert_csr_intr_enable
assert_dpr_default_on_enable
assert_cmdr_default_on_enable
assert_fsm_byte_match_last_cmd
*/
endclass