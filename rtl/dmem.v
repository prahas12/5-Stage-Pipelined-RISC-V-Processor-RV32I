`timescale 1ns / 1ps

module dmem #(parameter DEPTH = 256) (
    input  wire        clk,
    input  wire        we,
    input  wire [31:0] a,
    input  wire [31:0] wd,
    output wire [31:0] rd
);

    reg [31:0] ram [0:DEPTH-1];

    integer i;
    initial begin
        for (i = 0; i < DEPTH; i = i + 1)
            ram[i] = 32'd0;
    end

    // Simple word-aligned read and write
    assign rd = ram[a[31:2]];

    always @(posedge clk) begin
        if (we) begin
            ram[a[31:2]] <= wd;
        end
    end

endmodule
