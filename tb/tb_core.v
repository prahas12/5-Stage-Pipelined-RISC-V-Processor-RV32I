`timescale 1ns / 1ps

module tb_core;

    reg clk;
    reg rst_n;

    wire [31:0] dbg_pc;
    wire [31:0] dbg_result;

    core_top u_core (
        .clk(clk),
        .rst_n(rst_n),
        .dbg_pc(dbg_pc),
        .dbg_result(dbg_result)
    );

    initial begin
        clk = 0;
        forever #5 clk = ~clk;
    end

    initial begin
        // Initialize Reset
        rst_n = 0;
        #20;
        rst_n = 1;

        // Wait for a reasonable amount of time to let the simple program finish
        #200;

        // Check the memory at address 0 to see if x3 (15 = 0xF) was written successfully
        if (u_core.u_dmem.ram[0] === 32'h0000000F) begin
            $display("SUCCESS: Value 15 correctly stored in DMEM.");
        end else begin
            $display("FAILED: Expected 15, got %d", u_core.u_dmem.ram[0]);
        end

        $finish;
    end

    // Optional: Dump waveforms
    initial begin
        $dumpfile("waveform.vcd");
        $dumpvars(0, tb_core);
    end

endmodule
