`timescale 1ns / 1ps

module forwarding_unit (
    input  wire [4:0] rs1_e,
    input  wire [4:0] rs2_e,
    input  wire [4:0] rd_m,
    input  wire       reg_write_m,
    input  wire [4:0] rd_w,
    input  wire       reg_write_w,
    output reg  [1:0] forward_a_e,
    output reg  [1:0] forward_b_e
);

    // Forwarding to ALU input A
    always @(*) begin
        if (reg_write_m && (rd_m != 0) && (rd_m == rs1_e)) begin
            forward_a_e = 2'b10; // Forward from MEM stage
        end else if (reg_write_w && (rd_w != 0) && (rd_w == rs1_e)) begin
            forward_a_e = 2'b01; // Forward from WB stage
        end else begin
            forward_a_e = 2'b00; // No forwarding
        end
    end

    // Forwarding to ALU input B
    always @(*) begin
        if (reg_write_m && (rd_m != 0) && (rd_m == rs2_e)) begin
            forward_b_e = 2'b10;
        end else if (reg_write_w && (rd_w != 0) && (rd_w == rs2_e)) begin
            forward_b_e = 2'b01;
        end else begin
            forward_b_e = 2'b00;
        end
    end

endmodule
