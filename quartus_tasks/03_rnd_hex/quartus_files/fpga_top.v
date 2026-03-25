module fpga_top(
    input  wire CLK,   // CLOCK
    input  wire RSTN,  // BUTTON RST (NEGATIVE)
    output wire STCP,
    output wire SHCP,
    output wire DS,
    output wire OE
);

reg rst_n, RSTN_d;

always @(posedge CLK) begin
    rst_n <= RSTN_d;
    RSTN_d <= RSTN;
end

top #(
    .CNT_GRND_WIDTH(26),
    .CNT_DISP_WIDTH(14)
) top_inst (
    .clk     (CLK),
    .rst_n   (rst_n),
    .o_stcp  (STCP),
    .o_shcp  (SHCP),
    .o_ds    (DS),
    .o_oe    (OE)
);

endmodule
