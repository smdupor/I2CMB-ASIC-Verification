package printing_pkg;
	//	Support functions to encapsulate common printing tasks, like Hlines, Hrules, rows of *, and header/footer banners

	const string lookup[27] = {"a",	"b","c","d","e","f","g","h","i","j","k","l","m","n","o","p","q","r","s","t","u","v","w","x","y","z",""	};

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
		$display("\n\n");
	endfunction

 	// ****************************************************************************
	// Create an alphanumeric code to represent this integer (used to ID large-
	// 		granularity transactions differently than numbers)
	// ****************************************************************************
	function string itoalpha(int i);
		static int j;
		static int k;
		k=i;
		j=0;
		while(k>=26) begin
			k -= 26;
			++j;
		end
		//if(j>0) 
		itoalpha={lookup[j], lookup[k]};
		//else itoalpha={" ", lookup[k]};
	endfunction

	parameter int PRINT_LINE_LEN = 76;

endpackage