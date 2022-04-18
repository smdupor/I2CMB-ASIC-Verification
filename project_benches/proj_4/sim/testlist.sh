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
# NAME:test_single_bus_default_speed            # Test on a single-bus instatiation
#   TEST_SEED := 65989
#   GTT := i2cmb_generator_test_single_bus
#
# NAME:test_multi_bus_max_speed                 #Test with all busses at 400kHz
#   TEST_SEED := 37915
#   GTT := i2cmb_generator_test_multi_bus
#
# NAME:test_multi_bus_ranged_speed              #Test with busses cfg'd from 400kHz to 40kHz in same instantiation
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
# NAME:i2cmb_generator_arb_loss_restart   -- Check the restart edge case
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
# NAME: test_hard_reset_injection
#	TEST_SEED := 12345
#   TN := test_hard_reset_injection
#	GTT := i2cmb_generator_test_resets
#
# NAME:test_multi_bus_slow_speed                #Test with all 16 busses < 100kHz default rate to cover bus conditioner slow branches.
#   TEST_SEED := 86753
#   GTT := i2cmb_generator_test_multi_bus_slow
#
#
#
#
#
#
start=$SECONDS
make run_all_tests
make mulbus_slow
duration=$(( SECONDS - start ))
echo " "
echo " "
echo " "
echo " "
echo "***************************************************************************************************"
echo "***************************************************************************************************"
echo "    TEST RUNTIME INFORMATION:"
echo " "
echo " TEST SUITE RAN IN $duration seconds."
echo " "
echo "***************************************************************************************************"
echo "***************************************************************************************************"