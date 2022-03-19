class i2c_driver extends ncsu_component#(.T(i2c_transaction));

	function new(string name = "", ncsu_component_base parent = null);
		super.new(name,parent);
	endfunction

	virtual i2c_if bus;
	i2c_configuration configuration;
	i2c_transaction i2c_trans;
	bit [7:0] i2c_driver_buffer[];
	logic [7:0] tf_buffer;
	bit transfer_complete;

	function void set_configuration(i2c_configuration cfg);
		configuration = cfg;
	endfunction

	virtual task bl_put(T trans);
		//$display({get_full_name()," ",trans.convert2string()});
		i2c_trans = trans;

		fork
			bus.wait_for_i2c_transfer(i2c_trans.rw,i2c_driver_buffer);
			if(i2c_trans.rw == I2_READ) bus.provide_read_data(i2c_trans.data, transfer_complete);
		join

	endtask

endclass
