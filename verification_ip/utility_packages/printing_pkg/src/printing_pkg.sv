package printing_pkg;
//	Support functions to encapsulate common printing tasks, like Hlines, Hrules, rows of *, and header/footer banners


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
	endfunction

	parameter int PRINT_LINE_LEN = 76;
	
endpackage