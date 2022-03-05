include $(ECE745_PROJECT_HOME)/verification_ip/ncsu_pkg/Makefile

comp_i2c_pkg: comp_i2c_types comp_i2c_printing
	vlog $(ECE745_PROJECT_HOME)/verification_ip/interface_packages/i2c_pkg/src/i2c_if.sv
	vlog +incdir+$(ECE745_PROJECT_HOME)/verification_ip/interface_packages/i2c_pkg +incdir+$(ECE745_PROJECT_HOME)/verification_ip/ncsu_pkg $(ECE745_PROJECT_HOME)/verification_ip/interface_packages/i2c_pkg/i2c_pkg.sv

comp_i2c_types:
	vlog $(ECE745_PROJECT_HOME)/verification_ip/interface_packages/i2c_pkg/src/i2c_types_pkg.sv
	
comp_i2c_printing:
	vlog $(ECE745_PROJECT_HOME)/verification_ip/utility_packages/printing_pkg/src/printing_pkg.sv

comp_i2c_pkg_sil: comp_i2c_types_sil comp_i2c_printing_sil
	vlog $(ECE745_PROJECT_HOME)/verification_ip/interface_packages/i2c_pkg/src/i2c_if.sv 
	vlog +incdir+$(ECE745_PROJECT_HOME)/verification_ip/ncsu_pkg/ +incdir+$(ECE745_PROJECT_HOME)/verification_ip/interface_packages/i2c_pkg $(ECE745_PROJECT_HOME)/verification_ip/interface_packages/i2c_pkg/i2c_pkg.sv 

comp_i2c_types_sil:
	vlog $(ECE745_PROJECT_HOME)/verification_ip/interface_packages/i2c_pkg/src/i2c_types_pkg.sv >/dev/null

comp_i2c_printing_sil:
	vlog $(ECE745_PROJECT_HOME)/verification_ip/utility_packages/printing_pkg/src/printing_pkg.sv >/dev/null