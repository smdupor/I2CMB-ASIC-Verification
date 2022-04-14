class i2cmb_predictor_regblock extends i2cmb_predictor;

	typedef enum int {DEFAULT_TESTING, ACCESS_CONTROL, CROSSCHECKING } pred_reg_states;

	wb_transaction last_trans[$]; // Keep a historic buffer of recent xations
	const bit [7:0] default_values [4] = {8'h0, 8'h0, 8'b1000_0000, 8'h0};
	bit [7:0] reg_file[4];
	pred_reg_states state;
	int transaction_count;

	// ****************************************************************************
	// Construction, setters, and getters 
	// ****************************************************************************
	function new(string name = "", ncsu_component_base  parent = null);
		super.new(name,parent);
		state = DEFAULT_TESTING;
	endfunction

 	// ****************************************************************************
	// Called from wb_agent, process all incoming monitored wb transactions.
	// ****************************************************************************
	virtual function void nb_put(ncsu_transaction trans);
		wb_transaction itrans;
		
		$cast(itrans, trans); // Grab incoming transaction process

		// Copy incoming transaction data into persistent data structure
		adr_mon = itrans.line;
		dat_mon = itrans.word;
		we_mon = itrans.write;
		is_write = itrans.write;

		//Based on REGISTER Address of received transaction, process transaction data accordingly
		case(adr_mon)
			DEFAULT_TESTING: process_default_testing();
			ACCESS_CONTROL:	process_access_ctrl_testing();
			CROSSCHECKING: process_crosschecking();
		endcase
		++transaction_count;
		last_trans.push_back(itrans);
	endfunction

	function void process_default_testing();

		assert(!we_mon && transaction_count < 4) else $error("REGBLOCK TESTFLOW ERROR, UNEXPECTED WRITE Transaction %0d", transaction_count);

		case(adr_mon)
	
			CSR: assert_csr_enable_defaults: assert(dat_mon == default_values[adr_mon]) 
			else $error("Assertion CSR defaults FAILED! GOT: %b", dat_mon);

		
			DPR: assert_dpr_default_on_enable: assert(dat_mon == default_values[adr_mon])
			else $error("Assertion assert_dpr_default_on_enable failed! GOT: %b", dat_mon);

		
			CMDR: assert_cmdr_default_on_enable: assert(dat_mon == default_values[adr_mon])
			else $error("Assertion assert_cmdr_default_on_enable failed! GOT: %b", dat_mon);
		
			STATE: begin 
				assert_fsmr_default_on_enable: assert(dat_mon == default_values[adr_mon])
				else $error("Assertion assert_fsmr_default_on_enable failed! GOT: %b", dat_mon);
				state = ACCESS_CONTROL;
			end
			endcase

	endfunction

	function void process_access_ctrl_testing();
		if(!we_mon) begin
			assert(transaction_count > 7 && transaction_count < 12) 
			else $error("REGBLOCK TESTFLOW ERROR, ACCESS CONTROL OUT OF BOUNDS, Transaction %0d", transaction_count);
		case(adr_mon)
	
			CSR: assert_csr_ro: assert(dat_mon == default_values[adr_mon]) 
			else $error("Assertion assert_csr_ro FAILED! GOT: %b", dat_mon);

		
			DPR: assert_dpr_ro: assert(dat_mon == default_values[adr_mon])
			else $error("Assertion assert_dpr_ro failed! GOT: %b", dat_mon);

		
			CMDR: assert_cmdr_ro: assert(dat_mon == default_values[adr_mon])
			else $error("Assertion assert_cmdr_ro failed! GOT: %b", dat_mon);
		
			STATE: begin 
				assert_fsmr_ro: assert(dat_mon == default_values[adr_mon])
				else $error("Assertion assert_fsmr_ro failed! GOT: %b", dat_mon);
				state = CROSSCHECKING;
			end
		end
	endfunction

	function void process_crosschecking();
		assert(transaction_count > 13) 
			else $error("REGBLOCK TESTFLOW ERROR, CROSSCHECKING OUT OF BOUNDS, Transaction %0d", transaction_count);
		// Accept the written value into predictor's copy of the register fiile
		if(we_mon) begin
			reg_file[adr_mon] = dat_mon;
		end

		else begin
		case(adr_mon)
			CSR: assert_csr_ro: assert(dat_mon == default_values[adr_mon]) 
			else $error("Assertion assert_csr_ro FAILED! GOT: %b", dat_mon);

		
			DPR: assert_dpr_ro: assert(dat_mon == default_values[adr_mon])
			else $error("Assertion assert_dpr_ro failed! GOT: %b", dat_mon);

		
			CMDR: assert_cmdr_ro: assert(dat_mon == default_values[adr_mon])
			else $error("Assertion assert_cmdr_ro failed! GOT: %b", dat_mon);
		
			STATE: begin 
				assert_fsmr_ro: assert(dat_mon == default_values[adr_mon])
				else $error("Assertion assert_fsmr_ro failed! GOT: %b", dat_mon);
				state = CROSSCHECKING;
			end
		end

	endfunction
 	

endclass
