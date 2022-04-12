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
				
			if(!configuration.expect_arb_loss) agent.nb_put(monitored_trans);
		end

	endtask

	task check_command_assertions();
		static T temp;
		temp =new;
		if(configuration.expect_arb_loss) return;

		if(last_trans[0] != null && last_trans[0].line == CMDR && last_trans[0].write && !monitored_trans.write) begin// && monitored_trans.line==CMDR) begin 	//	The last transaction was a command, and we are clearing the interrupt
			//	$display(last_trans[1].convert2string());
		//		$display("Elapsed Cycle: %0d", bus.num_clocks);
				bus.num_clocks = 0;
				if(last_trans[0].word[2:0] != M_READ_WITH_NACK && last_trans[0].word[2:0] != M_READ_WITH_ACK) begin
					//$display("HIT ASSERT");
					assert_done_raised_on_complete: assert (monitored_trans.word[7]==1'b1)				// Done Bit was raised signaling complete
					else $error("Assertion assert_done_raised_on_complete failed!, got word: %b", monitored_trans.word);

					assert_nacks_when_expected: assert(monitored_trans.word[5]==configuration.expect_nacks)
					else $error("Assertion assert_nacks_when_expected failed!");

					if(!configuration.expect_arb_loss) begin
						assert_arbitration_won: assert(monitored_trans.word[6]==1'b0)
						else $error("Assertion assert_arbitration_won failed!");
					end
				/*if(monitored_trans.word[2:0] == M_SET_I2C_BUS) begin
					this.bus.master_read(CSR, temp.word);
					assert_bus_id_match: assert(temp.word[3:0]==last_trans[0].word[3:0])			// Captured Bus matches selected bus
					else $error("Assertion assert_bus_id_match failed!");


				end 
				else if ( last_trans[0].word[2:0] == M_I2C_START ) begin
					this.bus.master_read(CSR, temp.word);

					
					assert_bc_on_bus_capture: assert(temp.word[4]==1'b0)							// Bus capture bit raised on capture
					else $error("Assertion assert_bc_on_bus_capture failed!");
				end*/

				end 

		end

		// Check register default values on a DUT-enable
		else if (monitored_trans.line == CSR && monitored_trans.write) begin
			this.bus.master_read(CSR, temp.word);												//CSR Defaults
			assert_csr_enable_defaults: assert(temp.word[7:6] == monitored_trans.word[7:6]) 
			//[7] == monitored_trans.word[7] && temp.word[6] == monitored_trans.word[6])
			else $error("Assertion CSR defaults FAILED! GOT: %b   %b    %b    %b", temp.word[7:6], temp.word[6], monitored_trans.word[7:6], monitored_trans.word[6]);

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
endclass