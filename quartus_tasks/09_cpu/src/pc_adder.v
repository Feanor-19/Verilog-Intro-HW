`include "common.vh" 

module pc_adder (
    input  wire [29:0]                  i_pc,
    input  wire [31:0]                  i_imm_i,
    input  wire [31:0]                  i_imm_j,
    input  wire [31:0]                  i_imm_b,
    input  wire [31:0]                  i_rs1,

    input  wire [`PC_ADD_SEL_WIDTH-1:0] i_pc_add_sel,

    output wire [29:0]                  o_pc_add
);

reg [31:0] add_a, add_b, add_res;
wire [31:0] pc_ext;

assign pc_ext = {i_pc, 2'b0};

always @(*) begin
    case (i_pc_add_sel)
        `PC_ADD_SEL_JAL:  begin add_a = pc_ext; add_b = i_imm_j; end
        `PC_ADD_SEL_BRAN: begin add_a = pc_ext; add_b = i_imm_b; end
        `PC_ADD_SEL_JALR: begin add_a = i_rs1;  add_b = i_imm_i; end
        default:          begin add_a = 32'bx;  add_b = 32'bx;   end
    endcase

    add_res = add_a + add_b;
end

assign o_pc_add = add_res[31:2];

endmodule
