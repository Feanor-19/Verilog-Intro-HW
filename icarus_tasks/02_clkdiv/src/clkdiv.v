// supports cases when F_INP/F_OUT isn't an integer
// duty cycle is NOT 50%
module clkdiv #(
   parameter F_INP = 50_000_000,
   parameter F_OUT = 9_600
)(
   input  wire clk,
   input  wire rst_n,
   output reg  out
);

localparam THRESHOLD = F_INP;
localparam INCREMENT = F_OUT;
localparam CNT_WIDTH = $clog2(THRESHOLD+INCREMENT);

reg [CNT_WIDTH-1:0] cnt;

generate 
if (4*F_OUT >= F_INP) begin
    always @(posedge clk, negedge rst_n) begin
        if (!rst_n) begin
            cnt <= 0;
            out <= 0;
        end else begin
            cnt <= cnt + INCREMENT;
            if (cnt >= THRESHOLD) begin
                out <= 1'b1;
                cnt <= cnt + INCREMENT - THRESHOLD;
            end else begin
                out <= 1'b0;
            end
        end
    end
end else begin
    always @(posedge clk, negedge rst_n) begin
        if (!rst_n) begin
            cnt <= 0;
            out <= 0;
        end else begin
            cnt <= cnt + INCREMENT;
            if (cnt >= THRESHOLD) begin
                cnt <= cnt + INCREMENT - THRESHOLD;
            end 
            
            if (cnt > THRESHOLD/2) begin
                out <= 1'b1;
            end else begin
                out <= 1'b0;
            end
        end
    end

end
endgenerate

endmodule
