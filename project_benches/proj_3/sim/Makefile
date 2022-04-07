export ECE745_PROJECT_HOME ?= $(PWD)/../../..

GTT ?= i2c_transaction
TEST_SEED ?= 12345

include $(ECE745_PROJECT_HOME)/verification_ip/ncsu_pkg/Makefile
include $(ECE745_PROJECT_HOME)/verification_ip/interface_packages/wb_pkg/Makefile
include $(ECE745_PROJECT_HOME)/verification_ip/interface_packages/i2c_pkg/Makefile
include $(ECE745_PROJECT_HOME)/verification_ip/environment_packages/i2cmb_env_pkg/Makefile

list:
	@grep '^[^#[:space:]].*:' Makefile

clean: 
	rm -rf work *.wlf transcript
	git pull

comp_I2C_MB:
	vcom -cover bcefst ../rtl/iicmb_int_pkg.vhd
	vcom -cover bcefst ../rtl/iicmb_pkg.vhd
	vcom -cover bcefst ../rtl/mbyte.vhd
	vcom -cover bcefst ../rtl/mbit.vhd
	vcom -cover bcefst ../rtl/bus_state.vhd
	vcom -cover bcefst ../rtl/filter.vhd
	vcom -cover bcefst ../rtl/conditioner.vhd
	vcom -cover bcefst ../rtl/conditioner_mux.vhd
	vcom -cover bcefst ../rtl/iicmb_m.vhd
	vcom -cover bcefst ../rtl/regblock.vhd
	vcom -cover bcefst ../rtl/wishbone.vhd 
	vcom -cover bcefst ../rtl/iicmb_m_wb.vhd


comp_bench: comp_ncsu_pkg comp_i2c_pkg comp_wb_pkg comp_i2cmb_env
	vlog ../testbench/top.sv

#comp_slave:	 comp_wb_pkg
#	vlog ../testbench/top.sv

optimize:
	vopt +acc top -o optimized_debug_top_tb

compile: comp_bench comp_I2C_MB optimize

simulate: 
	#vsim  -i -classdebug -msgmode both -do "set NoQuitOnFinish 1; do wave.do"  +GTT=$(GTT) +VERBOSITY_LEVEL=MEDIUM optimized_debug_top_tb &
	vsim -i -classdebug -msgmode both -coverage -sv_seed $(TEST_SEED) -do "set NoQuitOnFinish 1;do wave.do;run -a;coverage attribute -name TESTNAME -value $(GTT); coverage save $(GTT).$(TEST_SEED).ucdb;" +GTT=$(GTT) +VERBOSITY_LEVEL=MEDIUM optimized_debug_top_tb &
debug: clean compile simulate

restart: clean compile

console: clean compile
	vsim  -c -classdebug -msgmode both -do "set NoQuitOnFinish 1; run 100ms; exit" optimized_debug_top_tb
	
silent: clean compile_sil
	#vsim  -c -classdebug -msgmode both -do "set NoQuitOnFinish 1; run 40ms; exit" +GTT=$(GTT) +VERBOSITY_LEVEL=MEDIUM optimized_debug_top_tb
	vsim  -c -sv_seed $(TEST_SEED) -coverage -do "set NoQuitOnFinish 1; run -a; coverage attribute -name TESTNAME -value i2cmb_test_multi_bus_range; coverage save $(GTT).$(TEST_SEED).ucdb; quit -f" +GTT=$(GTT) +VERBOSITY_LEVEL=LOW optimized_debug_top_tb
	#@echo "********************************************************************************************"
	#@echo "  "
	#diff transcript transcript.bak
silent2: clean compile_sil
	GTT := test_reg_crosscheck
	vsim  -c -sv_seed $(TEST_SEED) -coverage -do "set NoQuitOnFinish 1; run -a; coverage attribute -name TESTNAME -value $(GTT); coverage save $(GTT).$(TEST_SEED).ucdb; quit -f" +GTT=$(GTT) +VERBOSITY_LEVEL=LOW optimized_debug_top_tb
	GT := test_reg_accessctrl
	vsim  -c -sv_seed $(TEST_SEED) -coverage -do "set NoQuitOnFinish 1; run -a; coverage attribute -name TESTNAME -value $(GTT); coverage save $(GTT).$(TEST_SEED).ucdb; quit -f" +GTT=$(GTT) +VERBOSITY_LEVEL=LOW optimized_debug_top_tb
	GTT := i2cmb_test_single_bus_default
	vsim  -c -sv_seed $(TEST_SEED) -coverage -do "set NoQuitOnFinish 1; run -a; coverage attribute -name TESTNAME -value $(GTT); coverage save $(GTT).$(TEST_SEED).ucdb; quit -f" +GTT=$(GTT) +VERBOSITY_LEVEL=LOW optimized_debug_top_tb
	GTT := i2cmb_test_multi_bus_default
	vsim  -c -sv_seed $(TEST_SEED) -coverage -do "set NoQuitOnFinish 1; run -a; coverage attribute -name TESTNAME -value $(GTT); coverage save $(GTT).$(TEST_SEED).ucdb; quit -f" +GTT=$(GTT) +VERBOSITY_LEVEL=LOW optimized_debug_top_tb
	GTT := i2cmb_test_multi_bus_max
	vsim  -c -sv_seed $(TEST_SEED) -coverage -do "set NoQuitOnFinish 1; run -a; coverage attribute -name TESTNAME -value $(GTT); coverage save $(GTT).$(TEST_SEED).ucdb; quit -f" +GTT=$(GTT) +VERBOSITY_LEVEL=LOW optimized_debug_top_tb
	GTT := i2cmb_test_multi_bus_range
	vsim  -c -sv_seed $(TEST_SEED) -coverage -do "set NoQuitOnFinish 1; run -a; coverage attribute -name TESTNAME -value $(GTT); coverage save $(GTT).$(TEST_SEED).ucdb; quit -f" +GTT=$(GTT) +VERBOSITY_LEVEL=LOW optimized_debug_top_tb
	GTT := test_arbitration
	vsim  -c -sv_seed $(TEST_SEED) -coverage -do "set NoQuitOnFinish 1; run -a; coverage attribute -name TESTNAME -value $(GTT); coverage save $(GTT).$(TEST_SEED).ucdb; quit -f" +GTT=$(GTT) +VERBOSITY_LEVEL=LOW optimized_debug_top_tb
	GTT := test_interrupt_cycling
	vsim  -c -sv_seed $(TEST_SEED) -coverage -do "set NoQuitOnFinish 1; run -a; coverage attribute -name TESTNAME -value $(GTT); coverage save $(GTT).$(TEST_SEED).ucdb; quit -f" +GTT=$(GTT) +VERBOSITY_LEVEL=LOW optimized_debug_top_tb
	GTT := test_hard_reset_insertion
	vsim  -c -sv_seed $(TEST_SEED) -coverage -do "set NoQuitOnFinish 1; run -a; coverage attribute -name TESTNAME -value $(GTT); coverage save $(GTT).$(TEST_SEED).ucdb; quit -f" +GTT=$(GTT) +VERBOSITY_LEVEL=LOW optimized_debug_top_tb

silent_super: clean compile_sil
	vsim  -c -classdebug -msgmode both -do "set NoQuitOnFinish 1; run 40ms; exit" +GTT=$(GTT) +VERBOSITY_LEVEL=MEDIUM optimized_debug_top_tb > /dev/null
	@echo "********************************************************************************************"
	@echo "  "
	diff transcript transcript.bak
	
silent_max_verb: clean compile_sil
	vsim  -c -classdebug -msgmode both -do "set NoQuitOnFinish 1; run 40ms; exit" +GTT=$(GTT) +VERBOSITY_LEVEL=DEBUG optimized_debug_top_tb
	#@echo "********************************************************************************************"
	#@echo "  "
	#diff transcript transcript.bak
	
comp_I2C_MB_sil:
	vcom -cover bcefst ../rtl/iicmb_int_pkg.vhd > /dev/null
	vcom -cover bcefst ../rtl/iicmb_pkg.vhd > /dev/null
	vcom -cover bcefst ../rtl/mbyte.vhd > /dev/null
	vcom -cover bcefst ../rtl/mbit.vhd > /dev/null
	vcom -cover bcefst ../rtl/bus_state.vhd > /dev/null
	vcom -cover bcefst ../rtl/filter.vhd > /dev/null
	vcom -cover bcefst ../rtl/conditioner.vhd > /dev/null
	vcom -cover bcefst ../rtl/conditioner_mux.vhd > /dev/null
	vcom -cover bcefst ../rtl/iicmb_m.vhd > /dev/null
	vcom -cover bcefst ../rtl/regblock.vhd > /dev/null
	vcom -cover bcefst ../rtl/wishbone.vhd  > /dev/null
	vcom -cover bcefst ../rtl/iicmb_m_wb.vhd > /dev/null


comp_bench_sil: comp_ncsu_pkg_sil comp_i2c_pkg_sil comp_wb_pkg_sil comp_i2cmb_env_sil
	vlog ../testbench/top.sv > /dev/null

#comp_slave_sil:	comp_i2c_pkg_sil comp_wb_pkg_sil
#	vlog ../testbench/top.sv > /dev/null

optimize_sil:
	vopt +acc top -o optimized_debug_top_tb > /dev/null

compile_sil: comp_bench_sil comp_I2C_MB_sil optimize_sil

convert_testplan:
	xml2ucdb -format Excel ./i2cmb_test_plan.xml ./i2cmb_test_plan.ucdb
	add testbrowser ./*.ucdb
	
merge_coverage:
	vcover merge -stats=none -strip 0 -totals sim_and_testplan_merged.ucdb ./*.ucdb 
	coverage open ./sim_and_testplan_merged.ucdb

report_coverage:
	vcover report -details -html -htmldir covhtmlreport -assert -directive -cvg -code bcefst -threshL 50 -threshH 90 ./sim_and_testplan_merged.ucdb

show_coverage:
	vsim -i -classdebug -msgmode both -coverage -sv_seed $(TEST_SEED) -do "set NoQuitOnFinish 1;do coverage_merge_and_report.do" +GTT=$(GTT) +VERBOSITY_LEVEL=MEDIUM optimized_debug_top_tb &