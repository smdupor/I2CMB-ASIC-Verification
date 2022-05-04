# I2CMB-ASIC-Verification
Implemented ASIC Verification project in SystemVerilog for a Wishbone to I2C Multiple Bus ASIC, including interfaces, testbench/sequencers/predictor/scoreboard, and testplan, closing to 99% coverage. 

The I2CMB Core VHDL code was generously provided by [OpenCores: IICMB](https://opencores.org/projects/iicmb). 

## Project Scope:
The project consisted of four stages: creating of I2c and Wishbone Interfaces, writing a complete testbench (UVM-Inspired, but simplified), creating a testplan formatted for Mentor Questasim, and creating sequencers ("generators") to close coverage.

## Results (Overall Coverage)
Through analysis of the DUT Specifications, a testplan consisting of 99 line items covering all critical functionality was created. Coverage across all of these individual items was closed to 100% via directed and random testing. The vast majority of device features were extensively testing, with the only exception being Wishbone multi-master selection: the cumulative code coverage for the DUT reached 89.47%. 

![Snapshot of overall testplan coverage](https://github.com/smdupor/I2CMB-ASIC-Verification/blob/master/docs/smdupor_expected_coverage_screenshot.jpg)

## Results (FSM Coverage)
Via analysis of the original source, the DUT specification, and assistance from the QuestaSim FSM tool, FSM state and transition coverage was closed to 100% for all FSMs within the DUT. Directed tests were used to confirm the states only reachable via hard reset were successfully exited and followed by normal operation.

### Byte-Level FSM
The top-level FSM, the "byte-level" is responsible for controlling the device based on commands from the Wishbone interface.

![Byte Level FSM](https://github.com/smdupor/I2CMB-ASIC-Verification/blob/master/docs/byte.jpg)

### Bit-Level FSM
The lower-level FSM is driven by output from the byte-level FSM, and is responsible for sending/receiving single I2C bits and managing correctness, arbitration, and error status. 

![Bit Level FSM](https://github.com/smdupor/I2CMB-ASIC-Verification/blob/master/docs/bit.jpg)

Ultimately, this project proved to be a highly fulfilling and interesting excercise, with ample opportunity to self-govern and self-motivate towards maximizing testplan depth and DUT coverage.
