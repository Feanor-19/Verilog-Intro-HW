module top #(
    parameter F_CLOCK = 50_000_000,
    parameter F_TIMER = 10,
    parameter MAX_VAL = 600,
    parameter CNT_DISP_WIDTH = 14
) (
    input  wire clk,
    input  wire rst_n,

    output wire o_stcp,
    output wire o_shcp,
    output wire o_ds,
    output wire o_oe
);

localparam TMR_VAL_WIDTH = $clog2(MAX_VAL);

wire  [3:0] anodes;
wire  [7:0] segments;

wire shift_done;

wire [15:0] timer_val;

assign timer_val[15:TMR_VAL_WIDTH] = {(16-TMR_VAL_WIDTH){1'b0}};

timer #(
    .F_CLOCK (F_CLOCK),
    .F_TIMER (F_TIMER),
    .MAX_VAL (MAX_VAL)
) timer_inst (
    .clk         (clk),
    .rst_n       (rst_n),
    .o_timer_val (timer_val[TMR_VAL_WIDTH-1:0])
);

hex_display #(
    .CNT_WIDTH(CNT_DISP_WIDTH)
) hex_display (
    .clk        (clk),
    .rst_n      (rst_n),
    .i_data     (timer_val),
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
