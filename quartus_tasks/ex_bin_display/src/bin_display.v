module bin_display #(
  parameter CNT_WIDTH = 14
)(
  input  wire       clk,
  input  wire       rst_n,
  input  wire [3:0] i_data,
  input  wire       i_rdy,
  output wire [3:0] o_anodes,
  output reg  [7:0] o_segments
);

reg [CNT_WIDTH-1:0] cnt;
reg [1:0]           pos;

reg got_rdy;

wire digit = i_data[pos];

always @(posedge clk, negedge rst_n) begin
  if (!rst_n) begin
    cnt <= {CNT_WIDTH{1'b0}};
    pos <= 2'd0;
  end else begin
    if (~(&cnt)) begin
      cnt <= cnt + 1'b1;
    end else if (&cnt & got_rdy) begin
      cnt <= {CNT_WIDTH{1'b0}};
      pos <= pos + 1'b1;
    end
  end
end

always @(posedge clk, negedge rst_n) begin
  if (!rst_n) begin
    got_rdy <= 1'b0;
  end else begin
    if (i_rdy) begin
      got_rdy <= 1'b1;
    end else if (&cnt & got_rdy) begin
      got_rdy <= 1'b0;
    end
  end
end

assign o_anodes = ~(4'b1 << pos);

always @(*) begin
  case (digit)
    1'b0: o_segments = 8'b11111100;
    1'b1: o_segments = 8'b01100000;
  endcase
end

endmodule
