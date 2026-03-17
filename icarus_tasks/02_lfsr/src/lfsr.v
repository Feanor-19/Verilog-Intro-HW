module lfsr #(
    parameter WIDTH = 8,
    parameter [WIDTH-2:0] P = 7'b0111000
) (
    input  wire clk,
    input  wire rst_n,

    input  wire i_en,
    output wire o_bit
);

reg [WIDTH-1:0] r;

reg bit_inp;

assign o_bit = r[WIDTH-1];

always @(posedge clk, negedge rst_n) begin
    if (!rst_n) begin
        r <= WIDTH'(1'b1);
    end else begin
        if (i_en)
            r <= {r[WIDTH-2:0], bit_inp};
    end
end

always @(*) begin
    bit_inp = 1'b1;

    for (int i = 0; i < WIDTH-1; i++) begin
        if (P[i])
            bit_inp ^= r[i];
    end
end

endmodule
