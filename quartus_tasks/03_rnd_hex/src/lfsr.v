module lfsr #(
    parameter WIDTH = 8,
    parameter [WIDTH-2:0] P = 7'b0111000,
    parameter [WIDTH-1:0] INITVAL = 8'h19
) (
    input  wire             clk,
    input  wire             rst_n,

    input  wire             i_en,
    output wire [WIDTH-1:0] o_reg 
);

reg [WIDTH-1:0] r;
reg bit_inp;

assign o_reg = r; 

always @(posedge clk, negedge rst_n) begin
    if (!rst_n) begin
        r <= INITVAL;
    end else begin
        if (i_en)
            r <= {r[WIDTH-2:0], bit_inp};
    end
end

always @(*) begin
    integer i;
    bit_inp = 1'b1;

    for (i = 0; i < WIDTH-1; i=i+1) begin
        if (P[i])
            bit_inp = bit_inp ^ r[i];
    end
end

endmodule
