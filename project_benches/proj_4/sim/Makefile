export ECE745_PROJECT_HOME ?= $(PWD)/../../..

GTT ?= i2cmb_test_multi_bus_range
TEST_SEED ?= 12345

include $(ECE745_PROJECT_HOME)/verification_ip/ncsu_pkg/Makefile
include $(ECE745_PROJECT_HOME)/verification_ip/interface_packages/wb_pkg/Makefile
include $(ECE745_PROJECT_HOME)/verification_ip/interface_packages/i2c_pkg/Makefile
include $(ECE745_PROJECT_HOME)/verification_ip/environment_packages/i2cmb_env_pkg/Makefile

list:
	@grep '^[^#[:space:]].*:' Makefile

clean: 
	rm -rf work *.wlf transcript
	rm -rf ./covhtmlreport/

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
	$(eval TN := test_clockstretching)
	$(eval GTT := i2cmb_generator_test_multi_bus_clockstretch)
	vsim  -i -sv_seed $(TEST_SEED) -coverage -do "do wave.do;set NoQuitOnFinish 1; run -a; coverage attribute -name TESTNAME -value $(TN);" +GEN_TRANS_TYPE=$(GTT) +VERBOSITY_LEVEL=LOW optimized_debug_top_tb
debug: clean compile simulate

restart: clean compile

run_gui: clean compile
	vsim -i -classdebug -msgmode both -coverage -do "set NoQuitOnFinish 1;do wave.do;" optimized_debug_top_tb &	

console: clean compile
	vsim  -c -classdebug -msgmode both -do "set NoQuitOnFinish 1; run 100ms; exit" optimized_debug_top_tb
	
silent: clean compile_sil
	$(eval GTT := i2cmb_generator_test_multi_bus_clockstretch)
	$(eval TN := test_clockstretching)
	vsim  -c -sv_seed $(TEST_SEED) -coverage -do "set NoQuitOnFinish 1; run -a; coverage attribute -name TESTNAME -value $(TN); coverage save $(TN).$(TEST_SEED).ucdb; quit -f" +GEN_TRANS_TYPE=$(GTT) +VERBOSITY_LEVEL=LOW optimized_debug_top_tb

mulbus: clean compile_sil
	$(eval TN := test_multi_bus_max_speed)
	$(eval GTT := i2cmb_generator_test_multi_bus)
	vsim  -c -sv_seed $(TEST_SEED) -coverage -do "set NoQuitOnFinish 1; run -a; coverage attribute -name TESTNAME -value $(TN); coverage save $(TN).$(TEST_SEED).ucdb; quit -f" +GEN_TRANS_TYPE=$(GTT) +VERBOSITY_LEVEL=LOW optimized_debug_top_tb

debug_mulbus: 
	$(eval TN := test_multi_bus_max_speed)
	$(eval GTT := i2cmb_generator_test_multi_bus)
	vsim  -i -sv_seed $(TEST_SEED)-classdebug -msgmode both -coverage -do "do wave.do;set NoQuitOnFinish 1; run -a; coverage attribute -name TESTNAME -value $(TN);" +GEN_TRANS_TYPE=$(GTT) +VERBOSITY_LEVEL=LOW optimized_debug_top_tb

polling: clean compile_sil
	$(eval TN := test_enable_disable_enable_intr_x_poll)
	$(eval GTT := i2cmb_generator_interrupt_cycling)
	vsim  -c -sv_seed $(TEST_SEED) -coverage -do "set NoQuitOnFinish 1; run -a; coverage attribute -name TESTNAME -value $(TN); coverage save $(TN).$(TEST_SEED).ucdb; quit -f" +GEN_TRANS_TYPE=$(GTT) +VERBOSITY_LEVEL=LOW optimized_debug_top_tb

singbus: clean compile_sil
	$(eval TN := test_single_bus_default_speed)
	$(eval GTT := i2cmb_generator_test_single_bus)
	vsim  -c -sv_seed $(TEST_SEED) -coverage -do "set NoQuitOnFinish 1; run -a; coverage attribute -name TESTNAME -value $(TN); coverage save $(TN).$(TEST_SEED).ucdb; quit -f" +GEN_TRANS_TYPE=$(GTT) +VERBOSITY_LEVEL=LOW optimized_debug_top_tb

ranged: clean compile_sil
	$(eval TEST_SEED := 54321)
	$(eval TN := test_multi_bus_ranged_speed)
	$(eval GTT := i2cmb_generator_test_multi_bus_ranged)
	vsim  -c -sv_seed $(TEST_SEED) -coverage -do "set NoQuitOnFinish 1; run -a; coverage attribute -name TESTNAME -value $(TN); coverage save $(TN).$(TEST_SEED).ucdb; quit -f" +GEN_TRANS_TYPE=$(GTT) +VERBOSITY_LEVEL=LOW optimized_debug_top_tb

discon_slv: clean compile_sil
	$(eval TN := test_disconnected_slave_nacks)
	$(eval GTT := i2cmb_generator_disconnected_slave)
	vsim  -c -sv_seed $(TEST_SEED) -coverage -do "set NoQuitOnFinish 1; run -a; coverage attribute -name TESTNAME -value $(TN); coverage save $(TN).$(TEST_SEED).ucdb; quit -f" +GEN_TRANS_TYPE=$(GTT) +VERBOSITY_LEVEL=MEDIUM optimized_debug_top_tb

discon_slv_dbg: clean compile_sil
	$(eval TN := test_disconnected_slave_nacks)
	$(eval GTT := i2cmb_generator_disconnected_slave)
	vsim  -i -sv_seed $(TEST_SEED) -coverage -do "set NoQuitOnFinish 1; run -a; coverage attribute -name TESTNAME -value $(TN); coverage save $(TN).$(TEST_SEED).ucdb" +GEN_TRANS_TYPE=$(GTT) +VERBOSITY_LEVEL=MEDIUM optimized_debug_top_tb


silent2: clean clean_ucdb compile_sil
	date +"%T" > .timelog
	$(eval TN := test_register_crosschecking)
	$(eval GTT := i2cmb_generator_test_reg_crosscheck)
	vsim  -c -sv_seed $(TEST_SEED) -coverage -do "set NoQuitOnFinish 1; run -a; coverage attribute -name TESTNAME -value $(TN); coverage save $(TN).$(TEST_SEED).ucdb; quit -f" +GEN_TRANS_TYPE=$(GTT) +VERBOSITY_LEVEL=LOW optimized_debug_top_tb
	$(eval TN := test_register_access_control)
	$(eval GTT := i2cmb_generator_accessctrl)
	vsim  -c -sv_seed $(TEST_SEED) -coverage -do "set NoQuitOnFinish 1; run -a; coverage attribute -name TESTNAME -value $(TN); coverage save $(TN).$(TEST_SEED).ucdb; quit -f" +GEN_TRANS_TYPE=$(GTT) +VERBOSITY_LEVEL=LOW optimized_debug_top_tb
	$(eval TN := test_single_bus_default_speed)
	$(eval GTT := i2cmb_generator_test_single_bus)
	vsim  -c -sv_seed $(TEST_SEED) -coverage -do "set NoQuitOnFinish 1; run -a; coverage attribute -name TESTNAME -value $(TN); coverage save $(TN).$(TEST_SEED).ucdb; quit -f" +GEN_TRANS_TYPE=$(GTT) +VERBOSITY_LEVEL=LOW optimized_debug_top_tb
	$(eval TN := test_multi_bus_max_speed)
	$(eval GTT := i2cmb_generator_test_multi_bus)
	vsim  -c -sv_seed $(TEST_SEED) -coverage -do "set NoQuitOnFinish 1; run -a; coverage attribute -name TESTNAME -value $(TN); coverage save $(TN).$(TEST_SEED).ucdb; quit -f" +GEN_TRANS_TYPE=$(GTT) +VERBOSITY_LEVEL=LOW optimized_debug_top_tb
	$(eval TEST_SEED := 54321)
	$(eval TN := test_multi_bus_ranged_speed)
	$(eval GTT := i2cmb_generator_test_multi_bus_ranged)
	vsim  -c -sv_seed $(TEST_SEED) -coverage -do "set NoQuitOnFinish 1; run -a; coverage attribute -name TESTNAME -value $(TN); coverage save $(TN).$(TEST_SEED).ucdb; quit -f" +GEN_TRANS_TYPE=$(GTT) +VERBOSITY_LEVEL=LOW optimized_debug_top_tb
	$(eval TEST_SEED := 12345)
	$(eval TN := test_clockstretching)
	$(eval GTT := i2cmb_generator_test_multi_bus_clockstretch)
	vsim  -c -sv_seed $(TEST_SEED) -coverage -do "set NoQuitOnFinish 1; run -a; coverage attribute -name TESTNAME -value $(TN); coverage save $(TN).$(TEST_SEED).ucdb; quit -f" +GEN_TRANS_TYPE=$(GTT) +VERBOSITY_LEVEL=LOW optimized_debug_top_tb
	$(eval TN := test_arbitration_lost_scenario)
	$(eval GTT := i2cmb_generator_arb_loss)
	vsim  -c -sv_seed $(TEST_SEED) -coverage -do "set NoQuitOnFinish 1; run -a; coverage attribute -name TESTNAME -value $(TN); coverage save $(TN).$(TEST_SEED).ucdb; quit -f" +GEN_TRANS_TYPE=$(GTT) +VERBOSITY_LEVEL=LOW optimized_debug_top_tb
	$(eval TEST_SEED := 98765)
	$(eval TN := test_enable_disable_enable_intr_x_poll)
	$(eval GTT := i2cmb_generator_interrupt_cycling)
	vsim  -c -sv_seed $(TEST_SEED) -coverage -do "set NoQuitOnFinish 1; run -a; coverage attribute -name TESTNAME -value $(TN); coverage save $(TN).$(TEST_SEED).ucdb; quit -f" +GEN_TRANS_TYPE=$(GTT) +VERBOSITY_LEVEL=LOW optimized_debug_top_tb
	$(eval TN := test_disconnected_slave_nacks)
	$(eval GTT := i2cmb_generator_disconnected_slave)
	vsim  -c -sv_seed $(TEST_SEED) -coverage -do "set NoQuitOnFinish 1; run -a; coverage attribute -name TESTNAME -value $(TN); coverage save $(TN).$(TEST_SEED).ucdb; quit -f" +GEN_TRANS_TYPE=$(GTT) +VERBOSITY_LEVEL=LOW optimized_debug_top_tb
	date +"%T" >> .timelog
	echo "***************************************************************************************************"
	echo "    TEST RUNTIME"
	cat .timelog
	echo "***************************************************************************************************"
test_arb_loss: clean compile_sil
	$(eval TN := i2cmb_generator_arb_loss)
	$(eval GTT := i2cmb_generator_arb_loss)
	vsim  -c -sv_seed $(TEST_SEED) -coverage -do "set NoQuitOnFinish 1; run -a; coverage attribute -name TESTNAME -value $(TN); coverage save $(TN).$(TEST_SEED).ucdb; quit -f" +GEN_TRANS_TYPE=$(GTT) +VERBOSITY_LEVEL=LOW optimized_debug_top_tb

test_arb_gui: clean compile_sil
	$(eval TN := i2cmb_generator_arb_loss)
	$(eval GTT := i2cmb_generator_arb_loss)
	vsim  -i -classdebug -msgmode both -sv_seed $(TEST_SEED) -do "set NoQuitOnFinish 1;do wave.do; run 50ms; coverage attribute -name TESTNAME -value $(TN); coverage save $(TN).$(TEST_SEED).ucdb" +GEN_TRANS_TYPE=$(GTT) +VERBOSITY_LEVEL=LOW optimized_debug_top_tb

silent_super: clean compile_sil
	vsim  -c -classdebug -msgmode both -do "set NoQuitOnFinish 1; run 40ms; exit" +GEN_TRANS_TYPE=$(GTT) +VERBOSITY_LEVEL=MEDIUM optimized_debug_top_tb > /dev/null
	@echo "********************************************************************************************"
	@echo "  "
	diff transcript transcript.bak
	
silent_max_verb: clean compile_sil
	vsim  -c -classdebug -msgmode both -do "set NoQuitOnFinish 1; run 40ms; exit" +GEN_TRANS_TYPE=$(GTT) +VERBOSITY_LEVEL=DEBUG optimized_debug_top_tb
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
	
merge_coverage:
	vcover merge -stats=none -strip 0 -totals sim_and_testplan_merged.ucdb ./*.ucdb 

report_coverage:
	vcover report -details -html -htmldir covhtmlreport -assert -directive -cvg -code bcefst -threshL 50 -threshH 90 ./sim_and_testplan_merged.ucdb

show_coverage:
	vsim -i -do "set NoQuitOnFinish 1;do load_ucdbs_and_merge_with_test_plan.do" &

clean_ucdb:
	rm *.ucdb

clean_covg:	clean_ucdb convert_testplan
	rm -rf ./covhtmlreport/

merge_coverage_with_test_plan: show_coverage

run_all_tests: silent2