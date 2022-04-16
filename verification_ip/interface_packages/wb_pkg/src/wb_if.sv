`timescale 1ns / 10ps

interface wb_if #(
    int ADDR_WIDTH = 2,
    int DATA_WIDTH = 8
) (

    // System sigals
    input wire clk_i,
    input wire rst_i,
    output tri rst_o,
    input wire irq_i,
    // Master signals
    output reg cyc_o,
    output reg stb_o,
    input wire ack_i,
    output reg [ADDR_WIDTH-1:0] adr_o,
    output reg we_o,
    // Slave signals
    input wire cyc_i,
    input wire stb_i,
    output reg ack_o,
    input wire [ADDR_WIDTH-1:0] adr_i,
    input wire we_i,
    // Shred signals
    output reg [DATA_WIDTH-1:0] dat_o,
    input wire [DATA_WIDTH-1:0] dat_i
);
  import wb_types_pkg::*;

  int num_clocks;
  always @(posedge clk_i)++num_clocks;

  bit disable_interrupts;
  logic hard_resetter;
  assign rst_o = hard_resetter;

  always @(posedge clk_i) begin
    if (disable_interrupts) begin
      assertion_expect_NO_interrupt_when_disabled :
      assert (irq_i == 1'b0)
      else $error("Assertion assertion_expect_NO_interrupt_when_disabled Failed! ");
    end
  end

  initial reset_bus();

  task force_hard_reset();
    hard_resetter <= 1'b1;
    #133 hard_resetter <= 1'b0;
  endtask

  task disable_rst_driver();
    hard_resetter <= 1'bz;
  endtask

  // ****************************************************************************              
  task wait_for_reset();
    if (rst_i !== 0) @(negedge rst_i);
  endtask

  // ****************************************************************************              
  task wait_for_num_clocks(int num_clocks);
    repeat (num_clocks) @(posedge clk_i);
  endtask

  // ****************************************************************************              
  task reset_bus();
    cyc_o <= 1'b0;
    stb_o <= 1'b0;
    we_o  <= 1'b0;
    adr_o <= 'b0;
    dat_o <= 'b0;
  endtask

  // ****************************************************************************              
  task master_write(input bit [ADDR_WIDTH-1:0] addr, input bit [DATA_WIDTH-1:0] data);
  
    @(posedge clk_i);
    adr_o <= addr;
    dat_o <= data;
    cyc_o <= 1'b1;
    stb_o <= 1'b1;
    we_o  <= 1'b1;
    while (!ack_i) @(posedge clk_i);
    cyc_o <= 1'b0;
    stb_o <= 1'b0;
    adr_o <= 'bx;
    dat_o <= 'bx;
    we_o  <= 1'b0;
    @(posedge clk_i);

  endtask

  // ****************************************************************************              
  task master_read(input bit [ADDR_WIDTH-1:0] addr, output bit [DATA_WIDTH-1:0] data);

    @(posedge clk_i);
    adr_o <= addr;
    dat_o <= 'bx;
    cyc_o <= 1'b1;
    stb_o <= 1'b1;
    we_o  <= 1'b0;
    @(posedge clk_i);
    while (!ack_i) @(posedge clk_i);
    cyc_o <= 1'b0;
    stb_o <= 1'b0;
    adr_o <= 'bx;
    dat_o <= 'bx;
    we_o  <= 1'b0;
    data = dat_i;

  endtask

  // ****************************************************************************              
  task master_monitor(output bit [ADDR_WIDTH-1:0] addr, output bit [DATA_WIDTH-1:0] data,
                      output bit we);

    while (!cyc_o) @(posedge clk_i);
    while (!ack_i) @(posedge clk_i);
    addr = adr_o;
    we   = we_o;
    if (we_o) begin
      data = dat_o;
    end else begin
      data = dat_i;
    end
    while (cyc_o) @(posedge clk_i);
  endtask

  // ****************************************************************************
  // Wait for, and clear, interrupt rising from WB-end of DUT. 
  // Do not check incoming status bits.
  // ****************************************************************************
  task wait_interrupt();
    wait (irq_i == 1'b1);
    if (!disable_interrupts) begin
      assertion_expect_interrupt_when_enabled :
      assert (irq_i == 1'b1)
      else $error("Assertion assertion_expect_NO_interrupt_when_disabled Failed! ");
    end
  endtask
endinterface
