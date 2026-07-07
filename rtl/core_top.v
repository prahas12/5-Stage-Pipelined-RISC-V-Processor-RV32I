`timescale 1ns/1ps
// 5 stage pipelined RV32I core: IF - ID - EX - MEM - WB
// has full forwarding (EX/MEM and MEM/WB -> EX) and a stall for load-use
// branches/jumps are resolved in EX, so a taken branch costs a 2 cycle flush
module core_top (
    input  wire clk,
    input  wire rst_n,
    // small debug/status output - exists so a synthesis tool has somewhere
    // to route the logic to. a top module with zero outputs gets fully
    // trimmed by opt_design (nothing to keep), which shows up as "design is
    // empty" during place_design. each bit is an XOR reduction across a
    // wide internal bus, so every bit of every source signal has to stay
    // alive for the parity to be correct - keeps the whole design intact
    // without needing 100+ I/O pins. tie to LEDs on a real board, or leave
    // unconnected for a utilization/schematic-only run.
    output wire [7:0] dbg_status
);

    // ------------------------------------------------------------------
    // IF stage
    // ------------------------------------------------------------------
    reg  [31:0] pc_if;
    wire [31:0] instr_if;
    wire        stall;
    wire        pc_redirect;
    wire [31:0] redirect_target;

    imem u_imem (
        .addr  (pc_if),
        .rdata (instr_if)
    );

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n)
            pc_if <= 32'h0;
        else if (pc_redirect)
            pc_if <= redirect_target;
        else if (!stall)
            pc_if <= pc_if + 32'h4;
        // else hold PC during a stall
    end

    // ------------------------------------------------------------------
    // IF/ID register
    // ------------------------------------------------------------------
    reg [31:0] pc_id;
    reg [31:0] instr_id;
    reg        valid_id;

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            pc_id    <= 32'h0;
            instr_id <= 32'h00000013; // nop (addi x0,x0,0)
            valid_id <= 1'b0;
        end else if (pc_redirect) begin
            pc_id    <= pc_id;
            instr_id <= 32'h00000013;
            valid_id <= 1'b0;
        end else if (stall) begin
            // hold current contents, do not latch new fetch
            pc_id    <= pc_id;
            instr_id <= instr_id;
            valid_id <= valid_id;
        end else begin
            pc_id    <= pc_if;
            instr_id <= instr_if;
            valid_id <= 1'b1;
        end
    end

    // ------------------------------------------------------------------
    // ID stage
    // ------------------------------------------------------------------
    // opcode/funct7 are decoded internally by u_decoder and not needed again
    // up here, kept on the bus for anyone probing the design in simulation
    /* verilator lint_off UNUSED */
    wire [6:0]  opcode_id;
    wire [6:0]  funct7_id;
    /* verilator lint_on UNUSED */
    wire [4:0]  rd_id, rs1_id, rs2_id;
    /* verilator lint_off UNUSED */
    wire [2:0]  funct3_id;
    /* verilator lint_on UNUSED */
    wire [31:0] imm_id;
    wire        reg_write_id, mem_read_id, mem_write_id, mem_to_reg_id;
    wire        alu_src_id, branch_id, is_jal_id, is_jalr_id, is_auipc_id;
    /* verilator lint_off UNUSED */
    wire        is_lui_id;
    /* verilator lint_on UNUSED */
    wire [3:0]  alu_op_id;
    wire [2:0]  branch_type_id;

    decoder u_decoder (
        .instr       (instr_id),
        .opcode      (opcode_id),
        .rd          (rd_id),
        .rs1         (rs1_id),
        .rs2         (rs2_id),
        .funct3      (funct3_id),
        .funct7      (funct7_id),
        .imm         (imm_id),
        .reg_write   (reg_write_id),
        .mem_read    (mem_read_id),
        .mem_write   (mem_write_id),
        .mem_to_reg  (mem_to_reg_id),
        .alu_src     (alu_src_id),
        .branch      (branch_id),
        .is_jal      (is_jal_id),
        .is_jalr     (is_jalr_id),
        .is_lui      (is_lui_id),
        .is_auipc    (is_auipc_id),
        .alu_op      (alu_op_id),
        .branch_type (branch_type_id)
    );

    wire [31:0] rs1_data_id, rs2_data_id;
    wire        rf_write_wb;
    wire [4:0]  rf_rd_wb;
    wire [31:0] rf_wdata_wb;

    regfile u_regfile (
        .clk      (clk),
        .we       (rf_write_wb),
        .rs1_addr (rs1_id),
        .rs2_addr (rs2_id),
        .rd_addr  (rf_rd_wb),
        .rd_data  (rf_wdata_wb),
        .rs1_data (rs1_data_id),
        .rs2_data (rs2_data_id)
    );

    // ------------------------------------------------------------------
    // hazard detection - load followed immediately by a dependent use
    // ------------------------------------------------------------------
    reg  mem_read_ex_r;
    reg  [4:0] rd_ex_r;

    assign stall = mem_read_ex_r && (rd_ex_r != 5'd0) &&
                   ((rd_ex_r == rs1_id) || (rd_ex_r == rs2_id)) && valid_id;

    // ------------------------------------------------------------------
    // ID/EX register
    // ------------------------------------------------------------------
    reg [31:0] pc_ex;
    reg [31:0] rs1_data_ex, rs2_data_ex, imm_ex;
    reg [4:0]  rs1_ex, rs2_ex, rd_ex;
    reg        reg_write_ex, mem_read_ex, mem_write_ex, mem_to_reg_ex;
    reg        alu_src_ex, branch_ex, is_jal_ex, is_jalr_ex, is_auipc_ex;
    reg [3:0]  alu_op_ex;
    reg [2:0]  branch_type_ex;
    reg        valid_ex;

    wire bubble_ex = pc_redirect || stall || !valid_id;

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            pc_ex          <= 32'h0;
            rs1_data_ex    <= 32'h0;
            rs2_data_ex    <= 32'h0;
            imm_ex         <= 32'h0;
            rs1_ex         <= 5'd0;
            rs2_ex         <= 5'd0;
            rd_ex          <= 5'd0;
            reg_write_ex   <= 1'b0;
            mem_read_ex    <= 1'b0;
            mem_write_ex   <= 1'b0;
            mem_to_reg_ex  <= 1'b0;
            alu_src_ex     <= 1'b0;
            branch_ex      <= 1'b0;
            is_jal_ex      <= 1'b0;
            is_jalr_ex     <= 1'b0;
            is_auipc_ex    <= 1'b0;
            alu_op_ex      <= 4'b0;
            branch_type_ex <= 3'b0;
            valid_ex       <= 1'b0;
            mem_read_ex_r  <= 1'b0;
            rd_ex_r        <= 5'd0;
        end else if (bubble_ex) begin
            pc_ex          <= pc_ex;
            rs1_data_ex    <= rs1_data_ex;
            rs2_data_ex    <= rs2_data_ex;
            imm_ex         <= imm_ex;
            rs1_ex         <= rs1_ex;
            rs2_ex         <= rs2_ex;
            rd_ex          <= rd_ex;
            reg_write_ex   <= 1'b0;
            mem_read_ex    <= 1'b0;
            mem_write_ex   <= 1'b0;
            mem_to_reg_ex  <= mem_to_reg_ex;
            alu_src_ex     <= alu_src_ex;
            branch_ex      <= 1'b0;
            is_jal_ex      <= 1'b0;
            is_jalr_ex     <= 1'b0;
            is_auipc_ex    <= is_auipc_ex;
            alu_op_ex      <= alu_op_ex;
            branch_type_ex <= branch_type_ex;
            valid_ex       <= 1'b0;
            mem_read_ex_r  <= 1'b0;
            rd_ex_r        <= 5'd0;
        end else begin
            pc_ex          <= pc_id;
            rs1_data_ex    <= rs1_data_id;
            rs2_data_ex    <= rs2_data_id;
            imm_ex         <= imm_id;
            rs1_ex         <= rs1_id;
            rs2_ex         <= rs2_id;
            rd_ex          <= rd_id;
            reg_write_ex   <= reg_write_id;
            mem_read_ex    <= mem_read_id;
            mem_write_ex   <= mem_write_id;
            mem_to_reg_ex  <= mem_to_reg_id;
            alu_src_ex     <= alu_src_id;
            branch_ex      <= branch_id;
            is_jal_ex      <= is_jal_id;
            is_jalr_ex     <= is_jalr_id;
            is_auipc_ex    <= is_auipc_id;
            alu_op_ex      <= alu_op_id;
            branch_type_ex <= branch_type_id;
            valid_ex       <= 1'b1;
            mem_read_ex_r  <= mem_read_id;
            rd_ex_r        <= rd_id;
        end
    end

    // ------------------------------------------------------------------
    // EX stage - forwarding + ALU + branch resolution
    // ------------------------------------------------------------------
    reg  [31:0] alu_result_mem_r; // from EX/MEM, used for forwarding
    reg  [4:0]  rd_mem_r;
    reg         reg_write_mem_r;
    reg  [31:0] wb_data_r;        // from MEM/WB, used for forwarding
    reg  [4:0]  rd_wb_r;
    reg         reg_write_wb_r;

    reg [1:0] fwd_a, fwd_b;
    localparam FWD_NONE = 2'b00;
    localparam FWD_MEM  = 2'b01;
    localparam FWD_WB   = 2'b10;

    always @(*) begin
        if (reg_write_mem_r && (rd_mem_r != 5'd0) && (rd_mem_r == rs1_ex))
            fwd_a = FWD_MEM;
        else if (reg_write_wb_r && (rd_wb_r != 5'd0) && (rd_wb_r == rs1_ex))
            fwd_a = FWD_WB;
        else
            fwd_a = FWD_NONE;

        if (reg_write_mem_r && (rd_mem_r != 5'd0) && (rd_mem_r == rs2_ex))
            fwd_b = FWD_MEM;
        else if (reg_write_wb_r && (rd_wb_r != 5'd0) && (rd_wb_r == rs2_ex))
            fwd_b = FWD_WB;
        else
            fwd_b = FWD_NONE;
    end

    wire [31:0] op1 = (fwd_a == FWD_MEM) ? alu_result_mem_r :
                      (fwd_a == FWD_WB)  ? wb_data_r :
                      rs1_data_ex;
    wire [31:0] op2 = (fwd_b == FWD_MEM) ? alu_result_mem_r :
                      (fwd_b == FWD_WB)  ? wb_data_r :
                      rs2_data_ex;

    wire [31:0] alu_in_a = is_auipc_ex ? pc_ex : op1;
    wire [31:0] alu_in_b = alu_src_ex  ? imm_ex : op2;

    wire [31:0] alu_result_raw;
    // zero flag isn't needed for branching here (branch_cond below handles
    // all six conditions directly off the operands), kept for visibility
    /* verilator lint_off UNUSED */
    wire        alu_zero;
    /* verilator lint_on UNUSED */

    alu u_alu (
        .a        (alu_in_a),
        .b        (alu_in_b),
        .alu_op   (alu_op_ex),
        .result   (alu_result_raw),
        .zero     (alu_zero)
    );

    // link address for jal/jalr, otherwise normal alu result
    wire [31:0] alu_result_ex = (is_jal_ex || is_jalr_ex) ? (pc_ex + 32'h4) : alu_result_raw;

    // branch condition, uses the forwarded register values directly (not the alu)
    // so it works correctly for blt/bge/bltu/bgeu as well as beq/bne
    reg branch_cond;
    always @(*) begin
        case (branch_type_ex)
            3'b000:  branch_cond = (op1 == op2);                          // beq
            3'b001:  branch_cond = (op1 != op2);                          // bne
            3'b100:  branch_cond = ($signed(op1) <  $signed(op2));        // blt
            3'b101:  branch_cond = ($signed(op1) >= $signed(op2));        // bge
            3'b110:  branch_cond = (op1 <  op2);                         // bltu
            3'b111:  branch_cond = (op1 >= op2);                         // bgeu
            default: branch_cond = 1'b0;
        endcase
    end

    wire branch_taken = branch_ex && branch_cond;
    wire jump_taken    = is_jal_ex || is_jalr_ex;

    assign pc_redirect     = valid_ex && (branch_taken || jump_taken);
    assign redirect_target = is_jalr_ex ? ((op1 + imm_ex) & 32'hFFFFFFFE) : (pc_ex + imm_ex);

    // ------------------------------------------------------------------
    // EX/MEM register
    // ------------------------------------------------------------------
    reg [31:0] alu_result_ex_mem;
    reg [31:0] store_data_mem;
    reg [4:0]  rd_mem;
    reg        reg_write_mem, mem_read_mem, mem_write_mem, mem_to_reg_mem;

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            alu_result_ex_mem <= 32'h0;
            store_data_mem    <= 32'h0;
            rd_mem            <= 5'd0;
            reg_write_mem     <= 1'b0;
            mem_read_mem      <= 1'b0;
            mem_write_mem     <= 1'b0;
            mem_to_reg_mem    <= 1'b0;
        end else begin
            alu_result_ex_mem <= alu_result_ex;
            store_data_mem    <= op2;
            rd_mem            <= rd_ex;
            reg_write_mem     <= reg_write_ex & valid_ex;
            mem_read_mem      <= mem_read_ex  & valid_ex;
            mem_write_mem     <= mem_write_ex & valid_ex;
            mem_to_reg_mem    <= mem_to_reg_ex;
        end
    end

    // feed EX/MEM state back for the forwarding unit above
    always @(*) begin
        alu_result_mem_r = alu_result_ex_mem;
        rd_mem_r          = rd_mem;
        reg_write_mem_r   = reg_write_mem;
    end

    // ------------------------------------------------------------------
    // MEM stage
    // ------------------------------------------------------------------
    wire [31:0] dmem_rdata;

    dmem u_dmem (
        .clk       (clk),
        .mem_read  (mem_read_mem),
        .mem_write (mem_write_mem),
        .addr      (alu_result_ex_mem),
        .wdata     (store_data_mem),
        .rdata     (dmem_rdata)
    );

    // ------------------------------------------------------------------
    // MEM/WB register
    // ------------------------------------------------------------------
    reg [31:0] alu_result_wb;
    reg [31:0] mem_data_wb;
    reg [4:0]  rd_wb;
    reg        reg_write_wb, mem_to_reg_wb;

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            alu_result_wb <= 32'h0;
            mem_data_wb   <= 32'h0;
            rd_wb         <= 5'd0;
            reg_write_wb  <= 1'b0;
            mem_to_reg_wb <= 1'b0;
        end else begin
            alu_result_wb <= alu_result_ex_mem;
            mem_data_wb   <= dmem_rdata;
            rd_wb         <= rd_mem;
            reg_write_wb  <= reg_write_mem;
            mem_to_reg_wb <= mem_to_reg_mem;
        end
    end

    // feed MEM/WB state back for the forwarding unit above
    always @(*) begin
        wb_data_r      = mem_to_reg_wb ? mem_data_wb : alu_result_wb;
        rd_wb_r        = rd_wb;
        reg_write_wb_r = reg_write_wb;
    end

    // ------------------------------------------------------------------
    // WB stage
    // ------------------------------------------------------------------
    assign rf_write_wb = reg_write_wb;
    assign rf_rd_wb     = rd_wb;
    assign rf_wdata_wb  = mem_to_reg_wb ? mem_data_wb : alu_result_wb;

    // ------------------------------------------------------------------
    // debug/status output - parity reduction across a wide probe bus so
    // every source bit stays load-bearing without needing a wide port
    // ------------------------------------------------------------------
    wire [31:0] probe_pc    = pc_if;
    wire [31:0] probe_instr = instr_id;
    wire [31:0] probe_alu   = alu_result_ex;
    wire [31:0] probe_wb    = rf_wdata_wb;

    assign dbg_status[0] = ^probe_pc;
    assign dbg_status[1] = ^probe_instr;
    assign dbg_status[2] = ^probe_alu;
    assign dbg_status[3] = ^probe_wb;
    assign dbg_status[4] = rf_write_wb;
    assign dbg_status[5] = ^(probe_pc ^ probe_instr);
    assign dbg_status[6] = ^(probe_alu ^ probe_wb);
    assign dbg_status[7] = valid_ex ^ valid_id ^ pc_redirect ^ stall;

endmodule