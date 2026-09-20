# Creates the Vivado GUI project
create_project RV32I_Processor ./vivado_project -part xc7a35tcpg236-1 -force

# Add RTL files
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

# Add constraints
add_files -fileset constrs_1 ./constraints.xdc

# Add simulation testbench
add_files -fileset sim_1 ../tb/tb_core.v

# Set top modules
set_property top core_top [current_fileset]
set_property top tb_core [get_filesets sim_1]

# Save and exit so the batch script can open it
exit
