# 5-Stage Pipelined RISC-V Processor (RV32I)

A classic 5-stage pipelined CPU implementing the RV32I base integer instruction set,
written in synthesizable Verilog. Built as a learning project to actually understand
the mechanics of pipelining — hazard detection, forwarding, and control flow flushing —
instead of just reading about them.

## Pipeline stages

```
IF  ->  ID  ->  EX  ->  MEM  ->  WB
```

- **IF**  – fetch instruction from instruction memory, increment PC
- **ID**  – decode instruction, read register file, generate immediate
- **EX**  – ALU operation, forwarding muxes, branch/jump resolution
- **MEM** – load/store to data memory
- **WB**  – write result back to the register file

## Features

- Full RV32I base integer instructions: R-type, I-type, loads/stores, branches, JAL/JALR, LUI/AUIPC
- Data forwarding (EX/MEM -> EX and MEM/WB -> EX) to remove most stalls
- Load-use hazard detection with a single-cycle stall
- Branches and jumps resolved in EX, with a 2-cycle flush of IF/ID and ID/EX on a taken branch/jump
- Write-first register file (write and read of the same register in one cycle behaves correctly)
- Clean synthesizable RTL — no vendor primitives, should map to any FPGA toolchain

## Repo layout

```
rtl/     core RTL: regfile, alu, decoder, imem, dmem, core_top
tb/      testbench (tb_core.v) with clock/reset gen and a register dump at the end
sim/     scratch folder simulation runs write into (waves.vcd shows up here)
scripts/ asm.py (encodes the test program into imem_init.hex), run_sim.sh
constraints/ constraints.xdc
docs/    notes on the microarchitecture
```

## Running the simulation

Requires [Icarus Verilog](http://iverilog.icarus.com/):

```bash
make sim
```

or directly:

```bash
bash scripts/run_sim.sh
```

This compiles the RTL + testbench, runs the built-in test program, prints a register
dump, and writes `sim/waves.vcd`. Open it with:

```bash
gtkwave sim/waves.vcd
```

## The test program

`rtl/imem_init.hex` is pre-assembled machine code (see `scripts/asm.py` for the source
and encoder) that deliberately exercises every hazard case:

| what it tests            | instructions                                   |
|---------------------------|------------------------------------------------|
| back-to-back ALU forwarding | `addi x1,x0,5` / `addi x2,x0,10` / `add x3,x1,x2` |
| MEM-stage forwarding      | `sub x4,x3,x1`                                  |
| store / load               | `sw x3,0(x0)` / `lw x5,0(x0)`                   |
| load-use stall             | `add x6,x5,x1` right after the load             |
| taken branch + flush       | `beq x1,x1,...` jumping over two dead instructions |
| not-taken branch           | `bne x1,x1,...`                                 |
| jal + link register        | `jal x8,...`                                    |
| backwards branch loop      | `blt` counting a register up in a small loop    |

Expected final register values are documented at the top of `tb/tb_core.v`'s companion
run — `x1..x11`, `x20..x22` all land on predictable values if the pipeline is behaving.

## Synthesizing / getting a schematic + device utilization

The RTL is plain, portable Verilog with no vendor-specific primitives, so it drops
into Vivado, Quartus, or any other FPGA toolchain as a new project:

1. Add every file in `rtl/` as a source, `core_top.v` as the top module
2. Add `tb/tb_core.v` as a simulation-only source for behavioral sim
3. Run synthesis to get the schematic / RTL view
4. Run implementation against your target device for utilization + timing reports

## Possible extensions

- Branch prediction (static or a simple BHT) to cut the control hazard penalty
- CSR support and a basic trap/interrupt path
- Byte/halfword load-store variants (`lb`, `lh`, `sb`, `sh`)
- Instruction/data cache in front of imem/dmem
