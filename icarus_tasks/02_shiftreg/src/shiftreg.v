// PISO (Parallel In, Serial Out)
module shiftreg #(
    parameter WIDTH = 8
) (
    input  wire             clk,
    input  wire             rst_n,

    input  wire             i_par_ld_en,
    input  wire [WIDTH-1:0] i_par_data,

    input  wire             i_sh_en,
    input  wire             i_bit_inp,
    output wire             o_bit_out
);

reg [WIDTH-1:0] r;

assign o_bit_out = r[WIDTH-1];

always @(posedge clk, negedge rst_n) begin
    if (!rst_n) begin
        r <= '0;
    end else begin
        if (i_par_ld_en) begin
            r <= i_par_data;
        end else if (i_sh_en) begin
            r <= {r[WIDTH-2:0], i_bit_inp};
        end
    end
end
    
endmodule
