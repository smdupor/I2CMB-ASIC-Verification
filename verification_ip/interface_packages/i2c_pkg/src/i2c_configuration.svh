class i2c_configuration extends ncsu_configuration;

	const int i2c_addr_width;
	const int i2c_data_width;

	function new(string name="");
		super.new(name);
		i2c_addr_width = 8;
		i2c_data_width = 8;
	endfunction

	virtual function string convert2string();
		return {super.convert2string};
	endfunction

endclass