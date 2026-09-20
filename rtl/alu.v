`timescale 1ns / 1ps
`include "rv32i_defines.vh"

module alu (
    input  wire [31:0] a,
    input  wire [31:0] b,
    input  wire [3:0]  alu_control,
    output reg  [31:0] result,
    output wire        zero
);

    always @(*) begin
        case (alu_control)
            `ALU_ADD:  result = a + b;
            `ALU_SUB:  result = a - b;
            `ALU_SLL:  result = a << b[4:0];
            `ALU_SLT:  result = ($signed(a) < $signed(b)) ? 32'd1 : 32'd0;
            `ALU_SLTU: result = (a < b) ? 32'd1 : 32'd0;
            `ALU_XOR:  result = a ^ b;
            `ALU_SRL:  result = a >> b[4:0];
            `ALU_SRA:  result = $signed(a) >>> b[4:0];
            `ALU_OR:   result = a | b;
            `ALU_AND:  result = a & b;
            default:   result = 32'd0;
        endcase
    end

    assign zero = (result == 32'd0);

endmodule
