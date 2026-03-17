module rf_2r1w_tb;

localparam DATA_WIDTH  = 32;
localparam REG_NUM     = 32;

localparam ADDR_WIDTH = $clog2(REG_NUM);

bit pass = 1'b1;

reg clk = 1'b0;
reg rst_n = 1'b1;
reg rdy = 1'b0;

reg [DATA_WIDTH-1:0] rf_model [REG_NUM];

reg [ADDR_WIDTH-1:0] wr_addr, rd1_addr, rd2_addr;
reg [DATA_WIDTH-1:0] wr_data, rd1_data, rd2_data;
reg wr_en = 1'b0;

always #1 clk <= ~clk;

rf_2r1w #(
    .DATA_WIDTH (DATA_WIDTH),
    .REG_NUM    (REG_NUM)
) rf_2r1w_inst (
    .clk        (clk),
    .rst_n      (rst_n),

    .i_rd1_addr (rd1_addr),
    .o_rd1_data (rd1_data),
    .i_rd2_addr (rd2_addr),
    .o_rd2_data (rd2_data),
    .i_wr_addr  (wr_addr),
    .i_wr_data  (wr_data),
    .i_wr_en    (wr_en)
);

function automatic void check();
    if (rd1_data != rf_model[rd1_addr] || rd2_data != rf_model[rd2_addr]) begin
        $display("[%0t] ERROR: read data is not compliant with the model. See traces.", $realtime);
        pass = 1'b0;
    end
endfunction

initial begin
    for (int i = 0; i < REG_NUM; i++)
        rf_model[i]= '0;

    wait(rdy);

    repeat(1000) begin
        @(negedge clk);

        rd1_addr = ADDR_WIDTH'($urandom_range(0, REG_NUM-1));
        rd2_addr = ADDR_WIDTH'($urandom_range(0, REG_NUM-1));

        wr_en = 1'($urandom_range(0, 1));

        if (wr_en) begin
            wr_addr  = ADDR_WIDTH'($urandom_range(0, REG_NUM-1));
            wr_data  = DATA_WIDTH'($urandom());
        
            rf_model[wr_addr] = wr_data;
        end

        @(negedge clk);

        check();
    end

    if (pass)
        $display("[%0t] PASS", $realtime);
    else
        $display("[%0t] FAIL", $realtime);

    $finish;
end

initial begin
    int random_seed;

    if (!$value$plusargs("RAND_SEED=%d", random_seed))
        random_seed = 0;

    $display("Set random seed to %0d", random_seed);
    void'($urandom(random_seed));

    $dumpvars;

    @(negedge clk);
    rst_n = 1'b0;
    @(negedge clk);
    rst_n = 1'b1;

    @(posedge clk);
    $display("[%0t] Start", $realtime);
    rdy = 1'b1;
end

endmodule
