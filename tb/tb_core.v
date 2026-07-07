`timescale 1ns/1ps

module tb_core;

    reg clk;
    reg rst_n;

    core_top dut (
        .clk   (clk),
        .rst_n (rst_n)
    );

    // 100 MHz style clock, period is arbitrary for a functional sim
    initial clk = 1'b0;
    always #5 clk = ~clk;

    initial begin
        rst_n = 1'b0;
        repeat (3) @(posedge clk);
        rst_n = 1'b1;
    end

    initial begin
        $dumpfile("waves.vcd");
        $dumpvars(0, tb_core);
    end

    // let the small test program run out, then dump register state and finish
    initial begin
        rst_n = 1'b0;
        #1000;
        $display("---------------------------------------------");
        $display(" register dump");
        $display("---------------------------------------------");
        $display(" x1  = %0d", dut.u_regfile.regs[1]);
        $display(" x2  = %0d", dut.u_regfile.regs[2]);
        $display(" x3  = %0d", dut.u_regfile.regs[3]);
        $display(" x4  = %0d", dut.u_regfile.regs[4]);
        $display(" x5  = %0d", dut.u_regfile.regs[5]);
        $display(" x6  = %0d", dut.u_regfile.regs[6]);
        $display(" x7  = %0d", dut.u_regfile.regs[7]);
        $display(" x8  = %0d", dut.u_regfile.regs[8]);
        $display(" x9  = %0d", dut.u_regfile.regs[9]);
        $display(" x10 = %0d", dut.u_regfile.regs[10]);
        $display(" x11 = %0d", dut.u_regfile.regs[11]);
        $display(" x20 = %0d", dut.u_regfile.regs[20]);
        $display(" x21 = %0d", dut.u_regfile.regs[21]);
        $display(" x22 = %0d", dut.u_regfile.regs[22]);
        $display(" mem[0] = %0d", dut.u_dmem.mem[0]);
        $display("---------------------------------------------");
        $finish;
    end

endmodule
