`timescale 1ns / 1ps

module regfile (
    input  wire        clk,
    input  wire        we3,
    input  wire [4:0]  a1,
    input  wire [4:0]  a2,
    input  wire [4:0]  a3,
    input  wire [31:0] wd3,
    output wire [31:0] rd1,
    output wire [31:0] rd2
);

    reg [31:0] rf [31:0];
    integer i;

    initial begin
        for (i = 0; i < 32; i = i + 1) begin
            rf[i] = 32'd0;
        end
    end

    // Three ported register file
    // read two ports combinationally
    // write third port on falling edge of clock to allow write-then-read in same cycle (avoids need for internal forwarding)
    // or we can use normal rising edge and forward internally. Let's use rising edge to be standard and forward externally if needed.
    
    always @(posedge clk) begin
        if (we3 && a3 != 5'd0) begin
            rf[a3] <= wd3;
        end
    end

    // Internal forwarding if reading the same register being written (Write-First logic)
    assign rd1 = (a1 != 5'd0) ? ((a1 == a3 && we3) ? wd3 : rf[a1]) : 32'd0;
    assign rd2 = (a2 != 5'd0) ? ((a2 == a3 && we3) ? wd3 : rf[a2]) : 32'd0;

endmodule
