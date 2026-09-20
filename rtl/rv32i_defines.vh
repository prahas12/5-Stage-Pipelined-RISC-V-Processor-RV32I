`ifndef RV32I_DEFINES_VH
`define RV32I_DEFINES_VH

// Opcodes
`define OPCODE_R_TYPE  7'b0110011
`define OPCODE_I_TYPE  7'b0010011
`define OPCODE_LOAD    7'b0000011
`define OPCODE_STORE   7'b0100011
`define OPCODE_BRANCH  7'b1100011
`define OPCODE_LUI     7'b0110111
`define OPCODE_AUIPC   7'b0010111
`define OPCODE_JAL     7'b1101111
`define OPCODE_JALR    7'b1100111

// ALU Operations
`define ALU_ADD   4'b0000
`define ALU_SUB   4'b1000
`define ALU_SLL   4'b0001
`define ALU_SLT   4'b0010
`define ALU_SLTU  4'b0011
`define ALU_XOR   4'b0100
`define ALU_SRL   4'b0101
`define ALU_SRA   4'b1101
`define ALU_OR    4'b0110
`define ALU_AND   4'b0111
`define ALU_NONE  4'b1111

// Branch Types
`define BR_BEQ    3'b000
`define BR_BNE    3'b001
`define BR_BLT    3'b100
`define BR_BGE    3'b101
`define BR_BLTU   3'b110
`define BR_BGEU   3'b111

// Result Source (Mem to Reg)
`define RES_ALU   2'b00
`define RES_MEM   2'b01
`define RES_PC    2'b10
`define RES_IMM   2'b11

`endif // RV32I_DEFINES_VH
