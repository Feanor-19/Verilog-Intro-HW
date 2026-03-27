module top #(
    parameter F_CLOCK = 50_000_000,
    parameter UART_RATE = 2_000_000,
    parameter CNT_DISP_WIDTH = 14
) (
    input  wire clk,
    input  wire rst_n,

    input  wire i_uart_rx, 

    output wire o_stcp,
    output wire o_shcp,
    output wire o_ds,
    output wire o_oe
);

wire  [3:0] anodes;
wire  [7:0] segments;
wire shift_done;

wire uart_dat_vld;
reg [7:0] uart_data_q, uart_data;

always @(posedge clk, negedge rst_n) begin
    if (!rst_n) begin
        uart_data_q <= 8'd0;
    end else begin
        if (uart_dat_vld) begin
            uart_data_q <= uart_data; 
        end
    end
end

uart_rx #(
    .FREQ (F_CLOCK),
    .RATE (UART_RATE)
) uart_rx_inst (
    .clk    (clk),
    .rst_n  (rst_n),

    .o_data (uart_data),
    .o_vld  (uart_dat_vld),
    .i_rx   (i_uart_rx)
);

hex_display #(
    .CNT_WIDTH(CNT_DISP_WIDTH)
) hex_display (
    .clk        (clk),
    .rst_n      (rst_n),
    .i_data     ({8'b0, uart_data_q}),
    .i_rdy      (shift_done),
    .o_anodes   (anodes),
    .o_segments (segments)
);

ctrl_74hc595 ctrl(
    .clk    (clk                ),
    .rst_n  (rst_n              ),
    .i_data ({segments, anodes} ),
    .o_stcp (o_stcp             ),
    .o_shcp (o_shcp             ),
    .o_ds   (o_ds               ),
    .o_oe   (o_oe               ),
    .o_done (shift_done         )
);

endmodule
