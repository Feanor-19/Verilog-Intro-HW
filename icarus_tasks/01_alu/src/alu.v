`include "defines.vh"

module alu (
    input  wire [`ALU_OP_WIDTH-1:0] i_op,
    input  wire [`DATA_WIDTH-1:0]   i_a,
    input  wire [`DATA_WIDTH-1:0]   i_b,

    output reg  [`DATA_WIDTH-1:0]   o_res
);

always @(*) begin
    case (i_op)
        `ALU_OP_ADD:  o_res = i_a + i_b;
        `ALU_OP_SUB:  o_res = i_a - i_b;
        `ALU_OP_SLL:  o_res = i_a << i_b[4:0];
        `ALU_OP_SRL:  o_res = i_a >> i_b[4:0];
        `ALU_OP_SRA:  o_res = $unsigned($signed(i_a) >>> i_b[4:0]);
        `ALU_OP_SLT:  o_res = {31'b0, $signed(i_a) < $signed(i_b)}; 
        `ALU_OP_SLTU: o_res = {31'b0, $unsigned(i_a) < $unsigned(i_b)};
        `ALU_OP_XOR:  o_res = i_a ^ i_b;
        `ALU_OP_OR:   o_res = i_a | i_b;
        `ALU_OP_AND:  o_res = i_a & i_b;
    default:
        o_res = 'x;
    endcase
end

endmodule
