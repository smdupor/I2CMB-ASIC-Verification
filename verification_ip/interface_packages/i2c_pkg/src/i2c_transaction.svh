class i2c_transaction extends ncsu_transaction;

`ncsu_register_object(i2c_transaction)

	bit [7:0] address;
	bit [7:0] data [];
	int selected_bus;
	i2c_op_t rw;

	function new(string name="");
		super.new(name);

	endfunction

	function void set(bit [7:0] address,	bit [7:0] data [],i2c_op_t rw, int selected_bus);
		this.address = address;
		this.data=data;
		this.rw=rw;
		this.selected_bus=selected_bus;
	endfunction

	function string convert2string_legacy();
		string s,temp;
		if(rw == I2_WRITE) begin
			s = "I2C_BUS WRITE Transfer To   Address: ";
		end
		else begin
			s = "I2C_BUS READ  Transfer From Address: ";
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
		//return {super.convert2string(),$sformatf("Address:0x%x payload:0x%p trailer:0x%x delay:%d", header, payload, trailer, delay)};
	endfunction

	virtual function string convert2string();
		return {super.convert2string(),convert2string_legacy()};
	endfunction

	function bit compare(i2c_transaction other);
		if(this.address != other.address) return 0;
		if(this.rw != other.rw) return 0;
		foreach(this.data[i]) begin
			if(this.data[i]!=other.data[i]) return 0;
		end
		return 1;
	endfunction

endclass
