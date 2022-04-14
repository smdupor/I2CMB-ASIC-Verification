class i2cmb_generator_arb_loss extends i2cmb_generator;
		
`ncsu_register_object(i2cmb_generator_arb_loss);

		// ****************************************************************************
		// Constructor, setters and getters
		// ****************************************************************************
		function new(string name = "", ncsu_component_base  parent = null);
			super.new(name,parent);
			if ( !$value$plusargs("GEN_TRANS_TYPE=%s", trans_name)) begin
				$display("FATAL: +GEN_TRANS_TYPE plusarg not found on command line");
				$fatal;
			end

			$display("%m found +GEN_TRANS_TYPE=%s", trans_name);
			if(trans_name == "i2cmb_generator_arb_loss") begin
				trans_name="i2c_arb_loss_transaction";
			end
			else if(trans_name != "i2cmb_test_multi_bus_range" || trans_name == "i2c_arb_loss_transaction") begin $fatal; end
			else begin
				trans_name = "i2c_rand_cs_transaction";
			end
			verbosity_level = global_verbosity_level;
		endfunction

		// ****************************************************************************
		// run the transaction generator; Create all transactions, then, pass trans-
		//		actions to agents, in order, in parallel. 
		// ****************************************************************************
		virtual task run();
			generate_arb_loss_reads();
			generate_arb_loss_flow();
			//92.12, 94.11, 82.25
			//arb_loss_start();
						//92.12, 94.11, 82.25	// Both one flow
			//91.14, 91.17, 82.25, 86.85 // Reads removed
			//92.12, 94.11, 82.25, 87.03
			wb_agent_handle.configuration.expect_arb_loss = 1'b1;

			// Iterate through all generated transactions, passing each down to respective agents.
			fork
				foreach(i2c_trans[i]) i2c_agent_handle.bl_put(i2c_trans[i]);
				begin foreach(wb_trans[i]) begin
						wb_agent_handle.bl_put(wb_trans[i]);
						if(wb_trans[i].en_printing) ncsu_info("",{get_full_name(),wb_trans[i].to_s_prettyprint},NCSU_HIGH); // Print only pertinent WB transactions per project spec.
						
					end
					#10000 $finish();
				end
			join
			

		endtask

		function void generate_arb_loss_flow();
			int i=0;

			for(i=0;i<=15;++i) begin
				enable_dut_with_interrupt();
				//issue_wait(1);
				if(!$cast(trans,ncsu_object_factory::create(trans_name))) $display({"\n\nTRANS CAST FAILED\n\n", trans.convert2string()});
				// pick  a bus, sequentially picking a new bus for each major transaction
				trans.selected_bus=i;

				select_I2C_bus(trans.selected_bus);

				// Send a start command
				//arb_loss_start();
				issue_start_command();
				// pick an address
				trans.address = 127;

				arb_loss_address_req_write(trans.address);
				disable_dut();
				i2c_trans.push_back(trans);
				i2c_trans.push_back(trans);
			end
			
		endfunction

		// Ensure that a read with NAK can be terminated with an arb loss
		function void generate_arb_loss_reads();
			i2c_arb_loss_transaction trans;
			bit [7:0] init_data[$];
		
			int i;
			init_data.delete();

			
				enable_dut_with_interrupt();
				//issue_wait(1);
				if(!$cast(trans,ncsu_object_factory::create(trans_name))) $display({"\n\nTRANS CAST FAILED\n\n", trans.convert2string()});
				// pick  a bus, sequentially picking a new bus for each major transaction
				trans.selected_bus=i;
				trans.set_arb_read();
				trans.rw=I2_READ;
				init_data.push_back(8'b0101_1010);
				trans.data = init_data;
				select_I2C_bus(trans.selected_bus);

				// Send a start command
				//arb_loss_start();
				issue_start_command();
				// pick an address
				trans.address = 127;

				transmit_address_req_read(trans.address);
				arb_loss_read_data_byte_with_stop();
				disable_dut();
				i2c_trans.push_back(trans);
			
		endfunction


		function void arb_loss_start();
		//master_write(CMDR, I2C_START);
		wb_transaction_arb_loss t = new("send_start_command");
		t.write = 1'b1;
		t.line = CMDR;
		t.word=8'b0;
		t.cmd=I2C_START;
		t.wait_int_nack=1'b0;
		t.wait_int_ack=1'b0;
		t.stall_cycles=0;
		t.label("SEND START");
		wb_trans.push_back(t);

		//wait_interrupt();
		clear_interrupt();
	endfunction

		function void arb_loss_address_req_write(input bit [7:0] addr);
		//master_write(DPR, addr);
		wb_transaction_arb_loss u;
		wb_transaction t = new("emplace_address_req_write");
		addr = addr << 1;
		addr[0]=1'b0;
		t.write = 1'b1;
		t.line = DPR;
		t.word=addr;
		t.cmd=NONE;
		t.wait_int_nack=1'b0;
		t.wait_int_ack=1'b0;
		t.stall_cycles=0;
		t.label("SEND ADDRESS REQ WRITE");
		wb_trans.push_back(t);


		//master_write(CMDR, I2C_WRITE);
		u = new("trigger_address_transmission_arb");
		u.write = 1'b1;
		u.line = CMDR;
		u.word=8'b0;
		u.cmd=I2C_WRITE;
		u.wait_int_nack=1'b1;
		u.wait_int_ack=1'b0;
		u.stall_cycles=0;
		wb_trans.push_back(u);

		//wait_interrupt_with_NACK(); // In case of a down/unresponsive slave, we'd get a nack	
		clear_interrupt();
	endfunction

			function void arb_loss_address_req_read(input bit [7:0] addr);
		//master_write(DPR, addr);
		wb_transaction_arb_loss u;
		wb_transaction t = new("emplace_address_req_write");
		addr = addr << 1;
		addr[0]=1'b1;
		t.write = 1'b1;
		t.line = DPR;
		t.word=addr;
		t.cmd=NONE;
		t.wait_int_nack=1'b0;
		t.wait_int_ack=1'b0;
		t.stall_cycles=0;
		t.label("SEND ADDRESS REQ WRITE");
		wb_trans.push_back(t);


		//master_write(CMDR, I2C_WRITE);
		u = new("trigger_address_transmission_arb");
		u.write = 1'b1;
		u.line = CMDR;
		u.word=8'b0;
		u.cmd=I2C_WRITE;
		u.wait_int_nack=1'b1;
		u.wait_int_ack=1'b0;
		u.stall_cycles=0;
		wb_trans.push_back(u);

		//wait_interrupt_with_NACK(); // In case of a down/unresponsive slave, we'd get a nack	
		clear_interrupt();
	endfunction

	// ****************************************************************************
	// READ a single byte of data from a previously-addressed I2C Slave,
	//      Indicating that this is the LAST BYTE of this transfer, and the next
	// 		bus action will be a STOP signal.
	// Check to ensure we didn't get a NACK/ Got the ACK from the slave.
	// ****************************************************************************
	function void arb_loss_read_data_byte_with_stop();
		//master_write(CMDR, READ_WITH_NACK);
		wb_transaction_arb_loss t = new("trigger_final_byte_read");
		t.write = 1'b1;
		t.line = CMDR;
		t.word=8'b0;
		t.cmd=READ_WITH_NACK;
		if(!enable_polling) begin
		t.wait_int_nack=1'b1;
		t.wait_int_ack=1'b0;
		t.stall_cycles=0;
		end else begin
		t.wait_int_nack=1'b0;
		t.wait_int_ack=1'b0;
		t.stall_cycles=0;
		end 
		t.label("READ BYTE");
		wb_trans.push_back(t);

/*		//wait_interrupt_with_NACK();
		clear_interrupt();

		//	master_read(DPR, iobuf);
		t = new("retrieve_data_post_read");
		t.write = 1'b0;
		t.line = DPR;
		t.word=8'b0;
		t.cmd=NONE;
		t.wait_int_nack=1'b0;
		t.wait_int_ack=1'b0;
		t.stall_cycles=0;
		wb_trans.push_back(t);*/
	endfunction	
	
	// ****************************************************************************
	// READ a single byte of data from a previously-addressed I2C Slave,
	//      Indicating that this is the LAST BYTE of this transfer, and the next
	// 		bus action will be a STOP signal.
	// Check to ensure we didn't get a NACK/ Got the ACK from the slave.
	// ****************************************************************************
	/*function void arb_loss_read_data_byte_with_stop();
		//master_write(CMDR, READ_WITH_NACK);
		wb_transaction t = new("trigger_final_byte_read");
		t.write = 1'b1;
		t.line = CMDR;
		t.word=8'b0;
		t.cmd=READ_WITH_NACK;
		if(!enable_polling) begin
		t.wait_int_nack=1'b1;
		t.wait_int_ack=1'b0;
		t.stall_cycles=0;
		end else begin
		t.wait_int_nack=1'b0;
		t.wait_int_ack=1'b0;
		t.stall_cycles=data_pause;
		end 
		t.label("READ BYTE");
		wb_trans.push_back(t);

		//wait_interrupt_with_NACK();
		clear_interrupt();

		//	master_read(DPR, iobuf);
		t = new("retrieve_data_post_read");
		t.write = 1'b0;
		t.line = DPR;
		t.word=8'b0;
		t.cmd=NONE;
		t.wait_int_nack=1'b0;
		t.wait_int_ack=1'b0;
		t.stall_cycles=0;
		wb_trans.push_back(t);
	endfunction*/


	endclass