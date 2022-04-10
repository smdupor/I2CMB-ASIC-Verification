class wb_transaction_arb_loss extends wb_transaction;

`ncsu_register_object(wb_transaction_arb_loss)

	// Transaction Parameters
	bit [7:0] word;		// Data to / from the DPR
	bit [1:0] line;		// Which register to read/write to/fromo
	bit write;			// Whether this xation is a write or read
	wb_cmd_t cmd;		// The wb command associated with this xaction
	bit wait_int_ack;	// Whether this xaction should cause an interrupt
	bit wait_int_nack;	// Whether this xaction should cause an interrupt requiring nack-checking
	int stall_cycles;	// How many cycles to stall after this xaction
	bit expect_arb_loss;

	// Printing Controls
	bit en_printing;		// Enable printing of this transaction at the generator
	string pretty_print_id;	// Pretty print ID

	// ****************************************************************************
	// Transaction Constructions
	// ****************************************************************************
	function new(string name="");
		super.new(name);
	endfunction

	// ****************************************************************************
	// to_string functionality
	// ****************************************************************************
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

	// ****************************************************************************
	// Set pretty printing mode label and enable printing of this xaction
	// ****************************************************************************
	function void label(string s);
		this.en_printing = 1'b1;
		this.pretty_print_id = s;
	endfunction

	// ****************************************************************************
	// Enable to_string functionality when in pretty print mode
	// ****************************************************************************
	virtual function string to_s_prettyprint();
		string s;
		s={" ",super.convert2string()};
		if(line == DPR && (name == "emplace_address_req_write" || name == "emplace_address_req_read")) s = {s, $sformatf("Value: %0d", word>>1)};
		else if(line==DPR) s = {s, $sformatf("Value: %0d", word)};
		return s;
	endfunction

	// ****************************************************************************
	// Check for equality between transactions
	// ****************************************************************************
	function bit compare(wb_transaction rhs);
		return (this.word==rhs.word &&
		this.line==rhs.line &&
		this.write==rhs.write &&
		this.cmd == rhs.cmd);
	endfunction

endclass
