package i2c_types_pkg;


	typedef enum bit {I2_WRITE=1'b0, I2_READ=1'b1} i2c_op_t;

	function void display_hstars();
		$display("*******************************************************************************");
	endfunction

	function void display_hrule();
		$display("-------------------------------------------------------------------------------");
	endfunction

	function void display_h_lowbar();
		$display("_______________________________________________________________________________");
	endfunction

	function void display_header_banner();
		display_hstars();
		$display("\t\t\tSTARTING TEST FLOW:\n\tTransfer data from monitors follows.");
		display_hstars();
	endfunction

	function void display_footer_banner();
		//display_hstars();
		display_h_lowbar();
		$display("\t\t\tNCSU ECE745 SPRING 2022 Project Author:\n");
		$display("\tStevan Dupor : smdupor@ncsu.edu : Section 001");
		display_h_lowbar();
		//$display("Author's Note: For your convenience, Wishbone-Side Monitor Messaging has been disabled.");
		//$display(" Increasing levels of monitor verbosity may be enabled using the \n ENABLE_WISHBONE_SIMPLE_DEBUG and ");
		//$display(" ENABLE_WISHBONE_VERBOSE_DEBUG parameters (set to 1). Thank you. \n\n\n");
		//display_hstars();
	endfunction
	

	parameter int PRINT_LINE_LEN = 76;
	
endpackage