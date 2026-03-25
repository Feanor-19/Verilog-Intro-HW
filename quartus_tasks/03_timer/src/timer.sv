module timer #(
    // Frequencies are supposed to be in Hertz
    parameter F_CLOCK = 50_000_000,
    parameter F_TIMER = 10,
    parameter MAX_VAL = 600,

    parameter TMR_VAL_WIDTH = $clog2(MAX_VAL)
) (
    input  wire                    clk,
    input  wire                    rst_n,
    output reg [TMR_VAL_WIDTH-1:0] o_timer_val
);

localparam CNT_THRESHOLD = F_CLOCK;
localparam CNT_INCREMENT = F_TIMER;
localparam CNT_WIDTH = $clog2(CNT_THRESHOLD+CNT_INCREMENT);

reg [TMR_VAL_WIDTH-1:0] tmr;
reg [CNT_WIDTH-1:0]     cnt;

wire tmr_en;

assign o_timer_val = tmr;

assign tmr_en = (cnt >= CNT_THRESHOLD) ? 1'b1 : 1'b0;

always @(posedge clk, negedge rst_n) begin
    if (!rst_n) begin
        cnt <= {CNT_WIDTH{1'b0}};
    end else begin
        cnt <= cnt + CNT_INCREMENT;
        if (cnt >= CNT_THRESHOLD) begin
            cnt <= cnt + CNT_INCREMENT - CNT_THRESHOLD;
        end
    end
end

always @(posedge clk, negedge rst_n) begin
    if (!rst_n) begin
        tmr <= TMR_VAL_WIDTH'(MAX_VAL);
    end else begin
        if (tmr_en & tmr != {TMR_VAL_WIDTH{1'b0}}) begin
            tmr <= tmr - 1'b1;
        end
    end
end


endmodule
