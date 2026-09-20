`timescale 1ns / 1ps

module hazard_unit (
    input  wire [4:0] rs1_d,
    input  wire [4:0] rs2_d,
    input  wire       pc_src_e,
    input  wire       result_src_e, // indicates load
    input  wire [4:0] rd_e,
    output wire       stall_f,
    output wire       stall_d,
    output wire       flush_d,
    output wire       flush_e
);

    wire lw_stall;

    // Load-use data hazard stall
    assign lw_stall = result_src_e & ((rs1_d == rd_e) | (rs2_d == rd_e)) & (rd_e != 0);
    
    assign stall_f = lw_stall;
    assign stall_d = lw_stall;
    
    // Flush when branch taken (in execute stage) or when load stall (in decode stage)
    assign flush_d = pc_src_e;
    assign flush_e = lw_stall | pc_src_e;

endmodule
