class wb_transaction extends ncsu_transaction;

`ncsu_register_object(wb_transaction)

		bit [7:0] address;
		bit [7:0] data [];
		i2c_op_t rw;
		close_on_complete_t persist;
		explicit_bus_cmd_t explicit;
		bit [3:0] selected_bus;
		int QTY_WORDS_TO_READ;

		// New Params
		bit [7:0] word;
		bit [1:0] line;
		bit write;
		wb_cmd_t cmd;
		bit wait_int_ack;
		bit wait_int_nack;
		int stall_cycles;
		bit block;

		function new(string name="");
			super.new(name);
		endfunction


		virtual function string convert2string();
			string s,temp;
			if(rw == I2_WRITE) begin
				s = "WB_BUS WRITE Transfer To   Address: ";
			end
			else begin
				s = "WB_BUS READ  Transfer From Address: ";
			end

			// Add ADDRESS associated with transfer to string, followed by "Data: " tag
			temp.itoa(integer'(address));
			s = {s,temp," Data: "};

			// Concatenate each data byte to string. PRINT_LINE_LEN parameter introduces a
			// number-of-characters cap, beyond which each  line will be wrapped to the nextline.
			foreach(data[i]) begin
				//if(s.len % PRINT_LINE_LEN < 4) s = {s,"\n\t"};
				temp.itoa(integer'(data[i]));
				s = {s,temp,","};
			end
			return s.substr(0,s.len-2);


			//return ""; //{super.convert2string(),$sformatf("header:0x%x payload:0x%p trailer:0x%x delay:%d", header, payload, trailer, delay)};
		endfunction

		function bit compare(wb_transaction rhs);
			return 0; // Always fail TODO TODO TODO TODO
		endfunction

		function void set(bit [7:0] address,	bit [7:0] data [],	i2c_op_t rw);
			this.address = address;
			this.data = data;
			this.rw = rw;
		endfunction

		virtual function void add_to_wave(int transaction_viewing_stream_h);
			/*super.add_to_wave(transaction_viewing_stream_h);
$add_attribute(transaction_view_h,header,"header");
$add_attribute(transaction_view_h,payload,"payload");
$add_attribute(transaction_view_h,trailer,"trailer");
$add_attribute(transaction_view_h,delay,"delay");
$end_transaction(transaction_view_h,end_time);
$free_transaction(transaction_view_h);*/
		endfunction

	endclass
	