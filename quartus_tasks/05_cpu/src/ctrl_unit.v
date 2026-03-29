`include "common.vh"

module ctrl_unit (
    input  wire [6:0]                 i_opcode,
    input  wire [2:0]                 i_funct3,
    input  wire [6:0]                 i_funct7,

    output reg  [`ALU_SEL1_WIDTH-1:0] o_alu_sel1,
    output reg  [`ALU_SEL2_WIDTH-1:0] o_alu_sel2,
    output reg  [`WRB_SEL_WIDTH-1:0]  o_wrb_sel,
    output reg  [`ALU_OP_WIDTH-1:0]   o_alu_op,
    output reg  [`CMP_OP_WIDTH-1:0]   o_cmp_op,

    output reg                        o_branch,
    output reg                        o_jump,
    output reg                        o_rf_wren,

    output reg                        o_lsu_wren,
    output reg [`LSU_SIZE_WIDTH-1:0]  o_lsu_size
);

always @(*) begin
    o_alu_sel1  = 0;
    o_alu_sel2  = 0;
    o_wrb_sel   = 0;
    o_alu_op    = 0;
    o_cmp_op    = 0;
    o_branch    = 0;
    o_jump      = 0;
    o_lsu_wren  = 0;
    o_lsu_size  = 0;

    o_rf_wren   = 1'b1;

    case (i_opcode)
        `RV_OPCODE_LUI:
        begin
            o_wrb_sel = `WRB_SEL_IMMU;
        end
        `RV_OPCODE_AUIPC:
        begin
            o_alu_sel1 = `ALU_SEL1_IMMU;
            o_alu_sel2 = `ALU_SEL2_PC;
            o_alu_op   = `ALU_OP_ADD;
            o_wrb_sel  = `WRB_SEL_ALURES;
        end
        `RV_OPCODE_JAL:
        begin
            o_jump     = 1'b1;
            o_alu_sel1 = `ALU_SEL1_IMMJ;
            o_alu_sel2 = `ALU_SEL2_PC; 
            o_alu_op   = `ALU_OP_ADD;
            o_wrb_sel  = `WRB_SEL_PCINC;
        end
        `RV_OPCODE_JALR:
        begin
            o_jump     = 1'b1;
            o_alu_sel1 = `ALU_SEL1_REG1;
            o_alu_sel2 = `ALU_SEL2_IMMI; 
            o_alu_op   = `ALU_OP_ADD;
            o_wrb_sel  = `WRB_SEL_PCINC;
        end
        `RV_OPCODE_BRANCH:
        begin
            o_cmp_op   = i_funct3;
            o_branch   = 1'b1;
            o_alu_sel1 = `ALU_SEL1_IMMB;
            o_alu_sel2 = `ALU_SEL2_PC; 
            o_alu_op   = `ALU_OP_ADD;
            o_rf_wren  = 1'b0;
        end
        `RV_OPCODE_LOAD:
        begin
            o_alu_sel1 = `ALU_SEL1_REG1;
            o_alu_sel2 = `ALU_SEL2_IMMI;
            o_alu_op   = `ALU_OP_ADD;
            o_wrb_sel  = `WRB_SEL_LSUDAT;
            o_lsu_size = i_funct3;
        end
        `RV_OPCODE_STORE:
        begin
            o_alu_sel1 = `ALU_SEL1_REG1;
            o_alu_sel2 = `ALU_SEL2_IMMS;
            o_alu_op   = `ALU_OP_ADD;
            o_rf_wren  = 1'b0;
            o_lsu_wren = 1'b1;
            o_lsu_size = i_funct3;
        end
        `RV_OPCODE_IMM:
        begin
            o_alu_sel1 = `ALU_SEL1_REG1;
            o_alu_sel2 = `ALU_SEL2_IMMI;
            o_alu_op   = {i_funct7[5], i_funct3};
            o_wrb_sel  = `WRB_SEL_ALURES;

            //NOTE: in case of shift op ALU is responsible for slicing the
            //correct part of the IMM-I
        end
        `RV_OPCODE_REG:
        begin
            o_alu_sel1 = `ALU_SEL1_REG1;
            o_alu_sel2 = `ALU_SEL2_REG2;
            o_alu_op   = {i_funct7[5], i_funct3};
            o_wrb_sel  = `WRB_SEL_ALURES;
        end
        default: ;
    endcase
end

endmodule
