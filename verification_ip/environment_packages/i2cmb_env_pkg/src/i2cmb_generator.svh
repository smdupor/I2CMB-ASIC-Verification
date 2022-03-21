	class generator extends ncsu_component#(.T(i2c_transaction));

		i2c_transaction i2c_trans[130];
		wb_transaction wb_trans[130];
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
			foreach (i2c_trans[i]) begin
				$cast(i2c_trans[i],ncsu_object_factory::create("i2c_transaction"));
				i2c_trans[i].address = (i % 18)+1;
				i2c_trans[i].selected_bus=i % 15;
				$cast(wb_trans[i],ncsu_object_factory::create("wb_transaction"));
				wb_trans[i].address = (i % 18)+1;
				wb_trans[i].selected_bus = i % 15;
				wb_trans[i].explicit=UNSET;
				wb_trans[i].persist=STOP;
			end

			set_explicit_range(0, 31, 0, I2_WRITE); // WRITE_ALL task
			set_explicit_range(100, 131, 1, I2_READ); // WRITE_ALL task


			j=63;
			k=2;
			// Generate data for writes in third alternating r/w series
			for(i=64;i<=127;i++)begin
				set_explicit_range(i, i, k, I2_WRITE);
				set_explicit_range(j, j, k+1, I2_READ);
				k += 2;
				--j;
			end

			foreach (i2c_trans[i]) begin
				fork
					wb_agent_handle.bl_put(wb_trans[i]);
					i2c_agent_handle.bl_put(i2c_trans[i]);
				join
				//$display("Block In Question Exited");
			end
			//assert (transaction[i].randomize());
			//agent.bl_put(transaction[i]);
			//$display({get_full_name()," ",transaction[i].convert2string()});
			//end
		endtask

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
			wb_trans[trans_index].data=init_data;
			i2c_trans[trans_index].rw = operation;
			wb_trans[trans_index].rw = operation;
			if(operation == I2_READ) wb_trans[trans_index].QTY_WORDS_TO_READ = wb_trans[trans_index].data.size();
			init_data.delete();
		endfunction


	endclass