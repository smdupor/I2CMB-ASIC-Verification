package i2c_types_pkg;

  // Passable enum indicating type of I2C operation between testbench and I2C_interface
  typedef enum bit {
    I2_WRITE = 1'b0,
    I2_READ  = 1'b1
  } i2c_op_t;

endpackage
