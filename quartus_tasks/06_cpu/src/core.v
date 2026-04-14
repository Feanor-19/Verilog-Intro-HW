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

wire [6:0]  opcode;
wire [2:0]  funct3;
wire [6:0]  funct7;
wire [4:0]  rs1;
wire [4:0]  rs2;
wire [4:0]  rd;
wire [31:0] imm_i;
wire [31:0] imm_s;
wire [31:0] imm_b;
wire [31:0] imm_u;
wire [31:0] imm_j;

wire [`ALU_SEL1_WIDTH-1:0] alu_sel1;
wire [`ALU_SEL2_WIDTH-1:0] alu_sel2;
wire [`WRB_SEL_WIDTH-1:0]  wrb_sel;
wire [`ALU_OP_WIDTH-1:0]   alu_op;
wire [`CMP_OP_WIDTH-1:0]   cmp_op;
wire                       instr_branch;
wire                       instr_jump;
wire                       rf_wren;
wire                       lsu_wren;
wire [`LSU_SIZE_WIDTH-1:0] lsu_size;
wire                       mem_load;

wire [31:0] src_reg1, src_reg2;
reg [31:0] alu_a, alu_b, alu_res, wrb_data, lsu_data_out;

wire cmp_res;

wire branch_taken;
reg [29:0] pc;
reg [29:0] pc_next;
wire [29:0] pc_inc;

reg reset_done;

reg mem_out;
wire mem_out_next;

// -----

decoder decoder_inst (
    .i_inst   (i_imem_data),

    .o_opcode (opcode),
    .o_funct3 (funct3),
    .o_funct7 (funct7),
    .o_rs1    (rs1),
    .o_rs2    (rs2),
    .o_rd     (rd),
    .o_imm_i  (imm_i),
    .o_imm_s  (imm_s),
    .o_imm_b  (imm_b),
    .o_imm_u  (imm_u),
    .o_imm_j  (imm_j)
);

ctrl_unit ctrl_unit_inst (
    .i_opcode   (opcode),
    .i_funct3   (funct3),
    .i_funct7   (funct7),

    .o_alu_sel1 (alu_sel1),
    .o_alu_sel2 (alu_sel2),
    .o_wrb_sel  (wrb_sel),
    .o_alu_op   (alu_op),
    .o_cmp_op   (cmp_op),
    .o_branch   (instr_branch),
    .o_jump     (instr_jump),
    .o_rf_wren  (rf_wren),
    .o_lsu_wren (lsu_wren),
    .o_lsu_size (lsu_size),
    .o_mem_load (mem_load)
);

// -----

always @(*) begin
    case (alu_sel1)
        `ALU_SEL1_IMMU: alu_a = imm_u;
        `ALU_SEL1_IMMB: alu_a = imm_b;
        `ALU_SEL1_IMMJ: alu_a = imm_j;
        `ALU_SEL1_REG1: alu_a = src_reg1;
        default:        alu_a = 32'bx;
    endcase

    case (alu_sel2)
        `ALU_SEL2_REG2: alu_b = src_reg2;
        `ALU_SEL2_IMMI: alu_b = imm_i;
        `ALU_SEL2_IMMS: alu_b = imm_s;
        `ALU_SEL2_PC:   alu_b = {pc, 2'b0};
        default:        alu_b = 32'bx;
    endcase
end

alu #(.DATA_WIDTH(32)) alu_inst (
    .i_op   (alu_op),
    .i_a    (alu_a),
    .i_b    (alu_b),
    .o_res  (alu_res)
);

// -----

cmp #(.DATA_WIDTH(32)) cmp_inst (
    .i_op    (cmp_op),
    .i_a     (src_reg1),
    .i_b     (src_reg2),
    .o_taken (cmp_res)
);

assign branch_taken = instr_jump | (instr_branch & cmp_res);

// -----

rf_2r1w #(.DATA_WIDTH(32), .REG_NUM(32)) rf_2r1w_inst (
    .clk        (clk),

    .i_rd1_addr (rs1),
    .o_rd1_data (src_reg1),

    .i_rd2_addr (rs2),
    .o_rd2_data (src_reg2),

    .i_wr_addr  (rd),
    .i_wr_data  (wrb_data),
    .i_wr_en    (rf_wren)
);

// -----

wire lsu_wren_clean;
assign lsu_wren_clean = lsu_wren & reset_done;

lsu lsu_inst(
    .clk         (clk),

    .i_core_addr (alu_res),
    .i_core_data (src_reg2),
    .o_core_data (lsu_data_out),
    .i_wren      (lsu_wren_clean),
    .i_size      (lsu_size),

    .o_mem_addr  (o_dmem_addr),
    .o_mem_data  (o_dmem_data),
    .i_mem_data  (i_dmem_data),
    .o_wren      (o_dmem_wren),
    .o_mask      (o_dmem_mask)
);

// -----

always @(*) begin
    case (wrb_sel)
        `WRB_SEL_IMMU:   wrb_data = imm_u;
        `WRB_SEL_ALURES: wrb_data = alu_res;
        `WRB_SEL_LSUDAT: wrb_data = lsu_data_out;
        `WRB_SEL_PCINC:  wrb_data = {pc_inc, 2'b0};
        default:         wrb_data = 32'bx;
    endcase
end

// -----

assign pc_inc = pc + 1'b1;
assign o_imem_addr = pc_next;

always @(*) begin
    pc_next = pc;
    if (~mem_out_next & reset_done) begin
        pc_next = branch_taken ? alu_res[31:2] : pc_inc;
    end
end

always @(posedge clk, negedge rst_n) begin
    if (!rst_n) begin
        pc <= PC_INIT_VAL[31:2];
    end else begin
        pc <= pc_next;
    end
end

// -----

always @(posedge clk, negedge rst_n) begin
    if (!rst_n) begin
        reset_done <= 1'b0;
    end else begin 
        reset_done <= 1'b1;
    end
end

// -----

assign mem_out_next = mem_load & ~mem_out;

always @(posedge clk, negedge rst_n) begin
    if (!rst_n) begin
        mem_out <= 1'b0;
    end else begin 
        mem_out <= mem_out_next;
    end
end

endmodule
