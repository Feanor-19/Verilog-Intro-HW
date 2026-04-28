`include "common.vh"

module core #(
    parameter [31:0] PC_INIT_VAL = 32'h0
) (
    input  wire        clk,
    input  wire        rst_n,

    output wire [29:0] o_imem_addr,
    input  wire [31:0] i_imem_data,

    output wire [29:0] o_dmem_addr,
    output wire [31:0] o_dmem_data,
    input  wire [31:0] i_dmem_data,
    output wire        o_dmem_wren,
    output wire [3:0]  o_dmem_mask
);

wire [6:0]  opcode_s0;
wire [2:0]  funct3_s0;
wire [6:0]  funct7_s0;
wire [4:0]  rs1_s0;
wire [4:0]  rs2_s0;
wire [4:0]  rd_s0;
wire [31:0] imm_i_s0;
wire [31:0] imm_s_s0;
wire [31:0] imm_b_s0;
wire [31:0] imm_u_s0;
wire [31:0] imm_j_s0;

reg [6:0]  opcode_s1;
reg [2:0]  funct3_s1;
reg [6:0]  funct7_s1;
reg [4:0]  rs1_s1;
reg [4:0]  rs2_s1;
reg [4:0]  rd_s1;
reg [31:0] imm_i_s1;
reg [31:0] imm_s_s1;
reg [31:0] imm_b_s1;
reg [31:0] imm_u_s1;
reg [31:0] imm_j_s1;

reg  [4:0]  rd_s2;
reg  [31:0] imm_u_s2;

wire [31:0]                    src_reg1_s0;
wire [31:0]                    src_reg2_s0;
wire [`ALU_SEL1_WIDTH-1:0]     alu_sel1_s1;
wire [`ALU_SEL2_WIDTH-1:0]     alu_sel2_s1;
wire [`ALU_OP_WIDTH-1:0]       alu_op_s1;
wire [`CMP_OP_WIDTH-1:0]       cmp_op_s1;
wire                           cmp_res_s1;
wire [`PC_ADD_SEL_WIDTH-1:0]   pc_add_sel_s1;
wire [`WRB_SEL_WIDTH-1:0]      wrb_sel_s1;
wire                           instr_branch_s1;
wire                           instr_jump_s1;
wire                           rf_wren_s1;
wire                           lsu_wren_s1;
wire [`LSU_SIZE_WIDTH-1:0]     lsu_size_s1;
wire [`LSU_ADDR_SEL_WIDTH-1:0] lsu_addr_sel_s1;
wire                           branch_taken_s1;
wire [31:0]                    lsu_data_in_s1;
wire [31:0]                    lsu_addr_s1;
wire                           bypass_sel1_s1;
wire                           bypass_sel2_s1;

reg  [31:0] src_reg1_s1;
reg  [31:0] src_reg2_s1;
reg  [31:0] alu_a_s1;
reg  [31:0] alu_b_s1;
reg  [31:0] alu_res_s1;
reg         prev_branch_taken_s1;

wire [31:0] src_reg1_byp_s1;
wire [31:0] src_reg2_byp_s1;

reg                       rf_wren_s2;
reg  [`WRB_SEL_WIDTH-1:0] wrb_sel_s2;
reg  [31:0]               alu_res_s2;
reg  [31:0]               wrb_data_s2;
reg  [31:0]               lsu_data_out_s2;

reg  [29:0] pc_s0;
reg  [29:0] pc_s1;
reg  [29:0] pc_next_s0;
reg  [29:0] pc_add_s1;
wire [29:0] pc_inc_s0;
reg  [29:0] pc_inc_s1;
reg  [29:0] pc_inc_s2;

reg reset_done_s0, reset_done_s1;

// -----

decoder decoder_inst (
    .i_inst   (i_imem_data),

    .o_opcode (opcode_s0),
    .o_funct3 (funct3_s0),
    .o_funct7 (funct7_s0),
    .o_rs1    (rs1_s0),
    .o_rs2    (rs2_s0),
    .o_rd     (rd_s0),
    .o_imm_i  (imm_i_s0),
    .o_imm_s  (imm_s_s0),
    .o_imm_b  (imm_b_s0),
    .o_imm_u  (imm_u_s0),
    .o_imm_j  (imm_j_s0)
);

// -----

always @(posedge clk, negedge rst_n) begin
    if (!rst_n) begin
        reset_done_s0 <= 1'b0;
    end else begin
        reset_done_s0 <= 1'b1;
    end
end

// -----

assign pc_inc_s0 = pc_s0 + 1'b1;

assign pc_next_s0 = (branch_taken_s1) ? pc_add_s1 : pc_inc_s0;

assign o_imem_addr = (reset_done_s0) ? pc_next_s0 : pc_s0;

always @(posedge clk, negedge rst_n) begin
    if (!rst_n) begin
        pc_s0 <= PC_INIT_VAL[31:2];
    end else if (reset_done_s0) begin
        pc_s0 <= pc_next_s0;
    end
end

// -----

rf_2r1w_byp #(.DATA_WIDTH(32), .REG_NUM(32)) rf_2r1w_inst (
    .clk        (clk),

    .i_rd1_addr (rs1_s0),
    .o_rd1_data (src_reg1_s0),

    .i_rd2_addr (rs2_s0),
    .o_rd2_data (src_reg2_s0),

    .i_wr_addr  (rd_s2),
    .i_wr_data  (wrb_data_s2),
    .i_wr_en    (rf_wren_s2)
);

// ------

// ======

always @(posedge clk) begin
    opcode_s1  <= opcode_s0;
    funct3_s1  <= funct3_s0;
    funct7_s1  <= funct7_s0;
    rs1_s1     <= rs1_s0;
    rs2_s1     <= rs2_s0;
    rd_s1      <= rd_s0;
    imm_i_s1   <= imm_i_s0;
    imm_s_s1   <= imm_s_s0;
    imm_b_s1   <= imm_b_s0;
    imm_u_s1   <= imm_u_s0;
    imm_j_s1   <= imm_j_s0;

    prev_branch_taken_s1 <= branch_taken_s1;

    src_reg1_s1 <= src_reg1_s0;
    src_reg2_s1 <= src_reg2_s0;

    pc_inc_s1 <= pc_inc_s0;
    pc_s1     <= pc_s0;

    reset_done_s1 <= reset_done_s0;
end

// ======

assign src_reg1_byp_s1 = (bypass_sel1_s1) ? wrb_data_s2 : src_reg1_s1;
assign src_reg2_byp_s1 = (bypass_sel2_s1) ? wrb_data_s2 : src_reg2_s1;

// ------

pc_adder pc_adder_inst (
    .i_pc           (pc_s1),
    .i_imm_i        (imm_i_s1),
    .i_imm_j        (imm_j_s1),
    .i_imm_b        (imm_b_s1),
    .i_rs1          (src_reg1_byp_s1),
    .i_pc_add_sel   (pc_add_sel_s1),
    .o_pc_add       (pc_add_s1)
);

// -----

ctrl_unit ctrl_unit_inst (
    .i_opcode            (opcode_s1),
    .i_funct3            (funct3_s1),
    .i_funct7            (funct7_s1),

    .o_alu_sel1          (alu_sel1_s1),
    .o_alu_sel2          (alu_sel2_s1),
    .o_wrb_sel           (wrb_sel_s1),
    .o_alu_op            (alu_op_s1),
    .o_cmp_op            (cmp_op_s1),
    .o_pc_add_sel        (pc_add_sel_s1),
    .o_branch            (instr_branch_s1),
    .o_jump              (instr_jump_s1),
    .o_rf_wren           (rf_wren_s1),
    .o_lsu_wren          (lsu_wren_s1),
    .o_lsu_size          (lsu_size_s1),
    .o_lsu_addr_sel      (lsu_addr_sel_s1),

    .i_rf_wren_s2        (rf_wren_s2),
    .i_rd_s2             (rd_s2),
    .i_rs1_s1            (rs1_s1),
    .i_rs2_s1            (rs2_s1),
    .o_bypass_sel1_s1    (bypass_sel1_s1),
    .o_bypass_sel2_s1    (bypass_sel2_s1),

    .i_prev_branch_taken (prev_branch_taken_s1)
);

// -----

always @(*) begin
    case (alu_sel1_s1)
        `ALU_SEL1_IMMU: alu_a_s1 = imm_u_s1;
        `ALU_SEL1_REG1: alu_a_s1 = src_reg1_byp_s1;
        default:        alu_a_s1 = 32'bx;
    endcase

    case (alu_sel2_s1)
        `ALU_SEL2_REG2: alu_b_s1 = src_reg2_byp_s1;
        `ALU_SEL2_IMMI: alu_b_s1 = imm_i_s1;
        `ALU_SEL2_IMMS: alu_b_s1 = imm_s_s1;
        `ALU_SEL2_PC:   alu_b_s1 = {pc_s1, 2'b0};
        default:        alu_b_s1 = 32'bx;
    endcase
end

alu #(.DATA_WIDTH(32)) alu_inst (
    .i_op   (alu_op_s1),
    .i_a    (alu_a_s1),
    .i_b    (alu_b_s1),
    .o_res  (alu_res_s1)
);

// -----

cmp #(.DATA_WIDTH(32)) cmp_inst (
    .i_op    (cmp_op_s1),
    .i_a     (src_reg1_byp_s1),
    .i_b     (src_reg2_byp_s1),
    .o_taken (cmp_res_s1)
);

assign branch_taken_s1 = instr_jump_s1 | (instr_branch_s1 & cmp_res_s1);

// -----

wire lsu_wren_clean;
assign lsu_wren_clean = lsu_wren_s1 & reset_done_s1;

pre_lsu pre_lsu_inst (
    .i_lsu_addr_sel (lsu_addr_sel_s1),
    .i_imm_i        (imm_i_s1),
    .i_imm_s        (imm_s_s1),
    .i_src_reg1     (src_reg1_byp_s1),
    .i_src_reg2     (src_reg2_byp_s1),
    .o_lsu_addr     (lsu_addr_s1),
    .o_lsu_data_in  (lsu_data_in_s1)
);

lsu lsu_inst (
    .clk         (clk),

    .i_core_addr (lsu_addr_s1),
    .i_core_data (lsu_data_in_s1),
    .o_core_data (lsu_data_out_s2),
    .i_wren      (lsu_wren_clean),
    .i_size      (lsu_size_s1),

    .o_mem_addr  (o_dmem_addr),
    .o_mem_data  (o_dmem_data),
    .i_mem_data  (i_dmem_data),
    .o_wren      (o_dmem_wren),
    .o_mask      (o_dmem_mask)
);

// =====

always @(posedge clk) begin
    rd_s2      <= rd_s1;
    rf_wren_s2 <= rf_wren_s1;

    imm_u_s2   <= imm_u_s1;
    alu_res_s2 <= alu_res_s1;
    pc_inc_s2  <= pc_inc_s1;
    wrb_sel_s2 <= wrb_sel_s1;
end

// =====

always @(*) begin
    case (wrb_sel_s2)
        `WRB_SEL_IMMU:   wrb_data_s2 = imm_u_s2;
        `WRB_SEL_ALURES: wrb_data_s2 = alu_res_s2;
        `WRB_SEL_LSUDAT: wrb_data_s2 = lsu_data_out_s2;
        `WRB_SEL_PCINC:  wrb_data_s2 = {pc_inc_s2, 2'b0};
        default:         wrb_data_s2 = 32'bx;
    endcase
end

endmodule
