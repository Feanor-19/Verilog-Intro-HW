module top #(
    parameter [15:0] NUM_TO_DISPLAY = 16'h19AB,
    parameter CNT_WIDTH = 14
) (
    input  wire clk,
    input  wire rst_n,

    output wire o_stcp,
    output wire o_shcp,
    output wire o_ds,
    output wire o_oe
);

wire  [3:0] anodes;
wire  [7:0] segments;

wire shift_done;

hex_display #(
    .CNT_WIDTH(CNT_WIDTH)
) hex_display (
    .clk        (clk),
    .rst_n      (rst_n),
    .i_data     (NUM_TO_DISPLAY),
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
