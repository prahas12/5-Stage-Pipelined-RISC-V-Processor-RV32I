`timescale 1ns / 1ps

module imem #(parameter DEPTH = 256) (
    input  wire [31:0] a,
    output wire [31:0] rd
);

    reg [31:0] ram [0:DEPTH-1];

    integer i;
    initial begin
        for (i = 0; i < DEPTH; i = i + 1)
            ram[i] = 32'd0;
        $readmemh("imem_init.hex", ram);
    end

    // Word aligned read
    assign rd = ram[a[31:2]];

endmodule
