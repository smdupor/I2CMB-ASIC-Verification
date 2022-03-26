export ECE745_PROJECT_HOME ?= $(PWD)/../../..

GEN_TRANS_TYPE ?= i2c_transaction

include $(ECE745_PROJECT_HOME)/verification_ip/ncsu_pkg/Makefile
include $(ECE745_PROJECT_HOME)/verification_ip/interface_packages/wb_pkg/Makefile
include $(ECE745_PROJECT_HOME)/verification_ip/interface_packages/i2c_pkg/Makefile
include $(ECE745_PROJECT_HOME)/verification_ip/environment_packages/i2cmb_env_pkg/Makefile

clean: 
	rm -rf work *.wlf transcript

comp_I2C_MB:
	vcom ../rtl/iicmb_int_pkg.vhd
	vcom ../rtl/iicmb_pkg.vhd
	vcom ../rtl/mbyte.vhd
	vcom ../rtl/mbit.vhd
	vcom ../rtl/bus_state.vhd
	vcom ../rtl/filter.vhd
	vcom ../rtl/conditioner.vhd
	vcom ../rtl/conditioner_mux.vhd
	vcom ../rtl/iicmb_m.vhd
	vcom ../rtl/regblock.vhd
	vcom ../rtl/wishbone.vhd 
	vcom ../rtl/iicmb_m_wb.vhd


comp_bench: comp_ncsu_pkg comp_i2c_pkg comp_wb_pkg comp_i2cmb_env
	vlog ../testbench/top.sv

#comp_slave:	 comp_wb_pkg
#	vlog ../testbench/top.sv

optimize:
	vopt +acc top -o optimized_debug_top_tb

compile: comp_bench comp_I2C_MB optimize

simulate:
	vsim  -i -classdebug -msgmode both -do "set NoQuitOnFinish 1; do wave.do"  +GEN_TRANS_TYPE=$(GEN_TRANS_TYPE) +VERBOSITY_LEVEL=MEDIUM optimized_debug_top_tb &

debug: clean compile simulate

restart: clean compile

console: clean compile
	vsim  -c -classdebug -msgmode both -do "set NoQuitOnFinish 1; run 100ms; exit" optimized_debug_top_tb
	
silent: clean compile_sil
	vsim  -c -classdebug -msgmode both -do "set NoQuitOnFinish 1; run 40ms; exit" +GEN_TRANS_TYPE=$(GEN_TRANS_TYPE) +VERBOSITY_LEVEL=MEDIUM optimized_debug_top_tb
	@echo "********************************************************************************************"
	@echo "  "
	diff transcript transcript.bak

silent_super: clean compile_sil
	vsim  -c -classdebug -msgmode both -do "set NoQuitOnFinish 1; run 40ms; exit" +GEN_TRANS_TYPE=$(GEN_TRANS_TYPE) +VERBOSITY_LEVEL=MEDIUM optimized_debug_top_tb > /dev/null
	@echo "********************************************************************************************"
	@echo "  "
	diff transcript transcript.bak
	
silent_max_verb: clean compile_sil
	vsim  -c -classdebug -msgmode both -do "set NoQuitOnFinish 1; run 40ms; exit" +GEN_TRANS_TYPE=$(GEN_TRANS_TYPE) +VERBOSITY_LEVEL=DEBUG optimized_debug_top_tb
	#@echo "********************************************************************************************"
	#@echo "  "
	#diff transcript transcript.bak
	
comp_I2C_MB_sil:
	vcom ../rtl/iicmb_int_pkg.vhd > /dev/null
	vcom ../rtl/iicmb_pkg.vhd > /dev/null
	vcom ../rtl/mbyte.vhd > /dev/null
	vcom ../rtl/mbit.vhd > /dev/null
	vcom ../rtl/bus_state.vhd > /dev/null
	vcom ../rtl/filter.vhd > /dev/null
	vcom ../rtl/conditioner.vhd > /dev/null
	vcom ../rtl/conditioner_mux.vhd > /dev/null
	vcom ../rtl/iicmb_m.vhd > /dev/null
	vcom ../rtl/regblock.vhd > /dev/null
	vcom ../rtl/wishbone.vhd  > /dev/null
	vcom ../rtl/iicmb_m_wb.vhd > /dev/null


comp_bench_sil: comp_ncsu_pkg_sil comp_i2c_pkg_sil comp_wb_pkg_sil comp_i2cmb_env_sil
	vlog ../testbench/top.sv > /dev/null

#comp_slave_sil:	comp_i2c_pkg_sil comp_wb_pkg_sil
#	vlog ../testbench/top.sv > /dev/null

optimize_sil:
	vopt +acc top -o optimized_debug_top_tb > /dev/null

compile_sil: comp_bench_sil comp_I2C_MB_sil optimize_sil