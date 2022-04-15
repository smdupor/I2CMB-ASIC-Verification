#!/bin/bash
#           Test list for STEVAN DUPOR smdupor@ncsu.edu
#
# Note: I highly recommend running this file as a script via ./testlist.sh
#
#
# NAME : test_register_block
#   TEST_SEED := 65989
#   GTT := i2cmb_generator_test_reg
#
# NAME:test_single_bus_default_speed
#   TEST_SEED := 65989
#   GTT := i2cmb_generator_test_single_bus
#
# NAME:test_multi_bus_max_speed
#   TEST_SEED := 37915
#   GTT := i2cmb_generator_test_multi_bus
#
# NAME:test_multi_bus_ranged_speed
#   TEST_SEED := 54321
#   GTT := i2cmb_generator_test_multi_bus_ranged
#
# NAME:test_clockstretching
#   TEST_SEED := 12345
#   GTT := i2cmb_generator_test_multi_bus_clockstretch
#
# NAME:test_arbitration_lost_scenario
#   TEST_SEED := 12345
#   GTT := i2cmb_generator_arb_loss
#
# NAME:test_enable_disable_enable_intr_x_poll
#   TEST_SEED := 98765
#   GTT := i2cmb_generator_interrupt_cycling
#
# NAME:test_disconnected_slave_nacks
#   TEST_SEED := 12345
#   GTT := i2cmb_generator_disconnected_slave
#
make run_all_tests
echo " "
echo " "
echo " "
echo " "
echo "***************************************************************************************************"
echo "***************************************************************************************************"
echo "    TEST RUNTIME INFORMATION:"
echo " "
cat .timelog
echo "***************************************************************************************************"
echo "***************************************************************************************************"