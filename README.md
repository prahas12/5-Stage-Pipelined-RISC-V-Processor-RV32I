# 5-Stage Pipelined RISC-V Processor (RV32I)

A synthesizable **5-stage pipelined RISC-V processor** implementing the **RV32I Base Integer Instruction Set**, written in Verilog HDL.

This project was developed to understand the complete RTL design flow—from processor design and pipeline implementation to simulation, synthesis, and FPGA implementation using **Xilinx Vivado**.

---

## Pipeline Architecture

```
IF  →  ID  →  EX  →  MEM  →  WB
```

| Stage | Description |
|--------|-------------|
| **IF** | Fetch instruction and update Program Counter |
| **ID** | Decode instruction, read register file, generate immediate |
| **EX** | ALU execution, branch evaluation, forwarding logic |
| **MEM** | Data memory read/write operations |
| **WB** | Write results back to the register file |

---

## Features

- RV32I Base Integer Instruction Set
- Classic 5-stage pipelined architecture
- Data forwarding unit
- Load-use hazard detection
- Branch and jump handling
- Register file with synchronous write
- Instruction memory
- Data memory
- Fully synthesizable Verilog RTL
- Simulated, synthesized and implemented using Xilinx Vivado

---

## Repository Structure

```text
5-Stage-Pipelined-RISC-V-Processor-RV32I/
│
├── rtl/
│   ├── core_top.v
│   ├── alu.v
│   ├── decoder.v
│   ├── regfile.v
│   ├── imem.v
│   └── dmem.v
│
├── tb/
│   └── tb_core.v
│
├── constraints.xdc
│
├── README.md
├── LICENSE
└── .gitignore
```

---

# Simulation (Vivado)

Simulation was performed using the **Xilinx Vivado Simulator**.

1. Create a new RTL Project in Vivado.
2. Add all files from the `rtl/` directory.
3. Set `core_top.v` as the top module.
4. Add `tb/tb_core.v` under **Simulation Sources**.
5. Run **Behavioral Simulation**.
6. Observe the pipeline execution using the waveform viewer.

---

## Vivado Design Flow

```
RTL Design
     │
     ▼
Behavioral Simulation
     │
     ▼
Synthesis
     │
     ▼
RTL Schematic
     │
     ▼
Implementation
     │
     ▼
Device View
```

---

## Tools Used

- Verilog HDL
- Xilinx Vivado
- Xilinx Artix-7 FPGA

---

## Future Improvements

- Branch prediction
- CSR support
- Interrupt handling
- RV32M Extension
- Instruction and Data Cache
- AXI Interface

---

## License

This project is released under the **MIT License**.
