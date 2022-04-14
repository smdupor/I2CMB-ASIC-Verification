class i2c_arb_loss_transaction extends i2c_transaction;

`ncsu_register_object(i2c_arb_loss_transaction)

	bit [7:0] address;
	bit [7:0] data [];
	int selected_bus;
	int clock_stretch_qty;
	i2c_op_t rw;
	bit lose_arb;
	bit on_read;
	bit on_start;

	// ****************************************************************************
	// Constraints and Randomization
	// ****************************************************************************


	function void post_randomize();
		clock_stretch_qty *= 1000;
	endfunction

	// ****************************************************************************
	// Construction, setters and getters
	// ****************************************************************************
	function new(string name="");
		super.new(name);
		lose_arb = 1'b1;
	endfunction

	function void set(bit [7:0] address,	bit [7:0] data [],i2c_op_t rw, int selected_bus);
		this.address = address;
		this.data=data;
		this.rw=rw;
		this.selected_bus=selected_bus;
	endfunction

	// ****************************************************************************
	// to_string LEGACY implementation, without calls to superclass
	// ****************************************************************************
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

			temp.itoa(integer'(data[i]));
			s = {s,temp,","};
		end
		return s.substr(0,s.len-2);

	endfunction

	// ****************************************************************************
	// Complete to_string functionality
	// ****************************************************************************
	virtual function string convert2string();
		return {super.convert2string(),convert2string_legacy()};
	endfunction

	// ****************************************************************************
	// Check match between two I2C Transactions
	// ****************************************************************************
	function bit compare(i2c_transaction other);
		if(this.address != other.address) return 0;
		if(this.rw != other.rw) return 0;
		foreach(this.data[i]) begin
			if(this.data[i]!=other.data[i]) return 0;
		end
		return 1;
	endfunction

	function void set_arb_read();
		this.on_read = 1'b1;
	endfunction

		function void set_arb_start();
		this.on_start = 1'b1;
	endfunction

endclass
