	class generator extends ncsu_component#(.T(i2c_transaction));

		i2c_transaction i2c_trans[130];
		//wb_transaction wb_trans[130];
		wb_transaction wb_trans[$];
		wb_agent wb_agent_handle;
		i2c_agent i2c_agent_handle;
		string trans_name;

		function new(string name = "", ncsu_component_base  parent = null);
			super.new(name,parent);
			/*if ( !$value$plusargs("GEN_TRANS_TYPE=%s", trans_name)) begin
	$display("FATAL: +GEN_TRANS_TYPE plusarg not found on command line");
	$fatal;
end*/
			$display("%m found +GEN_TRANS_TYPE=%s", trans_name);
		endfunction

		virtual task run();
			int i,j,k;
			// Instantiate Transactions

			enable_dut_with_interrupt();

			j=64;
			k=63;
			foreach (i2c_trans[i]) begin
				$cast(i2c_trans[i],ncsu_object_factory::create("i2c_transaction"));
				// pick  a bus
				i2c_trans[i].selected_bus=i % 15;
				select_I2C_bus(i2c_trans[i].selected_bus);

				issue_start_command();

				// pick an address
				i2c_trans[i].address = (i % 18)+1;

				// WRITE ALL
				if(i==0) begin
					transmit_address_req_write(i2c_trans[i].address);
					for(j=0;j<=31;j++) write_data_byte(byte'(j));
					set_explicit_range(0, 31, i, I2_WRITE);
					issue_stop_command();
				end

				// READ ALL
				if(i==1) begin
					transmit_address_req_read(i2c_trans[i].address);
					for(j=100;j<=130;j++) read_data_byte_with_continue();
					read_data_byte_with_stop();
					set_explicit_range(100, 131, i, I2_READ);
					issue_stop_command();
					j=64;
				end

				// Alternation EVEN
				if(i>1 && i % 2 == 0) begin // do a write
					transmit_address_req_write(i2c_trans[i].address);
					write_data_byte(byte'(k));
					--k;
					set_explicit_range(k, k, i, I2_WRITE);
					issue_stop_command();
				end
				// Alternation ODD
				else if (i>1 && i % 2 == 1) begin // do a write
					transmit_address_req_read(i2c_trans[i].address);
					read_data_byte_with_stop();
					++j;
					set_explicit_range(j, j, i, I2_READ);
					issue_stop_command();
				end

				/*$cast(wb_trans[i],ncsu_object_factory::create("wb_transaction"));
				wb_trans[i].address = (i % 18)+1;
				wb_trans[i].selected_bus = i % 15;
				wb_trans[i].explicit=UNSET;
				wb_trans[i].persist=STOP;*/


			end
			//issue_start_command();
			//issue_stop_command();
			//	issue_stop_command();

			//set_explicit_range(0, 31, 0, I2_WRITE); // WRITE_ALL task
			//set_explicit_range(100, 131, 1, I2_READ); // WRITE_ALL task


			/*j=63;
			k=2;
			// Generate data for writes in third alternating r/w series
			for(i=64;i<=127;i++)begin
				set_explicit_range(i, i, k, I2_WRITE);
				set_explicit_range(j, j, k+1, I2_READ);
				k += 2;
				--j;
			end*/
			foreach(wb_trans[i]) begin
				$display(wb_trans[i].name);
				if(i>10) break;
			end

			wb_agent_handle.bl_put(wb_trans.pop_front());
			$display("   ");
			/*foreach (i2c_trans[i]) begin
				
				fork
					begin
						do begin
							wb_agent_handle.bl_put(wb_trans.pop_front());
				 end
						while(!next_is_new_transfer()); end
					i2c_agent_handle.bl_put(i2c_trans[i]);
				join
				//$display("Block In Question Exited");
			end*/
			//assert (transaction[i].randomize());
			//agent.bl_put(transaction[i]);
			//$display({get_full_name()," ",transaction[i].convert2string()});
			//end
			fork
				foreach(i2c_trans[i]) i2c_agent_handle.bl_put(i2c_trans[i]);
				foreach(wb_trans[i]) wb_agent_handle.bl_put(wb_trans[i]);
			join
			# 1000000;
		endtask

		function bit next_is_new_transfer();
			return (wb_trans.size() == 0 || wb_trans[0].block);
		endfunction

		function void set_wb_agent(wb_agent agent);
			this.wb_agent_handle = agent;
		endfunction

		function void set_i2c_agent(i2c_agent agent);
			this.i2c_agent_handle = agent;
		endfunction

		function void set_explicit_range(input int start_value, input int end_value, input int trans_index, input i2c_op_t operation);
			bit [7:0] init_data[$];
			init_data.delete();

			if(end_value >= start_value) begin
				for(int i=start_value;i<=end_value;i++) begin
					init_data.push_back(byte'(i));
				end
			end
			else begin
				for(int i=start_value;i>=end_value;i--) begin
					init_data.push_back(byte'(i));
				end
			end
			i2c_trans[trans_index].data=init_data;
			//wb_trans[trans_index].data=init_data;
			i2c_trans[trans_index].rw = operation;
			//wb_trans[trans_index].rw = operation;
			//if(operation == I2_READ) wb_trans[trans_index].QTY_WORDS_TO_READ = wb_trans[trans_index].data.size();
			init_data.delete();
		endfunction


		//_____________________________________________________________________________________\\
		//                           WISHBONE DRIVER ABSTRACTIONS                              \\
		//_____________________________________________________________________________________\\

		// ****************************************************************************
		// Enable the DUT core. Effectively, a soft reset after a disable command
		// 		NB: Also sets the enable_interrupt bit of the DUT such that we can use
		// 			raised interrupts to determine DUT-ready rather than polling
		//			DUT registers for readiness.
		// ****************************************************************************
		function void enable_dut_with_interrupt();
			wb_transaction t = new("DUT_Enable");
			t.write = 1'b1;
			t.line = CSR;
			t.cmd = ENABLE_CORE_INTERRUPT;
			t.word=8'b0;
			t.wait_int_nack=1'b0;
			t.wait_int_ack=1'b0;
			t.stall_cycles=0;
			wb_trans.push_back(t);
			//master_write(CSR, ENABLE_CORE_INTERRUPT); // Enable DUT
		endfunction

		// ****************************************************************************
		// Select desired I2C bus of DUT to use for transfers.
		// ****************************************************************************
		function void select_I2C_bus(input bit [7:0] selected_bus);
			wb_transaction t = new("write_selected_i2c_bus");
			t.write = 1'b1;
			t.line = DPR;
			t.word=selected_bus;
			t.cmd=NONE;
			t.wait_int_nack=1'b0;
			t.wait_int_ack=1'b0;
			t.stall_cycles=0;
			t.block = 1'b1;
			wb_trans.push_back(t);
			//master_write(DPR, selected_bus);

			t = new("trigger_selection_i2c_bus");
			t.write = 1'b1;
			t.line = CMDR;
			t.word=8'b0;
			t.cmd=SET_I2C_BUS;
			t.wait_int_nack=1'b0;
			t.wait_int_ack=1'b1;
			t.stall_cycles=0;
			wb_trans.push_back(t);
			//master_write(CMDR, SET_I2C_BUS);

			//wait_interrupt();

		endfunction

		// ****************************************************************************
		// Disable the DUT and STALL for 2 system cycles
		// ****************************************************************************
		function void disable_dut();
			wb_transaction t = new("disable_dut");
			t.write = 1'b1;
			t.line = CSR;
			t.word=8'b0;
			t.cmd=DISABLE_CORE;
			t.wait_int_nack=1'b0;
			t.wait_int_ack=1'b0;
			t.stall_cycles=2;
			wb_trans.push_back(t);
			//master_write(CSR, DISABLE_CORE); // Enable DUT

		endfunction

		// ****************************************************************************
		// Wait for, and clear, interrupt rising from WB-end of DUT. 
		// Do not check incoming status bits.
		// ****************************************************************************
		function void wait_interrupt();
			//wait(irq_i ==1'b1);
			//master_read(CMDR, buf_in);
		endfunction

		// ****************************************************************************
		// Wait for, and clear, interrupt rising from WB-end of DUT. 
		// Check status register and alert user to problem if a NACK was received.
		// ****************************************************************************
		function void wait_interrupt_with_NACK();
			//wait(irq_i ==1'b1);
			//master_read(CMDR, buf_in);
			//if(buf_in[6]==1'b1) $display("\t[ WB ] NACK");
		endfunction

		// ****************************************************************************
		// Send a start command to I2C nets via DUT
		// ****************************************************************************
		function void issue_start_command();
			wb_transaction t = new("send_start_command");
			t.write = 1'b1;
			t.line = CMDR;
			t.word=8'b0;
			t.cmd=I2C_START;
			t.wait_int_nack=1'b0;
			t.wait_int_ack=1'b1;
			t.stall_cycles=0;
			wb_trans.push_back(t);

			//master_write(CMDR, I2C_START);
			//wait_interrupt();
		endfunction

		// ****************************************************************************
		// Send a stop command to I2C Nets via DUT
		// ****************************************************************************
		function void issue_stop_command();
			wb_transaction t = new("send_stop_command");
			t.write = 1'b1;
			t.line = CMDR;
			t.word=8'b0;
			t.cmd=I2C_STOP;
			t.wait_int_nack=1'b0;
			t.wait_int_ack=1'b1;
			t.stall_cycles=0;
			wb_trans.push_back(t);
			//master_write(CMDR, I2C_STOP); // Stop the transaction/Close connection
			//wait_interrupt();
		endfunction

		// ****************************************************************************
		// Format incoming address byte and set R/W bit to request a WRITE.
		// Transmit this formatted address byte on the I2C bus
		// ****************************************************************************
		function void transmit_address_req_write(input bit [7:0] addr);
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
			wb_trans.push_back(t);

			//master_write(DPR, addr);

			t = new("trigger_address_transmission");
			t.write = 1'b1;
			t.line = CMDR;
			t.word=8'b0;
			t.cmd=I2C_WRITE;
			t.wait_int_nack=1'b1;
			t.wait_int_ack=1'b0;
			t.stall_cycles=0;
			wb_trans.push_back(t);
			//master_write(CMDR, I2C_WRITE);
			//wait_interrupt_with_NACK(); // In case of a down/unresponsive slave, we'd get a nack	
		endfunction

		// ****************************************************************************
		// Format incoming address byte and set R/W bit to request a READ.
		// Transmit this formatted address byte on the I2C bus
		// ****************************************************************************
		function void transmit_address_req_read(input bit [7:0] addr);
			wb_transaction t = new("emplace_address_req_read");
			addr = addr << 1;
			addr[0]=1'b1;

			t.write = 1'b1;
			t.line = DPR;
			t.word=addr;
			t.cmd=NONE;
			t.wait_int_nack=1'b0;
			t.wait_int_ack=1'b0;
			t.stall_cycles=0;
			wb_trans.push_back(t);

			t = new("trigger_address_transmission");
			t.write = 1'b1;
			t.line = CMDR;
			t.word=8'b0;
			t.cmd=I2C_WRITE;
			t.wait_int_nack=1'b1;
			t.wait_int_ack=1'b0;
			t.stall_cycles=0;
			wb_trans.push_back(t);
			//master_write(CMDR, I2C_WRITE);
			//wait_interrupt_with_NACK(); // In case of a down/unresponsive slave, we'd get a nack
		endfunction

		// ****************************************************************************
		// Write a single byte of data to a previously-addressed I2C Slave
		// Check to ensure we didn't get a NACK/ Got the ACK from the slave.
		// ****************************************************************************
		function void write_data_byte(input bit [7:0] data);
			wb_transaction t = new("emplace_data_pre_write");
			t.write = 1'b1;
			t.line = DPR;
			t.word=data;
			t.cmd=NONE;
			t.wait_int_nack=1'b0;
			t.wait_int_ack=1'b0;
			t.stall_cycles=0;
			wb_trans.push_back(t);

			//master_write(DPR, data);
			t = new("trigger_byte_write_trans");
			t.write = 1'b1;
			t.line = CMDR;
			t.word=8'b0;
			t.cmd=I2C_WRITE;
			t.wait_int_nack=1'b1;
			t.wait_int_ack=1'b0;
			t.stall_cycles=0;
			wb_trans.push_back(t);
			//master_write(CMDR, I2C_WRITE);
			//wait_interrupt_with_NACK();
		endfunction

		// ****************************************************************************
		// READ a single byte of data from a previously-addressed I2C Slave,
		//      Indicating that we are REQUESTING ANOTHER byte after this byte.
		// Check to ensure we didn't get a NACK/ Got the ACK from the slave.
		// ****************************************************************************
		function void read_data_byte_with_continue();
			wb_transaction t = new("trigger_byte_read_trans");
			t.write = 1'b1;
			t.line = CMDR;
			t.word=8'b0;
			t.cmd=READ_WITH_ACK;
			t.wait_int_nack=1'b1;
			t.wait_int_ack=1'b0;
			t.stall_cycles=0;
			wb_trans.push_back(t);
			//master_write(CMDR, READ_WITH_ACK);
			//wait_interrupt_with_NACK();
			t = new("retrieve_data_post_read");
			t.write = 1'b0;
			t.line = DPR;
			t.word=8'b0;
			t.cmd=NONE;
			t.wait_int_nack=1'b0;
			t.wait_int_ack=1'b0;
			t.stall_cycles=0;
			wb_trans.push_back(t);

			//master_read(DPR, iobuf);
		endfunction

		// ****************************************************************************
		// READ a single byte of data from a previously-addressed I2C Slave,
		//      Indicating that this is the LAST BYTE of this transfer, and the next
		// 		bus action will be a STOP signal.
		// Check to ensure we didn't get a NACK/ Got the ACK from the slave.
		// ****************************************************************************
		function void read_data_byte_with_stop();
			wb_transaction t = new("trigger_byte_read_trans");
			t.write = 1'b1;
			t.line = CMDR;
			t.word=8'b0;
			t.cmd=READ_WITH_NACK;
			t.wait_int_nack=1'b1;
			t.wait_int_ack=1'b0;
			t.stall_cycles=0;
			wb_trans.push_back(t);

			//master_write(CMDR, READ_WITH_NACK);
			//wait_interrupt_with_NACK();

			t = new("retrieve_data_post_read");
			t.write = 1'b0;
			t.line = DPR;
			t.word=8'b0;
			t.cmd=NONE;
			t.wait_int_nack=1'b0;
			t.wait_int_ack=1'b0;
			t.stall_cycles=0;
			wb_trans.push_back(t);
			//master_read(DPR, iobuf);
		endfunction

	endclass