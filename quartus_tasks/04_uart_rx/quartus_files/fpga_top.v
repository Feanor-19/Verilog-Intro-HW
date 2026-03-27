// TODO СИНХРОНИЗАТОР ДЛЯ RXD

module fpga_top(
    input  wire CLK,
    input  wire RSTN,
    input  wire RXD,
    output wire STCP,
    output wire SHCP,
    output wire DS,
    output wire OE
);

reg rst_n, RSTN_d;
reg i_rx, RXD_d;

always @(posedge CLK) begin
    rst_n <= RSTN_d;
    RSTN_d <= RSTN;
end

always @(posedge CLK) begin
    i_rx <= RXD_d;
    RXD_d <= RXD;
end

top #(
    .F_CLOCK        (50_000_000),
    .UART_RATE      (2_000_000),
    .CNT_DISP_WIDTH (14)
) top_inst (
    .clk        (CLK),
    .rst_n      (rst_n),
    .i_uart_rx  (i_rx),
    .o_stcp     (STCP),
    .o_shcp     (SHCP),
    .o_ds       (DS),
    .o_oe       (OE)
);

endmodule
