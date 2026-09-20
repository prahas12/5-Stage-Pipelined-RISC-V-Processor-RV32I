# 100 MHz clock constraint (10.00 ns period)
create_clock -period 10.000 -name clk -waveform {0.000 5.000} [get_ports clk]

# Optional: Since rst_n is an asynchronous input, we can set it as a false path 
# so the timing analyzer doesn't flag it as an unconstrained setup/hold violation.
set_false_path -from [get_ports rst_n]
