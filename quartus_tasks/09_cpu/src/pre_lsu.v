`include "common.vh"

module pre_lsu (
    input  wire [`LSU_ADDR_SEL_WIDTH-1:0] i_lsu_addr_sel,

    input  wire [31:0]                    i_imm_i,
    input  wire [31:0]                    i_imm_s,
    input  wire [31:0]                    i_src_reg1,
    input  wire [31:0]                    i_src_reg2,

    output reg  [31:0]                    o_lsu_addr,
    output wire [31:0]                    o_lsu_data_in
);

reg  [31:0] lsu_addr_imm;

assign o_lsu_data_in = i_src_reg2;

always @(*) begin
    case (i_lsu_addr_sel)
        `LSU_ADDR_SEL_I: lsu_addr_imm = i_imm_i;
        `LSU_ADDR_SEL_S: lsu_addr_imm = i_imm_s;
        default:         lsu_addr_imm = 32'bx;
    endcase
    o_lsu_addr = lsu_addr_imm + i_src_reg1;
end

endmodule
