onerror {resume}
quietly set PrefSource(OpenOnBreak) 0
quietly set PrefSource(OpenOnFinish) 0
quietly set PrefSource(OpenOnStep) 0
quietly WaveActivateNextPane {} 0
add wave -noupdate -divider I2C_MB
add wave -noupdate -divider {WB Signals}
add wave -noupdate /top/DUT_16_max/clk_i
add wave -noupdate /top/DUT_16_max/rst_i
add wave -noupdate /top/DUT_16_max/rst_o
add wave -noupdate /top/DUT_16_max/cyc_i
add wave -noupdate /top/DUT_16_max/stb_i
add wave -noupdate /top/DUT_16_max/ack_o
add wave -noupdate /top/DUT_16_max/adr_i
add wave -noupdate /top/DUT_16_max/we_i
add wave -noupdate /top/DUT_16_max/dat_i
add wave -noupdate /top/DUT_16_max/dat_o
add wave -noupdate /top/DUT_16_max/irq
add wave -noupdate -divider {I2C System-Wide Signals}
add wave -noupdate /top/DUT_16_max/scl_i
add wave -noupdate -expand /top/DUT_16_max/sda_i
add wave -noupdate /top/DUT_16_max/scl_o
add wave -noupdate /top/DUT_16_max/sda_o
add wave -noupdate -divider {I2C Slave BFM Driver Internal Signals}
add wave -noupdate /top/i2c_bus/driver_interrupt
add wave -noupdate /top/i2c_bus/driver_buffer
add wave -noupdate -expand /top/i2c_bus/sda_drive
add wave -noupdate /top/i2c_bus/sda_o
TreeUpdate [SetDefaultTree]
WaveRestoreCursors {{Cursor 1} {0 ns} 0}
quietly wave cursor active 0
configure wave -namecolwidth 263
configure wave -valuecolwidth 100
configure wave -justifyvalue left
configure wave -signalnamewidth 0
configure wave -snapdistance 10
configure wave -datasetprefix 0
configure wave -rowmargin 4
configure wave -childrowmargin 2
configure wave -gridoffset 0
configure wave -gridperiod 1
configure wave -griddelta 40
configure wave -timeline 0
configure wave -timelineunits ns
update
WaveRestoreZoom {0 ms} {34 ms}
