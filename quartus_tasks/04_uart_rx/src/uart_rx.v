module uart_rx #(
    parameter FREQ = 50_000_000,
    parameter RATE =  2_000_000
) (
    input  wire       clk,
    input  wire       rst_n,

    output wire [7:0] o_data,
    output wire       o_vld,
    input  wire       i_rx
);

localparam [3:0] IDLE  = {1'b0, 3'd0},
                 START = {1'b0, 3'd1},
                 STOP  = {1'b0, 3'd2},
                 BIT0  = {1'b1, 3'd0},
                 BIT1  = {1'b1, 3'd1},
                 BIT2  = {1'b1, 3'd2},
                 BIT3  = {1'b1, 3'd3},
                 BIT4  = {1'b1, 3'd4},
                 BIT5  = {1'b1, 3'd5},
                 BIT6  = {1'b1, 3'd6},
                 BIT7  = {1'b1, 3'd7};

reg [7:0] data;
reg rx_d;
reg [3:0] state, next_state;

wire rx_fall;
wire shift_en;
wire start;
wire en;

assign o_data   = data;
assign rx_fall  = ~i_rx & rx_d;
assign start = (state == IDLE) & rx_fall;
assign o_vld = (state == STOP) & en & i_rx;
assign shift_en = en & state[3];

counter #(
    .CNT_WIDTH  ($clog2(FREQ/RATE)),
    .CNT_LOAD   ((FREQ/RATE)/2),
    .CNT_MAX    (FREQ/RATE-1)
) counter_inst (
    .clk        (clk),
    .rst_n      (rst_n),
    .i_load     (start),
    .o_en       (en)
);

always @(*) begin
    case (state)
        IDLE:    next_state = rx_fall ? START             : state;
        START:   next_state = en      ? (~i_rx?BIT0:IDLE) : state;
        BIT0:    next_state = en      ? BIT1              : state;
        BIT1:    next_state = en      ? BIT2              : state;
        BIT2:    next_state = en      ? BIT3              : state;
        BIT3:    next_state = en      ? BIT4              : state;
        BIT4:    next_state = en      ? BIT5              : state;
        BIT5:    next_state = en      ? BIT6              : state;
        BIT6:    next_state = en      ? BIT7              : state;
        BIT7:    next_state = en      ? STOP              : state;
        STOP:    next_state = en      ? IDLE              : state;

        default: next_state = state;
    endcase
end

always @(posedge clk, negedge rst_n) begin
    if (!rst_n) begin
        state <= IDLE;
    end else begin
        state <= next_state;
    end
end

always @(posedge clk, negedge rst_n) begin
    if (!rst_n) begin
        rx_d <= 1'b0;
    end else begin
        rx_d <= i_rx;
    end
end

always @(posedge clk, negedge rst_n) begin
    if (!rst_n) begin
        data <= 8'd0;
    end else begin
        if (shift_en) begin
            data <= {i_rx, data[7:1]};
        end
    end
end

endmodule
