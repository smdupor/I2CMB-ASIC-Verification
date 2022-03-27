comp_wb_pkg: comp_wb_printing comp_wb_types
	vlog $(ECE745_PROJECT_HOME)/verification_ip/interface_packages/wb_pkg/src/wb_if.sv
	vlog +incdir+$(ECE745_PROJECT_HOME)/verification_ip/ncsu_pkg +incdir+$(ECE745_PROJECT_HOME)/verification_ip/interface_packages/wb_pkg $(ECE745_PROJECT_HOME)/verification_ip/interface_packages/wb_pkg/wb_pkg.sv

comp_wb_pkg_sil: comp_wb_printing_sil comp_wb_types_sil
	vlog $(ECE745_PROJECT_HOME)/verification_ip/interface_packages/wb_pkg/src/wb_if.sv > /dev/null
	vlog +incdir+$(ECE745_PROJECT_HOME)/verification_ip/ncsu_pkg +incdir+$(ECE745_PROJECT_HOME)/verification_ip/interface_packages/wb_pkg $(ECE745_PROJECT_HOME)/verification_ip/interface_packages/wb_pkg/wb_pkg.sv > /dev/null
	
comp_wb_printing:
	vlog $(ECE745_PROJECT_HOME)/verification_ip/utility_packages/printing_pkg/src/printing_pkg.sv

comp_wb_printing_sil:
	vlog $(ECE745_PROJECT_HOME)/verification_ip/utility_packages/printing_pkg/src/printing_pkg.sv >/dev/null
	
comp_wb_types:
	vlog $(ECE745_PROJECT_HOME)/verification_ip/interface_packages/wb_pkg/src/wb_types_pkg.sv
	
comp_wb_types_sil:
	vlog $(ECE745_PROJECT_HOME)/verification_ip/interface_packages/wb_pkg/src/wb_types_pkg.sv > /dev/null