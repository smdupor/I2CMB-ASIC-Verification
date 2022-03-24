	class wb_driver extends ncsu_component#(.T(wb_transaction));

		function new(string name = "", ncsu_component_base parent = null);
			super.new(name,parent);
		endfunction

		virtual wb_if bus;
		wb_configuration configuration;
		wb_transaction wb_trans;
		bit dut_enable;
		logic [7:0] tf_buffer;

		function void set_configuration(wb_configuration cfg);
			configuration = cfg;
		endfunction

		/*
		 * CSR - no word
		 * DPR - word
		 * CMDR - w command
		 * 
		 * 
		 */

		virtual task bl_put(T trans);
			//$display({get_full_name()," ",trans.convert2string()});
			//bus.drive(trans.payload); TODO: : DRIVE BUS
			bit [7:0] buffer;
			wb_trans = trans;
			bus.wait_for_reset();

			if(wb_trans.write) begin
				if(wb_trans.line == CMDR || wb_trans.line == CSR) bus.master_write(wb_trans.line, wb_trans.cmd);
				if(wb_trans.line == DPR) bus.master_write(wb_trans.line, wb_trans.word);
				if(wb_trans.wait_int_ack) bus.wait_interrupt();
				if(wb_trans.wait_int_nack) bus.wait_interrupt_with_NACK();
				if(wb_trans.stall_cycles > 0) bus.wait_for_num_clocks(wb_trans.stall_cycles);
			end
			else begin
				if(wb_trans.line == CMDR ||  wb_trans.line == CSR) bus.master_read(wb_trans.line, buffer);
				if(wb_trans.line==DPR) bus.master_read(wb_trans.line, buffer);
				if(wb_trans.wait_int_ack) bus.wait_interrupt();
				if(wb_trans.wait_int_nack) bus.wait_interrupt_with_NACK();
				if(wb_trans.stall_cycles > 0) bus.wait_for_num_clocks(wb_trans.stall_cycles);

			end

			/*case(wb_trans.explicit)
	EXPLICIT_ENABLE: begin
		bus.enable_dut_with_interrupt();
		dut_enable = 1'b1;
		return;
	end
	EXPLICIT_DISABLE: begin
		dut_enable = 1'b0;
		bus.disable_dut();
		return;
	end
	EXPLICIT_STOP: begin
		bus.issue_stop_command();
		return;
	end
	default: begin end // The majority of calls will not request an explicit forced command; Continue to functionality.
endcase*/

			// If DUT is not currently enabled, enable it.
			/*if(!dut_enable) begin
				bus.enable_dut_with_interrupt();
				//$display("Enable DUT");
				dut_enable = 1'b1;

				//$display("Select bus");

			end*/
			// Select the bus of the DUT to use for this transaction
			//bus.select_I2C_bus(wb_trans.selected_bus);

			//$display("write all");
			// Perform a write of all data within this transaction
			/*if(wb_trans.rw == I2_WRITE) begin
				bus.issue_start_command();
				bus.transmit_address_req_write(wb_trans.address);

				// Write contents of "output Buffer" to selected I2C Slave in a single stream
				for(int i=0;i<wb_trans.data.size;i++)
					bus.write_data_byte(wb_trans.data[i]);

			end

			// Or, Perform a read of the number of words expected by this transaction
			else if(wb_trans.QTY_WORDS_TO_READ > 0) begin // A read has been requested
				bus.issue_start_command();
				bus.transmit_address_req_read(wb_trans.address);
				for(int i=0;i<wb_trans.QTY_WORDS_TO_READ-1;i++) begin
					bus.read_data_byte_with_continue(tf_buffer); // Read all but the last byte and swallow data
					//tf_tup.address = i2c_slave_addr[8:2];
					//tf_tup.data = tf_buffer;
					//master_receive_buffer.push_back(tf_tup); // Store in Driver test Queue
				end
				bus.read_data_byte_with_stop(tf_buffer); // Read the last byte and swallow data
				//tf_tup.address = i2c_slave_addr[8:2];
				//tf_tup.data = tf_buffer;
				//master_receive_buffer.push_back(tf_tup); // Store in Driver test Queue


			end

			// If this transaction is not part of a restart-sequence, send a stop command on the bus
			//if(wb_trans.persist == STOP) 
			bus.issue_stop_command();*/
			//#1000 $display("Next");

		endtask





	endclass
	