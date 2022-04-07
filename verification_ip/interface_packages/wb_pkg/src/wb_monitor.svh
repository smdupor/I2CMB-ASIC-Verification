class wb_monitor extends ncsu_component#(.T(wb_transaction));

	

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
			
			check_command_assertions();
				
			agent.nb_put(monitored_trans);
		end

	endtask

	task check_command_assertions();
		static T temp;
		temp =new;
		if(last_trans[0] != null)
		if(last_trans[0].line == CMDR && last_trans[0].write && !monitored_trans.write) begin// && monitored_trans.line==CMDR) begin 	//	The last transaction was a command, and we are clearing the interrupt
				//this.bus.master_read(STATE, temp.word);
				$display("Assert block last %b word %b     this  %b word %b ",last_trans[0].line, last_trans[0].word, monitored_trans.line, monitored_trans.word );
				assert_fsm_byte_match_last_cmd: assert (1'b1==1'b1)//(temp.word[6:4]==last_trans[0].word[2:0])		// FSM Byte Command Match 
				else $error("Assertion assert_fsm_byte_match failed!");
				if(last_trans[0].word[2:0] != M_READ_WITH_NACK && last_trans[0].word[2:0] != M_READ_WITH_ACK) begin
					assert_done_raised_on_complete: assert (monitored_trans.word[7]==1'b1)				// Done Bit was raised signaling complete
					else $error("Assertion assert_done_raised_on_complete failed!, got word: %b", monitored_trans.word);
				end 
				if(last_trans[0].word == SET_I2C_BUS) begin
					this.bus.master_read(CSR, temp.word);
					assert_bus_id_match: assert(temp.word[3:0]==last_trans[1].word[3:0])			// Captured Bus matches selected bus
					else $error("Assertion assert_bus_id_match failed!");

					assert_bc_on_bus_capture: assert(temp.word[4]==1'b1)							// Bus capture bit raised on capture
					else $error("Assertion assert_bc_on_bus_capture failed!");
				end 
				else if (last_trans[0].word == I2C_START || last_trans[0].word == I2C_WRITE || last_trans[0].word == READ_WITH_ACK ) begin
					this.bus.master_read(CSR, temp.word);
					assert_bb_during_transaction: assert(temp.word[5]==1'b1)						// Bus Busy during transaction
					else $error("Assertion assert_bb_during_transaction failed!");
				end
		end

		// Check register default values on a DUT-enable
		else if (monitored_trans.line == CSR && monitored_trans.word[7]==1'b1 && monitored_trans.write == I2_WRITE) begin
			this.bus.master_read(CSR, temp.word);												//CSR Defaults
			assert_csr_enable_defaults: assert(temp.word[7:6] == monitored_trans[7:6])
			else $error("Assertion csr_intr_disable!");

			this.bus.master_read(DPR, temp.word);												// DPR Default
			assert_dpr_default_on_enable: assert(temp.word == 8'b0)
			else $error("Assertion assert_dpr_default_on_enable failed!");

			this.bus.master_read(CMDR, temp.word);
			assert_cmdr_default_on_enable: assert(temp.word == 8'b1000_0000)					// CMDR Default
			else $error("Assertion assert_cmdr_default_on_enable failed!");

			this.bus.master_read(STATE, temp.word);
			assert_fsmr_default_on_enable: assert(temp.word == 8'h0)
			else $error("Assertion assert_fsmr_default_on_enable failed!");

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