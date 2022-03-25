class i2cmb_predictor extends ncsu_component;

	ncsu_component scoreboard;
	ncsu_transaction transport_trans;
	i2cmb_env_configuration configuration;
	int counter;

	function new(string name = "", ncsu_component_base  parent = null);
		super.new(name,parent);
	endfunction

	function void set_configuration(i2cmb_env_configuration cfg);
		configuration = cfg;
	endfunction

	virtual function void set_scoreboard(ncsu_component scoreboard);
		this.scoreboard = scoreboard;
	endfunction

	virtual function void nb_put(ncsu_transaction trans);
		wb_transaction itrans;
		static i2c_transaction monitored_trans;
		static bit transfer_in_progress, print_next_read, address_state, transaction_init;
		static bit [7:0] last_dpr;
		static bit [2:0] adr_mon;
		static bit [7:0] dat_mon;
		static bit  we_mon;
		static bit [7:0] words_transferred[$];
		string s,t;

		$cast(itrans, trans);

		adr_mon=itrans.line;
		dat_mon=itrans.word;
		we_mon=itrans.write;

		if(adr_mon == 0) begin
			// Monitor for DUT Enable/Disable
			// SWALLOW THE DUT Enable/Disable Write
		end
		else if(adr_mon == 1) begin // Catch all commands passed to DUT
			last_dpr = dat_mon;
			if(print_next_read) begin // Swallow interrupt reads and print transfers only
				print_next_read = 1'b0;
				words_transferred.push_back(last_dpr);
				if(enable_transaction_viewing) $display("\t\t\t\t\t\t\t\tWB_BUS Transfer  READ Data: %d", last_dpr);
			end
		end

		else if(adr_mon == 2) begin

			// Detect start condition and prepare start && address report
			if(dat_mon[2:0] == M_I2C_START && we_mon) begin
				s = "\t\t\t\t\t\t\t\tWB_BUS: Sent START";
				if(transaction_init) begin
					monitored_trans.data=words_transferred;
					words_transferred.delete();
					if(enable_transaction_viewing) $display(monitored_trans.convert2string);
				end
				else begin
					monitored_trans = new({"i2c_trans(", itoalpha(counter),")"}); //$sformatf("%0d",counter)});
					counter +=1;
					//monitored_trans = new("wb_trans");
					transaction_init = 1'b1;
				end
				transfer_in_progress = 1'b1;
				address_state = 1'b1;
			end
			// Detect stop condition and immediately report 
			if(dat_mon[2:0] == M_I2C_STOP && we_mon) begin
				if(enable_transaction_viewing) $display("\t\t\t\t\t\t\t\tWB_BUS: Sent STOP");
				transaction_init = 1'b0;
				transfer_in_progress = 1'b0;
				monitored_trans.data=words_transferred;
				words_transferred.delete();

				// TODO SEND TRANSACTION TO SUBSCRIBERS
				scoreboard.nb_transport(monitored_trans,transport_trans);

				if(enable_transaction_viewing) $display(monitored_trans.convert2string);

			end
			// Determine whether write action is requesting an address transmit,  a write, or a read
			if(dat_mon[2:0] == M_I2C_WRITE && we_mon && !address_state) begin
				words_transferred.push_back(last_dpr);
				if(enable_transaction_viewing) $display("\t\t\t\t\t\t\t\tWB_BUS: Transfer WRITE Data : %d", last_dpr);
			end
			else if(dat_mon[2:0] == M_I2C_WRITE && we_mon) begin
				t.itoa(integer'(last_dpr[7:1]));
				monitored_trans.address=last_dpr[7:1];

				if(last_dpr[0]==1'b0) begin
					s = {s," && Address ", t," : req. WRITE"};
					monitored_trans.rw = I2_WRITE;
				end
				else begin
					s = {s," && Address ", t, " : req. READ"};
					monitored_trans.rw = I2_READ;
				end
				if(enable_transaction_viewing) $display("%s",s);
				address_state = 1'b0;
			end
			// Detect that we are swallowing an interrupt read for a COMMAND READ and notify statemachine
			if(dat_mon[2:0] == M_READ_WITH_ACK || dat_mon[2:0] == M_READ_WITH_NACK) print_next_read = 1'b1;
		end
		// If verbose debugging, display all command register actions
		//	if(ENABLE_WISHBONE_VERBOSE_DEBUG) if(enable_transaction_viewing) $display("[WB] CMDR (%h) Data: %b we: %h", adr_mon, dat_mon, we_mon);

		else begin
			// if verbose debugging, display all non-specific commands outside of prior decision tree
			//if(ENABLE_WISHBONE_VERBOSE_DEBUG) if(enable_transaction_viewing) $display("Address: %h Data: %b we: %h", adr_mon, dat_mon, we_mon);
		end

	endfunction

endclass
