class wb_transaction extends ncsu_transaction;

`ncsu_register_object(wb_transaction)

	// New Params
	bit [7:0] word;
	bit [1:0] line;
	bit write;
	wb_cmd_t cmd;
	bit wait_int_ack;
	bit wait_int_nack;
	int stall_cycles;
	bit block;

	// Printing Controls
	bit en_printing;
	string pretty_print_id;

	function new(string name="");
		super.new(name);
	endfunction


	virtual function string convert2string();
		string s,temp;
		if(write == 1'b1) begin
			s = "WB_BUS WRITE to  ";
		end
		else begin
			s = "WB_BUS READ from ";
		end
		case(line)
			DPR: s = {s, "DPR "};
			CMDR: s = {s, "CMDR "};
			CSR: s = {s, "CSR "};
		endcase
		if(line == CSR ||  line==CMDR) s = {s, "Value(0x): ", cmd};
		else if(line==DPR && (name == "emplace_address_req_write" || name == "emplace_address_req_read")) s = {s, "Value: ", word>>1};
		else if(line==DPR) s = {s, "Value: ", word};
		return {super.convert2string(),s};
	endfunction

	function void label(string s);
		this.en_printing = 1'b1;
		this.pretty_print_id = s;
	endfunction

	virtual function string to_s_prettyprint();
		string s;
		s={" ",super.convert2string()};
		if(line == DPR && (name == "emplace_address_req_write" || name == "emplace_address_req_read")) s = {s, $sformatf("Value: %0d", word>>1)};
		else if(line==DPR) s = {s, $sformatf("Value: %0d", word)};
		return s;
	endfunction

	function bit compare(wb_transaction rhs);
		return (this.word==rhs.word &&
		this.line==rhs.line &&
		this.write==rhs.write &&
		this.cmd == rhs.cmd);
	endfunction

endclass
