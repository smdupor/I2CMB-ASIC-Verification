package i2c_types_pkg;


typedef enum bit {I2_WRITE=1'b0, I2_READ=1'b1} i2c_op_t;

function void display_hstars();
	$display("*******************************************************************************");
endfunction

function void display_hrule();
	$display("-------------------------------------------------------------------------------");
endfunction

parameter int PRINT_LINE_LEN = 76;
endpackage