`ifndef RV32I_DEFINES_VH
`define RV32I_DEFINES_VH

// Opcodes
`define OPCODE_R_TYPE  7'b0110011
`define OPCODE_I_TYPE  7'b0010011
`define OPCODE_LOAD    7'b0000011
`define OPCODE_STORE   7'b0100011
`define OPCODE_BRANCH  7'b1100011
`define OPCODE_LUI     7'b0110111
`define OPCODE_AUIPC   7'b0010111
`define OPCODE_JAL     7'b1101111
`define OPCODE_JALR    7'b1100111

// ALU Operations
`define ALU_ADD   4'b0000
`define ALU_SUB   4'b1000
`define ALU_SLL   4'b0001
`define ALU_SLT   4'b0010
`define ALU_SLTU  4'b0011
`define ALU_XOR   4'b0100
`define ALU_SRL   4'b0101
`define ALU_SRA   4'b1101
`define ALU_OR    4'b0110
`define ALU_AND   4'b0111
`define ALU_NONE  4'b1111

// Branch Types
`define BR_BEQ    3'b000
`define BR_BNE    3'b001
`define BR_BLT    3'b100
`define BR_BGE    3'b101
`define BR_BLTU   3'b110
`define BR_BGEU   3'b111

// Result Source (Mem to Reg)
`define RES_ALU   2'b00
`define RES_MEM   2'b01
`define RES_PC    2'b10
`define RES_IMM   2'b11

`endif // RV32I_DEFINES_VH
`timescale 1ns / 1ps
// include removed

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
`timescale 1ns / 1ps
// include removed

module controller (
    input  wire [6:0] op,
    input  wire [2:0] funct3,
    input  wire       funct7b5,
    output wire       reg_write,
    output wire [1:0] result_src,
    output wire       mem_write,
    output wire       jump,
    output wire       branch,
    output wire       alu_src,
    output wire [3:0] alu_control,
    output wire [2:0] imm_src
);

    reg [1:0] alu_op;
    reg       r_reg_write;
    reg [1:0] r_result_src;
    reg       r_mem_write;
    reg       r_jump;
    reg       r_branch;
    reg       r_alu_src;
    reg [2:0] r_imm_src;

    always @(*) begin
        // Default values
        r_reg_write  = 1'b0;
        r_result_src = 2'b00;
        r_mem_write  = 1'b0;
        r_jump       = 1'b0;
        r_branch     = 1'b0;
        r_alu_src    = 1'b0;
        r_imm_src    = 3'b000;
        alu_op       = 2'b00;

        case (op)
            `OPCODE_LOAD: begin
                r_reg_write  = 1'b1;
                r_result_src = `RES_MEM;
                r_alu_src    = 1'b1;
                r_imm_src    = 3'b000; // I-type
                alu_op       = 2'b00;  // ADD
            end
            `OPCODE_STORE: begin
                r_mem_write  = 1'b1;
                r_alu_src    = 1'b1;
                r_imm_src    = 3'b001; // S-type
                alu_op       = 2'b00;  // ADD
            end
            `OPCODE_R_TYPE: begin
                r_reg_write  = 1'b1;
                r_result_src = `RES_ALU;
                alu_op       = 2'b10;  // Decode funct
            end
            `OPCODE_I_TYPE: begin
                r_reg_write  = 1'b1;
                r_result_src = `RES_ALU;
                r_alu_src    = 1'b1;
                r_imm_src    = 3'b000; // I-type
                alu_op       = 2'b10;  // Decode funct
            end
            `OPCODE_BRANCH: begin
                r_branch     = 1'b1;
                r_imm_src    = 3'b010; // B-type
                alu_op       = 2'b01;  // SUB
            end
            `OPCODE_JAL: begin
                r_reg_write  = 1'b1;
                r_result_src = `RES_PC;
                r_jump       = 1'b1;
                r_imm_src    = 3'b011; // J-type
            end
            `OPCODE_JALR: begin
                r_reg_write  = 1'b1;
                r_result_src = `RES_PC;
                r_jump       = 1'b1;
                r_alu_src    = 1'b1;
                r_imm_src    = 3'b000; // I-type
                alu_op       = 2'b00; // ADD for target calc
            end
            `OPCODE_LUI: begin
                r_reg_write  = 1'b1;
                r_result_src = `RES_IMM;
                r_imm_src    = 3'b100; // U-type
            end
            `OPCODE_AUIPC: begin
                r_reg_write  = 1'b1;
                r_result_src = `RES_ALU;
                r_alu_src    = 1'b1;
                r_imm_src    = 3'b100; // U-type
                alu_op       = 2'b00;  // ADD PC+imm
            end
            default: ;
        endcase
    end

    // ALU Decoder
    reg [3:0] r_alu_control;
    always @(*) begin
        case (alu_op)
            2'b00: r_alu_control = `ALU_ADD;
            2'b01: r_alu_control = `ALU_SUB;
            2'b10: begin // R-type or I-type ALU
                case (funct3)
                    3'b000: r_alu_control = (op == `OPCODE_R_TYPE && funct7b5) ? `ALU_SUB : `ALU_ADD;
                    3'b010: r_alu_control = `ALU_SLT;
                    3'b011: r_alu_control = `ALU_SLTU;
                    3'b100: r_alu_control = `ALU_XOR;
                    3'b110: r_alu_control = `ALU_OR;
                    3'b111: r_alu_control = `ALU_AND;
                    3'b001: r_alu_control = `ALU_SLL;
                    3'b101: r_alu_control = (funct7b5) ? `ALU_SRA : `ALU_SRL;
                    default: r_alu_control = `ALU_NONE;
                endcase
            end
            default: r_alu_control = `ALU_NONE;
        endcase
    end

    assign reg_write   = r_reg_write;
    assign result_src  = r_result_src;
    assign mem_write   = r_mem_write;
    assign jump        = r_jump;
    assign branch      = r_branch;
    assign alu_src     = r_alu_src;
    assign imm_src     = r_imm_src;
    assign alu_control = r_alu_control;

endmodule
`timescale 1ns / 1ps
// include removed

module core_top (
    input wire clk,
    input wire rst_n
);

    // -------------------------------------------------------------------------
    // Wires & Pipeline Registers
    // -------------------------------------------------------------------------
    
    // Hazard Unit signals
    wire stall_f, stall_d, flush_d, flush_e;
    wire [1:0] forward_a_e, forward_b_e;
    
    // Branch / Jump resolution (happens in Execute stage to handle forwarding easily)
    wire pc_src_e;
    wire [31:0] pc_target_e;
    
    // --- Fetch Stage (F) ---
    reg  [31:0] pc_f;
    wire [31:0] pc_next_f;
    wire [31:0] pc_plus4_f;
    wire [31:0] instr_f;
    
    // --- Decode Stage (D) ---
    reg  [31:0] pc_d, instr_d, pc_plus4_d;
    wire [31:0] rd1_d, rd2_d, imm_ext_d;
    wire [4:0]  rs1_d, rs2_d, rd_d;
    wire [2:0]  imm_src_d;
    
    // Control signals in D
    wire reg_write_d, mem_write_d, jump_d, branch_d, alu_src_d;
    wire [1:0] result_src_d;
    wire [3:0] alu_control_d;
    
    // --- Execute Stage (E) ---
    reg [31:0] rd1_e, rd2_e, pc_e, imm_ext_e, pc_plus4_e;
    reg [4:0]  rs1_e, rs2_e, rd_e;
    reg [3:0]  alu_control_e;
    reg        reg_write_e, mem_write_e, jump_e, branch_e, alu_src_e;
    reg [1:0]  result_src_e;
    reg [2:0]  funct3_e;
    
    wire [31:0] src_a_e, src_b_e, write_data_e, alu_result_e;
    wire zero_e;
    
    // --- Memory Stage (M) ---
    reg [31:0] alu_result_m, write_data_m, pc_plus4_m, imm_ext_m;
    reg [4:0]  rd_m;
    reg        reg_write_m, mem_write_m;
    reg [1:0]  result_src_m;
    
    wire [31:0] read_data_m;
    
    // --- Writeback Stage (W) ---
    reg [31:0] alu_result_w, read_data_w, pc_plus4_w, imm_ext_w;
    reg [4:0]  rd_w;
    reg        reg_write_w;
    reg [1:0]  result_src_w;
    
    wire [31:0] result_w;
    
    // -------------------------------------------------------------------------
    // Fetch Stage (F)
    // -------------------------------------------------------------------------
    assign pc_plus4_f = pc_f + 32'd4;
    assign pc_next_f  = (pc_src_e) ? pc_target_e : pc_plus4_f;
    
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            pc_f <= 32'd0;
        end else if (!stall_f) begin
            pc_f <= pc_next_f;
        end
    end
    
    imem #(.DEPTH(256)) u_imem (
        .a(pc_f),
        .rd(instr_f)
    );
    
    // -------------------------------------------------------------------------
    // Fetch to Decode Pipeline Register (F/D)
    // -------------------------------------------------------------------------
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            instr_d    <= 32'd0; // NOP
            pc_d       <= 32'd0;
            pc_plus4_d <= 32'd0;
        end else if (flush_d) begin
            instr_d    <= 32'd0; // NOP
            pc_d       <= 32'd0;
            pc_plus4_d <= 32'd0;
        end else if (!stall_d) begin
            instr_d    <= instr_f;
            pc_d       <= pc_f;
            pc_plus4_d <= pc_plus4_f;
        end
    end
    
    // -------------------------------------------------------------------------
    // Decode Stage (D)
    // -------------------------------------------------------------------------
    assign rs1_d = instr_d[19:15];
    assign rs2_d = instr_d[24:20];
    assign rd_d  = instr_d[11:7];
    
    controller u_ctrl (
        .op(instr_d[6:0]),
        .funct3(instr_d[14:12]),
        .funct7b5(instr_d[30]),
        .reg_write(reg_write_d),
        .result_src(result_src_d),
        .mem_write(mem_write_d),
        .jump(jump_d),
        .branch(branch_d),
        .alu_src(alu_src_d),
        .alu_control(alu_control_d),
        .imm_src(imm_src_d)
    );
    
    regfile u_regfile (
        .clk(clk),
        .we3(reg_write_w),
        .a1(rs1_d),
        .a2(rs2_d),
        .a3(rd_w),
        .wd3(result_w),
        .rd1(rd1_d),
        .rd2(rd2_d)
    );
    
    // Immediate Extension
    reg [31:0] imm_ext_reg;
    always @(*) begin
        case (imm_src_d)
            3'b000: imm_ext_reg = {{20{instr_d[31]}}, instr_d[31:20]}; // I-type
            3'b001: imm_ext_reg = {{20{instr_d[31]}}, instr_d[31:25], instr_d[11:7]}; // S-type
            3'b010: imm_ext_reg = {{20{instr_d[31]}}, instr_d[7], instr_d[30:25], instr_d[11:8], 1'b0}; // B-type
            3'b011: imm_ext_reg = {{12{instr_d[31]}}, instr_d[19:12], instr_d[20], instr_d[30:21], 1'b0}; // J-type
            3'b100: imm_ext_reg = {instr_d[31:12], 12'b0}; // U-type
            default: imm_ext_reg = 32'd0;
        endcase
    end
    assign imm_ext_d = imm_ext_reg;
    
    // -------------------------------------------------------------------------
    // Decode to Execute Pipeline Register (D/E)
    // -------------------------------------------------------------------------
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            reg_write_e   <= 1'b0;
            result_src_e  <= 2'b0;
            mem_write_e   <= 1'b0;
            jump_e        <= 1'b0;
            branch_e      <= 1'b0;
            alu_control_e <= 4'b0;
            alu_src_e     <= 1'b0;
            rd1_e         <= 32'b0;
            rd2_e         <= 32'b0;
            pc_e          <= 32'b0;
            rs1_e         <= 5'b0;
            rs2_e         <= 5'b0;
            rd_e          <= 5'b0;
            imm_ext_e     <= 32'b0;
            pc_plus4_e    <= 32'b0;
            funct3_e      <= 3'b0;
        end else if (flush_e) begin
            reg_write_e   <= 1'b0;
            result_src_e  <= 2'b0;
            mem_write_e   <= 1'b0;
            jump_e        <= 1'b0;
            branch_e      <= 1'b0;
            alu_control_e <= 4'b0;
            alu_src_e     <= 1'b0;
            rd1_e         <= 32'b0;
            rd2_e         <= 32'b0;
            pc_e          <= 32'b0;
            rs1_e         <= 5'b0;
            rs2_e         <= 5'b0;
            rd_e          <= 5'b0;
            imm_ext_e     <= 32'b0;
            pc_plus4_e    <= 32'b0;
            funct3_e      <= 3'b0;
        end else begin
            reg_write_e   <= reg_write_d;
            result_src_e  <= result_src_d;
            mem_write_e   <= mem_write_d;
            jump_e        <= jump_d;
            branch_e      <= branch_d;
            alu_control_e <= alu_control_d;
            alu_src_e     <= alu_src_d;
            rd1_e         <= rd1_d;
            rd2_e         <= rd2_d;
            pc_e          <= pc_d;
            rs1_e         <= rs1_d;
            rs2_e         <= rs2_d;
            rd_e          <= rd_d;
            imm_ext_e     <= imm_ext_d;
            pc_plus4_e    <= pc_plus4_d;
            funct3_e      <= instr_d[14:12];
        end
    end
    
    // -------------------------------------------------------------------------
    // Execute Stage (E)
    // -------------------------------------------------------------------------
    // Forwarding logic for ALU inputs
    assign src_a_e = (forward_a_e == 2'b10) ? alu_result_m :
                     (forward_a_e == 2'b01) ? result_w : rd1_e;
                     
    assign write_data_e = (forward_b_e == 2'b10) ? alu_result_m :
                          (forward_b_e == 2'b01) ? result_w : rd2_e;
                          
    assign src_b_e = (alu_src_e) ? imm_ext_e : write_data_e;
    
    alu u_alu (
        .a(src_a_e),
        .b(src_b_e),
        .alu_control(alu_control_e),
        .result(alu_result_e),
        .zero(zero_e)
    );
    
    // Branch Target Calculation (for JAL and Branch)
    // Note: AUIPC target is computed in ALU using PC + Imm. JALR target is also ALU result.
    assign pc_target_e = (jump_e && alu_control_e == `ALU_ADD && alu_src_e) ? alu_result_e : (pc_e + imm_ext_e);
    
    // Branch condition evaluation
    reg branch_cond_met;
    always @(*) begin
        case (funct3_e)
            `BR_BEQ:  branch_cond_met = zero_e;
            `BR_BNE:  branch_cond_met = !zero_e;
            `BR_BLT:  branch_cond_met = (alu_result_e == 32'd1); // SLT returns 1 if less
            `BR_BGE:  branch_cond_met = (alu_result_e == 32'd0);
            `BR_BLTU: branch_cond_met = (alu_result_e == 32'd1); // SLTU
            `BR_BGEU: branch_cond_met = (alu_result_e == 32'd0);
            default:  branch_cond_met = 1'b0;
        endcase
    end
    
    assign pc_src_e = (branch_e & branch_cond_met) | jump_e;
    
    // -------------------------------------------------------------------------
    // Execute to Memory Pipeline Register (E/M)
    // -------------------------------------------------------------------------
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            reg_write_m  <= 1'b0;
            result_src_m <= 2'b0;
            mem_write_m  <= 1'b0;
            alu_result_m <= 32'b0;
            write_data_m <= 32'b0;
            rd_m         <= 5'b0;
            pc_plus4_m   <= 32'b0;
            imm_ext_m    <= 32'b0;
        end else begin
            reg_write_m  <= reg_write_e;
            result_src_m <= result_src_e;
            mem_write_m  <= mem_write_e;
            alu_result_m <= alu_result_e;
            write_data_m <= write_data_e;
            rd_m         <= rd_e;
            pc_plus4_m   <= pc_plus4_e;
            imm_ext_m    <= imm_ext_e;
        end
    end
    
    // -------------------------------------------------------------------------
    // Memory Stage (M)
    // -------------------------------------------------------------------------
    dmem #(.DEPTH(256)) u_dmem (
        .clk(clk),
        .we(mem_write_m),
        .a(alu_result_m),
        .wd(write_data_m),
        .rd(read_data_m)
    );
    
    // -------------------------------------------------------------------------
    // Memory to Writeback Pipeline Register (M/W)
    // -------------------------------------------------------------------------
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            reg_write_w  <= 1'b0;
            result_src_w <= 2'b0;
            alu_result_w <= 32'b0;
            read_data_w  <= 32'b0;
            rd_w         <= 5'b0;
            pc_plus4_w   <= 32'b0;
            imm_ext_w    <= 32'b0;
        end else begin
            reg_write_w  <= reg_write_m;
            result_src_w <= result_src_m;
            alu_result_w <= alu_result_m;
            read_data_w  <= read_data_m;
            rd_w         <= rd_m;
            pc_plus4_w   <= pc_plus4_m;
            imm_ext_w    <= imm_ext_m;
        end
    end
    
    // -------------------------------------------------------------------------
    // Writeback Stage (W)
    // -------------------------------------------------------------------------
    assign result_w = (result_src_w == `RES_MEM) ? read_data_w :
                      (result_src_w == `RES_PC)  ? pc_plus4_w : 
                      (result_src_w == `RES_IMM) ? imm_ext_w : alu_result_w;
                      
    // -------------------------------------------------------------------------
    // Hazard and Forwarding Units
    // -------------------------------------------------------------------------
    hazard_unit u_hazard (
        .rs1_d(rs1_d),
        .rs2_d(rs2_d),
        .pc_src_e(pc_src_e),
        .result_src_e(result_src_e[0]), // simplified check for load (result_src_e == 01)
        .rd_e(rd_e),
        .stall_f(stall_f),
        .stall_d(stall_d),
        .flush_d(flush_d),
        .flush_e(flush_e)
    );
    
    forwarding_unit u_forward (
        .rs1_e(rs1_e),
        .rs2_e(rs2_e),
        .rd_m(rd_m),
        .reg_write_m(reg_write_m),
        .rd_w(rd_w),
        .reg_write_w(reg_write_w),
        .forward_a_e(forward_a_e),
        .forward_b_e(forward_b_e)
    );
    
endmodule
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
