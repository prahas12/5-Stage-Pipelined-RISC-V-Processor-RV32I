# Vivado Tcl Script to Automate Synthesis and Timing Report Generation

# 1. Create a new Vivado Project in the current directory (targeting an Artix-7 FPGA)
create_project rv32i_timing_proj ./vivado_project -part xc7a35tcpg236-1 -force

# 2. Add RTL Source Files
add_files ../rtl/alu.v
add_files ../rtl/controller.v
add_files ../rtl/core_top.v
add_files ../rtl/dmem.v
add_files ../rtl/forwarding_unit.v
add_files ../rtl/hazard_unit.v
add_files ../rtl/imem.v
add_files ../rtl/regfile.v
add_files ../rtl/rv32i_defines.vh
add_files ../rtl/imem_init.hex

# 3. Add Timing Constraints
add_files -fileset constrs_1 ./constraints.xdc

# 4. Set the top module
set_property top core_top [current_fileset]

# 5. Run Synthesis
puts "========================================================="
puts "Running Synthesis..."
puts "========================================================="
launch_runs synth_1 -jobs 4
wait_on_run synth_1

# 6. Open Synthesized Design and Extract Timing
open_run synth_1 -name synth_1
report_timing_summary -file post_synth_timing.txt
puts "Created: post_synth_timing.txt"

# 7. Run Implementation (Placement & Routing) to get exact physical delays
puts "========================================================="
puts "Running Implementation..."
puts "========================================================="
launch_runs impl_1 -jobs 4
wait_on_run impl_1

# 8. Open Implemented Design and Extract Final Exact Timing
open_run impl_1 -name impl_1
report_timing_summary -file post_impl_timing.txt
puts "Created: post_impl_timing.txt"

puts "========================================================="
puts "SUCCESS: Exact Timing Reports have been generated!"
puts "Please check the 'vivado' folder for post_impl_timing.txt"
puts "========================================================="
