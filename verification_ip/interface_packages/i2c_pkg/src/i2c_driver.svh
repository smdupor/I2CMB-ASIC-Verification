class i2c_driver extends ncsu_component#(.T(i2c_transaction));

	virtual i2c_if bus;
	i2c_configuration configuration;
	i2c_transaction i2c_trans;
	i2c_rand_cs_transaction i2c_rand_cs;
	i2c_arb_loss_transaction i2c_arb_loss;
	bit arb_loss_complete;

	function new(string name = "", ncsu_component_base parent = null);
		super.new(name,parent);
	endfunction

	function void set_configuration(i2c_configuration cfg);
		configuration = cfg;
	endfunction

	virtual task bl_put(T trans);
		bit [7:0] i2c_driver_buffer[];
		bit transfer_complete;

		if(trans != null) begin
		i2c_trans = trans;
		bus.configure(i2c_trans.address, i2c_trans.selected_bus);
		end
		if(!$cast(i2c_arb_loss, trans)) begin
		//$display({get_full_name()," ",trans.convert2string()});
		if($cast(i2c_rand_cs, trans)) begin
			if(i2c_rand_cs.rw == I2_WRITE) bus.stretch_qty = i2c_rand_cs.clock_stretch_qty;
			else bus.read_stretch_qty = i2c_rand_cs.clock_stretch_qty;
			$display("Clockstr qty %0d", i2c_rand_cs.clock_stretch_qty);
		end

		

		if(trans != null) begin
		fork
			bus.wait_for_i2c_transfer(i2c_trans.rw,i2c_driver_buffer);
			if(i2c_trans.rw == I2_READ) bus.provide_read_data(i2c_trans.data, transfer_complete);
		join
		end
		end
		else begin
			//if(!arb_loss_complete) begin
					bus.force_arbitration_loss();
			//		arb_loss_complete=1'b1;
			//end
		end
	endtask

endclass
