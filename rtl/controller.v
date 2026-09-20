`timescale 1ns / 1ps
`include "rv32i_defines.vh"

module controller (
    input  wire [6:0] op,
    input  wire [2:0] funct3,
    input  wire       funct7b5,
    output wire       reg_write,
    output wire [1:0] result_src,
    output wire       mem_write,
    output wire       jump,
    output wire       branch,
    output wire       alu_src,
    output wire [3:0] alu_control,
    output wire [2:0] imm_src
);

    reg [1:0] alu_op;
    reg       r_reg_write;
    reg [1:0] r_result_src;
    reg       r_mem_write;
    reg       r_jump;
    reg       r_branch;
    reg       r_alu_src;
    reg [2:0] r_imm_src;

    always @(*) begin
        // Default values
        r_reg_write  = 1'b0;
        r_result_src = 2'b00;
        r_mem_write  = 1'b0;
        r_jump       = 1'b0;
        r_branch     = 1'b0;
        r_alu_src    = 1'b0;
        r_imm_src    = 3'b000;
        alu_op       = 2'b00;

        case (op)
            `OPCODE_LOAD: begin
                r_reg_write  = 1'b1;
                r_result_src = `RES_MEM;
                r_alu_src    = 1'b1;
                r_imm_src    = 3'b000; // I-type
                alu_op       = 2'b00;  // ADD
            end
            `OPCODE_STORE: begin
                r_mem_write  = 1'b1;
                r_alu_src    = 1'b1;
                r_imm_src    = 3'b001; // S-type
                alu_op       = 2'b00;  // ADD
            end
            `OPCODE_R_TYPE: begin
                r_reg_write  = 1'b1;
                r_result_src = `RES_ALU;
                alu_op       = 2'b10;  // Decode funct
            end
            `OPCODE_I_TYPE: begin
                r_reg_write  = 1'b1;
                r_result_src = `RES_ALU;
                r_alu_src    = 1'b1;
                r_imm_src    = 3'b000; // I-type
                alu_op       = 2'b10;  // Decode funct
            end
            `OPCODE_BRANCH: begin
                r_branch     = 1'b1;
                r_imm_src    = 3'b010; // B-type
                alu_op       = 2'b01;  // SUB
            end
            `OPCODE_JAL: begin
                r_reg_write  = 1'b1;
                r_result_src = `RES_PC;
                r_jump       = 1'b1;
                r_imm_src    = 3'b011; // J-type
            end
            `OPCODE_JALR: begin
                r_reg_write  = 1'b1;
                r_result_src = `RES_PC;
                r_jump       = 1'b1;
                r_alu_src    = 1'b1;
                r_imm_src    = 3'b000; // I-type
                alu_op       = 2'b00; // ADD for target calc
            end
            `OPCODE_LUI: begin
                r_reg_write  = 1'b1;
                r_result_src = `RES_IMM;
                r_imm_src    = 3'b100; // U-type
            end
            `OPCODE_AUIPC: begin
                r_reg_write  = 1'b1;
                r_result_src = `RES_ALU;
                r_alu_src    = 1'b1;
                r_imm_src    = 3'b100; // U-type
                alu_op       = 2'b00;  // ADD PC+imm
            end
            default: ;
        endcase
    end

    // ALU Decoder
    reg [3:0] r_alu_control;
    always @(*) begin
        case (alu_op)
            2'b00: r_alu_control = `ALU_ADD;
            2'b01: r_alu_control = `ALU_SUB;
            2'b10: begin // R-type or I-type ALU
                case (funct3)
                    3'b000: r_alu_control = (op == `OPCODE_R_TYPE && funct7b5) ? `ALU_SUB : `ALU_ADD;
                    3'b010: r_alu_control = `ALU_SLT;
                    3'b011: r_alu_control = `ALU_SLTU;
                    3'b100: r_alu_control = `ALU_XOR;
                    3'b110: r_alu_control = `ALU_OR;
                    3'b111: r_alu_control = `ALU_AND;
                    3'b001: r_alu_control = `ALU_SLL;
                    3'b101: r_alu_control = (funct7b5) ? `ALU_SRA : `ALU_SRL;
                    default: r_alu_control = `ALU_NONE;
                endcase
            end
            default: r_alu_control = `ALU_NONE;
        endcase
    end

    assign reg_write   = r_reg_write;
    assign result_src  = r_result_src;
    assign mem_write   = r_mem_write;
    assign jump        = r_jump;
    assign branch      = r_branch;
    assign alu_src     = r_alu_src;
    assign imm_src     = r_imm_src;
    assign alu_control = r_alu_control;

endmodule
