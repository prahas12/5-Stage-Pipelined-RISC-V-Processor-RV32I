# Makefile for 5-Stage Pipelined RISC-V Processor

# Tools
IVERILOG = iverilog
VVP = vvp
GTKWAVE = gtkwave

# Directories
RTL_DIR = rtl
TB_DIR = tb

# Source files
RTL_SRCS = $(wildcard $(RTL_DIR)/*.v)
TB_SRCS = $(TB_DIR)/tb_core.v

# Output executable
OUT = simv

# Targets
all: compile run

compile:
	$(IVERILOG) -I $(RTL_DIR) -o $(OUT) $(RTL_SRCS) $(TB_SRCS)

run: compile
	$(VVP) $(OUT)

wave: run
	$(GTKWAVE) waveform.vcd &

clean:
	rm -f $(OUT) waveform.vcd

.PHONY: all compile run wave clean
