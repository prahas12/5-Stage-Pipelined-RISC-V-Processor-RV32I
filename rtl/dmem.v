`timescale 1ns/1ps
// simple synchronous data memory, only word accesses supported (lw/sw)
module dmem #(
    parameter DEPTH = 256
)(
    input  wire        clk,
    input  wire         mem_read,
    input  wire         mem_write,
    /* verilator lint_off UNUSED */
    input  wire [31:0] addr,
    /* verilator lint_on UNUSED */
    input  wire [31:0] wdata,
    output wire [31:0] rdata
);

    reg [31:0] mem [0:DEPTH-1];
    integer i;

    initial begin
        for (i = 0; i < DEPTH; i = i + 1)
            mem[i] = 32'h0;
    end

    always @(posedge clk) begin
        if (mem_write)
            mem[addr[$clog2(DEPTH)+1:2]] <= wdata;
    end

    // combinational read, simpler for a teaching pipeline than adding a bypass
    assign rdata = mem_read ? mem[addr[$clog2(DEPTH)+1:2]] : 32'h0;

endmodule
