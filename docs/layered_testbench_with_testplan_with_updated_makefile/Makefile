GEN_TRANS_TYPE ?= abc_transaction_base
TEST_SEED ?= 12345

clean:
	rm -rf work

compile:
	vlog +incdir+ncsu_pkg ncsu_pkg/ncsu_pkg.sv
	vlog +incdir+ncsu_pkg +incdir+abc_pkg abc_pkg/abc_pkg.sv
	vlog abc_pkg/src/abc_if.sv
	vlog +incdir+ncsu_pkg +incdir+first_project_pkg first_project_pkg/first_project_pkg.sv
	vlog first_dut/first_dut.sv
	vlog top.sv

optimize:
	vopt +acc top -o optimized_debug_top_tb

run_cli:
	vsim  -c -sv_seed $(TEST_SEED) -do "set NoQuitOnFinish 1; run -a; coverage attribute -name TESTNAME -value $(GEN_TRANS_TYPE); coverage save $(GEN_TRANS_TYPE).$(TEST_SEED).ucdb; quit -f" +GEN_TRANS_TYPE=$(GEN_TRANS_TYPE) optimized_debug_top_tb

run_gui:
	vsim  -sv_seed $(TEST_SEED) -do "do wave.do;run -a" +GEN_TRANS_TYPE=$(GEN_TRANS_TYPE) optimized_debug_top_tb

cli: clean compile optimize run_cli

debug: clean compile optimize run_gui

convert_testplan:
	xml2ucdb -format Excel ./test_plan_layered_testbench.xml ./test_plan_layered_testbench.ucdb
	add testbrowser ./*.ucdb
merge_coverage:
	vcover merge -stats=none -strip 0 -totals sim_and_testplan_merged.ucdb ./*.ucdb 
	coverage open ./sim_and_testplan_merged.ucdb

report_coverage:
	vcover report -details -html -htmldir covhtmlreport -assert -directive -cvg -code bcefst -threshL 50 -threshH 90 ./sim_and_testplan_merged.ucdb
