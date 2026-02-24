module mux4 #(
	parameter WIDTH = 32
) (
	input  wire [1:0] 		i_sel,
	input  wire [WIDTH-1:0] i_0,
	input  wire [WIDTH-1:0] i_1,
	input  wire [WIDTH-1:0] i_2,
	input  wire [WIDTH-1:0] i_3,
	output reg  [WIDTH-1:0] o_out
);

always @(*) begin
    case (i_sel)
        2'b00: o_out = i_0;
        2'b01: o_out = i_1;
        2'b10: o_out = i_2;
        2'b11: o_out = i_3;
    endcase
end

endmodule