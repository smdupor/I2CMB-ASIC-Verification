class i2c_monitor extends ncsu_component#(.T(i2c_transaction));


	i2c_configuration  conf;
	virtual i2c_if bus;

	T monitored_trans;
	ncsu_component #(T) agent;

	function new(input string name = "", ncsu_component_base  parent = null);
		super.new(name,parent);
	endfunction

	function void set_configuration(input i2c_configuration cfg);
		conf = cfg;
	endfunction

	function void set_agent(input ncsu_component#(T) agent);
		this.agent = agent;

	endfunction

	virtual task run ();
		bit[7:0] i2mon_addr;
		i2c_op_t i2mon_op;
		bit [7:0] i2mon_data [];
		string s,temp;
		s = "";

		forever begin
			// Request transfer info from i2c BFM
			bus.monitor(i2mon_addr, i2mon_op, i2mon_data);

			// Format header based on WRITE or READ
			if(i2mon_op == I2_WRITE) begin
				s = "I2C_BUS WRITE Transfer To   Address: ";
			end
			else begin
				s = "I2C_BUS READ  Transfer From Address: ";
			end

			// Add ADDRESS associated with transfer to string, followed by "Data: " tag
			temp.itoa(integer'(i2mon_addr));
			s = {s,temp," Data: "};

			// Concatenate each data byte to string. PRINT_LINE_LEN parameter introduces a
			// number-of-characters cap, beyond which each  line will be wrapped to the nextline.
			foreach(i2mon_data[i]) begin
				if(s.len % PRINT_LINE_LEN < 4) s = {s,"\n\t"};
				temp.itoa(integer'(i2mon_data[i]));
				s = {s,temp,","};
			end

			$display("%s", s.substr(0,s.len-2));

			// In the case of a multi-line transfer, print a horizontal rule to make clear where 
			// this transfer transcript message ends
			if(s.len>60) display_hrule;
		end
	endtask

endclass