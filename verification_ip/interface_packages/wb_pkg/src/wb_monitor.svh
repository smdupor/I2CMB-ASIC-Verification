	class wb_monitor extends ncsu_component#(.T(wb_transaction));

		wb_configuration  configuration;
		virtual wb_if bus;

		T monitored_trans;
		ncsu_component #(T) agent;

		enum logic[2:0] {M_SET_I2C_BUS=3'b110, M_I2C_START=3'b100, M_I2C_WRITE=3'b001,
			M_I2C_STOP=3'b101, M_READ_WITH_NACK=3'b011, M_READ_WITH_ACK=3'b010} mon;

		function new(input string name = "", ncsu_component_base  parent = null);
			super.new(name,parent);
		endfunction

		function void set_configuration(input wb_configuration cfg);
			configuration = cfg;
		endfunction

		function void set_agent(input ncsu_component#(T) agent);
			this.agent = agent;

		endfunction

		/*virtual task run ();
	//bus.wait_for_reset();
	 forever begin
    monitored_trans = new("monitored_trans");
    if ( enable_transaction_viewing) begin
       monitored_trans.start_time = $time;
    end
    bus.monitor(monitored_trans.header,
                monitored_trans.payload,
                monitored_trans.trailer,
                monitored_trans.delay
                );
    $display("%s wb_monitor::run() header 0x%x payload 0x%p trailer 0x%x delay 0x%x",
             get_full_name(),
             monitored_trans.header, 
             monitored_trans.payload, 
             monitored_trans.trailer, 
             monitored_trans.delay
             );
    agent.nb_put(monitored_trans);
    if ( enable_transaction_viewing) begin
       monitored_trans.end_time = $time;
       monitored_trans.add_to_wave(transaction_viewing_stream);
    end
	// end
endtask*/

		virtual task run();
			static bit transfer_in_progress, print_next_read, address_state, transaction_init;
			static bit [7:0] last_dpr;
			static bit [2:0] adr_mon;
			static bit [7:0] dat_mon;
			static bit  we_mon;
			static bit [7:0] words_transferred[$];
			string s,t;
			forever begin
				// Initiate Wishbone master monitoring no more than once per system clock
				#10 this.bus.master_monitor(adr_mon, dat_mon, we_mon);
				//if(!transaction_init) begin monitored_trans = new("wb_trans"); transaction_init = 1'b1; end
				if(adr_mon == 0) begin
					// Monitor for DUT Enable/Disable
					// SWALLOW THE DUT Enable/Disable Write
				end
				else if(adr_mon == 1) begin // Catch all commands passed to DUT
					last_dpr = dat_mon;
					if(print_next_read) begin // Swallow interrupt reads and print transfers only
						print_next_read = 1'b0;
						words_transferred.push_back(last_dpr);
						$display("\t\t\t\t\t\t\t\tWB_BUS Transfer  READ Data: %d", last_dpr);
					end
				end

				else if(adr_mon == 2) begin

					// Detect start condition and prepare start && address report
					if(dat_mon[2:0] == M_I2C_START && we_mon) begin
						s = "\t\t\t\t\t\t\t\tWB_BUS: Sent START";
						if(transaction_init) begin
							monitored_trans.data=words_transferred;
							words_transferred.delete();
							$display(monitored_trans.convert2string);
						end
						else begin
							monitored_trans = new("wb_trans");
							transaction_init = 1'b1;
						end
						transfer_in_progress = 1'b1;
						address_state = 1'b1;
					end
					// Detect stop condition and immediately report 
					if(dat_mon[2:0] == M_I2C_STOP && we_mon) begin
						$display("\t\t\t\t\t\t\t\tWB_BUS: Sent STOP");
						transaction_init = 1'b0;
						transfer_in_progress = 1'b0;
						monitored_trans.data=words_transferred;
						words_transferred.delete();

						// TODO SEND TRANSACTION TO SUBSCRIBERS
						$display(monitored_trans.convert2string);

					end
					// Determine whether write action is requesting an address transmit,  a write, or a read
					if(dat_mon[2:0] == M_I2C_WRITE && we_mon && !address_state) begin
						words_transferred.push_back(last_dpr);
						$display("\t\t\t\t\t\t\t\tWB_BUS: Transfer WRITE Data : %d", last_dpr);
					end
					else if(dat_mon[2:0] == M_I2C_WRITE && we_mon) begin
						t.itoa(integer'(last_dpr[8:1]));
						monitored_trans.address=last_dpr[8:1];

						if(last_dpr[0]==1'b0) begin
							s = {s," && Address ", t," : req. WRITE"};
							monitored_trans.rw = I2_WRITE;
						end
						else begin
							s = {s," && Address ", t, " : req. READ"};
							monitored_trans.rw = I2_READ;
						end
						$display("%s",s);
						address_state = 1'b0;
					end
					// Detect that we are swallowing an interrupt read for a COMMAND READ and notify statemachine
					if(dat_mon[2:0] == M_READ_WITH_ACK || dat_mon[2:0] == M_READ_WITH_NACK) print_next_read = 1'b1;
				end
				// If verbose debugging, display all command register actions
				//	if(ENABLE_WISHBONE_VERBOSE_DEBUG) $display("[WB] CMDR (%h) Data: %b we: %h", adr_mon, dat_mon, we_mon);

				else begin
					// if verbose debugging, display all non-specific commands outside of prior decision tree
					//if(ENABLE_WISHBONE_VERBOSE_DEBUG) $display("Address: %h Data: %b we: %h", adr_mon, dat_mon, we_mon);
				end
			end


		endtask

	endclass