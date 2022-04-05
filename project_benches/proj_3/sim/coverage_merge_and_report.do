# coverage attribute -name TESTNAME -value test_name
# coverage save test_name.$Sv_Seed.ucdb
xml2ucdb -format Excel ./i2cmb_test_plan.xml ./i2cmb_test_plan.ucdb
add testbrowser ./*.ucdb
vcover merge -stats=none -strip 0 -totals sim_and_testplan_merged.ucdb ./*.ucdb 
coverage open ./sim_and_testplan_merged.ucdb
vcover report -detail -html -output covhtmlreport -assert -directive -cvg -code bcefst -threshL 50 -threshH 90 ./sim_and_testplan_merged.ucdb
