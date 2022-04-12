xml2ucdb -format Excel ./i2cmb_test_plan.xml ./i2cmb_test_plan.ucdb
vcover merge -stats=none -strip 0 -totals sim_and_testplan_merged.ucdb ./*.ucdb 
add testbrowser ./*.ucdb
#add testbrowser ./sim_and_testplan_merged.ucdb
coverage open ./sim_and_testplan_merged.ucdb
rm -rf ./covhtmlreport/
vcover report -detail -html -output covhtmlreport -assert -directive -cvg -code bcefst -threshL 50 -threshH 90 ./sim_and_testplan_merged.ucdb
