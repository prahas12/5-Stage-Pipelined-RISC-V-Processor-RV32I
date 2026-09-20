# 5-Stage Pipelined RISC-V RV32I Processor

![Verilog](https://img.shields.io/badge/Verilog-2001-blue.svg)
![RISC-V](https://img.shields.io/badge/RISC--V-RV32I-red.svg)
![Vivado](https://img.shields.io/badge/Vivado-2025.2-orange.svg)
![License](https://img.shields.io/badge/License-MIT-green.svg)

This repository contains a synthesizable and mathematically robust implementation of a 32-bit RISC-V processor (RV32I Base Integer Instruction Set) using Verilog-2001. 

The processor is modeled after the classic architectural standards presented in Patterson & Hennessy's Computer Organization and Design RISC-V Edition. It is highly modularized, well-commented, completely free of Unknown (X) signal propagation, and is physically proven to synthesize and route on AMD/Xilinx Artix-7 FPGAs.

## Key Features

* Classic 5-Stage Pipeline: Instruction Fetch (IF), Instruction Decode (ID), Execute (EX), Memory (MEM), and Writeback (WB).
* Full Hazard Resolution: Hardware-level data hazard forwarding and load-use stalling to guarantee instruction integrity without software NOPs.
* Synthesizable Memory: Block RAM (BRAM) inferable Instruction and Data Memories.
* Distributed RAM Regfile: Write-first 32x32-bit Register File that infers highly efficient LUT-RAM.
* Zero X Propagation: Safely initializes unmapped memory and resolves all branches efficiently.

## Supported Instructions (37 Total)

This processor implements the complete RV32I Base Integer Instruction Set required to run standard C programs compiled via the RISC-V GCC toolchain.

* R-Type (Arithmetic & Logical): ADD, SUB, XOR, OR, AND, SLL, SRL, SRA, SLT, SLTU
* I-Type (Immediate Arithmetic): ADDI, XORI, ORI, ANDI, SLLI, SRLI, SRAI, SLTI, SLTIU
* I-Type & S-Type (Memory Access): LW (Load Word), SW (Store Word)
* B-Type (Branches): BEQ, BNE, BLT, BGE, BLTU, BGEU
* J-Type & I-Type (Jumps): JAL (Jump & Link), JALR (Jump & Link Register)
* U-Type (Upper Immediates): LUI (Load Upper Immediate), AUIPC (Add Upper Immediate to PC)

(Note: Sub-word memory accesses like LB/LH/SB/SH were intentionally omitted to maintain a 32-bit aligned block-RAM memory interface, optimizing for introductory FPGA synthesis).

## Architecture & Hazard Handling

### Pipeline Stages
1. IF (Instruction Fetch): The PC pulls the next instruction from imem.v. It defaults to PC+4 unless redirected by the EX stage.
2. ID (Instruction Decode): controller.v derives all pipeline control signals combinatorially. Source registers are fetched, and immediates are extended based on the instruction type.
3. EX (Execute): alu.v computes arithmetic and branch targets. Branch conditions are evaluated here.
4. MEM (Memory): Data is loaded from or stored to dmem.v on the clock edge.
5. WB (Writeback): The result is safely written back to the destination register.

### Hazard Resolution
* Data Hazards (RAW): A dedicated forwarding_unit.v multiplexes operands. If an instruction in EX needs a register currently being processed in MEM or WB, the data is forwarded instantly.
* Load-Use Hazards: The hazard_unit.v detects if an instruction in EX is a Load (LW) and its destination is needed by the ID stage. It safely stalls the IF and ID stages for 1 cycle and flushes the EX stage to insert a bubble.
* Control Hazards (Branches/Jumps): Because branch logic is evaluated in the EX stage, taking a branch incurs a 2-cycle penalty. The hazard_unit.v automatically flushes the two mistakenly fetched instructions in the IF and ID stages.

## Timing & Performance (Implementation Results)

The design has been thoroughly routed on an AMD/Xilinx Artix-7 (xc7a35tcpg236-1) FPGA using Vivado 2025.2. The exact physical routing and timing reports are included in the reports/ folder.

Implementation Timing Summary:
* Target Clock: 100 MHz (10.00 ns period)
* Worst Negative Slack (WNS): +1.720 ns
* Total Negative Slack (TNS): 0.000 ns
* Worst Hold Slack (WHS): +0.038 ns

Performance Metrics:
* Maximum Operating Frequency (Fmax): ~120.77 MHz 
* Critical Path: EX Stage -> D/E Pipeline Reg -> Forwarding Mux -> ALU -> E/M Pipeline Reg.
* Base CPI: 1.0 (excluding branches and load-stalls).

## Repository Structure

```text
├── rtl/                    # Synthesizable Verilog Source Code
│   ├── alu.v               # Arithmetic Logic Unit
│   ├── controller.v        # Main Control Unit
│   ├── core_top.v          # Top-level datapath & pipeline registers
│   ├── dmem.v              # Data Memory
│   ├── forwarding_unit.v   # Data Hazard Forwarding Unit
│   ├── hazard_unit.v       # Stall and Flush Logic
│   ├── imem.v              # Instruction Memory
│   ├── regfile.v           # 32x32-bit Register File
│   └── rv32i_defines.vh    # Constants and Opcode definitions
├── tb/                     # Verification
│   └── tb_core.v           # Self-checking testbench
├── reports/                # Post-Implementation metrics
│   └── timing_report.rpt   # Detailed exact Vivado timing report
├── vivado/                 # Vivado automation scripts
│   ├── constraints.xdc     # 100 MHz clock constraints
│   ├── create_gui_project.tcl # TCL script to generate .xpr project
│   └── run_simulation.bat  # One-click xsim simulation script
├── Makefile                # Icarus Verilog compilation script
└── LICENSE                 # MIT License
```

## How to Reproduce & Simulate

### 1. Using Xilinx Vivado (Recommended)
You can generate the project automatically using the provided TCL script in the vivado/ directory, or manually create a project, add the rtl/ and tb/ sources, and run synthesis/implementation.

### 2. Using Icarus Verilog (Command Line)
You can use the provided Makefile with Icarus Verilog:
```bash
make        # Compiles and runs the simulation
make wave   # Opens GTKWave to view the output
```

## License

This project is licensed under the MIT License - see the LICENSE file for details.
