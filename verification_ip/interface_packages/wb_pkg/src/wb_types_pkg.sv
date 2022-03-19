package wb_types_pkg;
	// Device/Wishbone Configuration and Command Logics
	enum logic[7:0] {ENABLE_CORE_INTERRUPT=8'b11xxxxxx,DISABLE_CORE=8'b0xxxxxxx,
		SET_I2C_BUS=8'bxxxxx110, I2C_START=8'bxxxxx100, I2C_WRITE=8'bxxxxx001,
		I2C_STOP=8'bxxxxx101, READ_WITH_NACK=8'bxxxxx011, READ_WITH_ACK=8'bxxxxx010} cmd;

	enum logic[2:0] {M_SET_I2C_BUS=3'b110, M_I2C_START=3'b100, M_I2C_WRITE=3'b001,
		M_I2C_STOP=3'b101, M_READ_WITH_NACK=3'b011, M_READ_WITH_ACK=3'b010} mon;


	enum bit [1:0] {CSR=2'b00, DPR=2'b01, CMDR=2'b10} dut_reg;

	typedef enum bit {STOP=1'b0, RESTART=1'b1} close_on_complete_t;

	typedef enum bit [2:0] {UNSET=3'b0, EXPLICIT_STOP=3'b01, EXPLICIT_ENABLE=3'b10, EXPLICIT_DISABLE=3'b11} explicit_bus_cmd_t;

endpackage