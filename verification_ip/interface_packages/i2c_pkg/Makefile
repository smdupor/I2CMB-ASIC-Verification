comp_i2c_pkg: comp_i2c_types
	vlog $(ECE745_PROJECT_HOME)/verification_ip/interface_packages/i2c_pkg/src/i2c_if.sv

comp_i2c_types:
	vlog $(ECE745_PROJECT_HOME)/verification_ip/interface_packages/i2c_pkg/src/i2c_types_pkg.sv

comp_i2c_pkg_sil: comp_i2c_types_sil
	vlog $(ECE745_PROJECT_HOME)/verification_ip/interface_packages/i2c_pkg/src/i2c_if.sv > /dev/null

comp_i2c_types_sil:
	vlog $(ECE745_PROJECT_HOME)/verification_ip/interface_packages/i2c_pkg/src/i2c_types_pkg.sv >/dev/null