`timescale 1ns/1ps
// instruction memory, word addressed, loaded at sim start from a hex file
module imem #(
    parameter DEPTH = 256
)(
    /* verilator lint_off UNUSED */
    input  wire [31:0] addr,
    /* verilator lint_on UNUSED */
    output wire [31:0] rdata
);

    reg [31:0] mem [0:DEPTH-1];

    initial begin
        $readmemh("imem_init.hex", mem);
    end

    // word aligned access, byte address in, only the bits that actually
    // index our depth are used (avoids a needless wide-to-narrow warning)
    assign rdata = mem[addr[$clog2(DEPTH)+1:2]];

endmodule
