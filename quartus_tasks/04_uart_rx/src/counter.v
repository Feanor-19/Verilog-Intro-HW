module counter #(
    parameter                 CNT_WIDTH = 0,
    parameter [CNT_WIDTH-1:0] CNT_LOAD  = 0,
    parameter [CNT_WIDTH-1:0] CNT_MAX   = 0
) (
    input  wire clk,
    input  wire rst_n,

    input  wire i_load,
    output wire o_en
);

reg [CNT_WIDTH-1:0] cnt;

assign o_en = (cnt == CNT_MAX);

always @(posedge clk or negedge rst_n) begin
    if (!rst_n)
        cnt <= {CNT_WIDTH{1'b0}};
    else begin
        if (i_load)
            cnt <= CNT_LOAD;
        else if (o_en)
            cnt <= {CNT_WIDTH{1'b0}};
        else
            cnt <= cnt + 1'b1;
    end
end

endmodule
