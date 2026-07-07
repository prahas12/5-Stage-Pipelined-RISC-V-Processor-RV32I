## defines the 100 MHz system clock so Vivado can actually run timing analysis
## (without this, every register shows up as a "not reached by a timing clock"
## bad-practice warning, since the tool has no clock to check against)
create_clock -period 10.000 -name sys_clk -waveform {0.000 5.000} [get_ports clk]

## rst_n is asserted for a handful of cycles at power-up and otherwise stays
## high - it's not a timing-critical path, so exclude it from setup/hold checks
set_false_path -from [get_ports rst_n]
