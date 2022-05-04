package i2cmb_env_pkg;

  import ncsu_pkg::*;
  import printing_pkg::*;
  import i2c_types_pkg::*;
  import wb_types_pkg::*;
  import i2c_pkg::*;
  import wb_pkg::*;

  `include "ncsu_macros.svh"

  `include "src/i2cmb_env_configuration.svh"

  `include "src/i2cmb_predictor.svh"
  `include "src/i2cmb_predictor_regblock.svh"
  `include "src/i2cmb_coverage.svh"
  `include "src/i2cmb_scoreboard.svh"
  `include "src/i2cmb_environment.svh"

  `include "src/i2cmb_generator.svh"
  `include "src/i2cmb_generator_test_resets.svh"
  `include "src/i2cmb_generator_test_reg.svh"
  `include "src/i2cmb_generator_arb_loss.svh"
  `include "src/i2cmb_generator_arb_loss_restart.svh"
  `include "src/i2cmb_generator_interrupt_cycling.svh"
  `include "src/i2cmb_generator_test_multi_bus_clockstretch.svh"
  `include "src/i2cmb_generator_test_multi_bus.svh"
    `include "src/i2cmb_generator_test_multi_bus_slow.svh"
  `include "src/i2cmb_generator_test_multi_bus_ranged.svh"
  `include "src/i2cmb_generator_test_single_bus.svh"
  `include "src/i2cmb_generator_disconnected_slave.svh"

  `include "src/i2cmb_test.svh"


endpackage
