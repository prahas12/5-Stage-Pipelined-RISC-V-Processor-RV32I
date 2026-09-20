@echo off
echo =========================================================
echo Compiling Verilog files with Vivado xvlog...
echo =========================================================
xvlog ../rtl/alu.v ../rtl/controller.v ../rtl/core_top.v ../rtl/dmem.v ../rtl/forwarding_unit.v ../rtl/hazard_unit.v ../rtl/imem.v ../rtl/regfile.v ../tb/tb_core.v

echo.
echo =========================================================
echo Elaborating the design with xelab...
echo =========================================================
xelab -debug typical -top tb_core -snapshot tb_core_snapshot

echo.
echo =========================================================
echo Running Simulation and launching Vivado Waveform Viewer...
echo =========================================================
xsim tb_core_snapshot -gui
