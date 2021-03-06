package i2c_pkg;
  import i2c_types_pkg::*;
  import printing_pkg::*;
  import ncsu_pkg::*;
  `include "ncsu_macros.svh"

  `include "src/i2c_configuration.svh"
  `include "src/i2c_transaction.svh"
  `include "src/i2c_rand_cs_transaction.svh"
  `include "src/i2c_rand_data_transaction.svh"
  `include "src/i2c_arb_loss_transaction.svh"
  `include "src/i2c_coverage.svh"

  `include "src/i2c_driver.svh"
  `include "src/i2c_monitor.svh"

  `include "src/i2c_agent.svh"


endpackage
