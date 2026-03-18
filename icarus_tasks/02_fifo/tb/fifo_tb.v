module fifo_tb;

reg clk = 1'b0;
reg rst_n = 1'b1;
reg rdy = 1'b0;

reg pass = 1;

localparam TEST_ELEM_WIDTH = 4 + 2 * `DATAW;
reg [TEST_ELEM_WIDTH-1:0] test[`TEST_SIZE];
reg [$clog2(`TEST_SIZE)-1:0] idx = 0;

reg  [`DATAW-1:0] ref_rd_data, ref_wr_data;
reg  ref_rd_en, ref_wr_en, ref_o_empty, ref_o_full;

reg               i_wr_en   = '0;
reg  [`DATAW-1:0] i_wr_data = '0;
reg               i_rd_en   = '0;
wire              o_wr_full;
wire [`DATAW-1:0] o_rd_data;
wire              o_rd_empty;

fifo #(
    .DATA_WIDTH (`DATAW),
    .LOG2_DEPTH (`LOG2DEPTH)
) fifo_inst (.*);

always #1 clk <= ~clk;

function automatic void check();
    bit ok = 1;
    if (ref_o_empty !== o_rd_empty) begin
        $display("[%0t] ERROR: ref_o_empty=%0d, o_rd_empty=%0d", $realtime, ref_o_empty, o_rd_empty);
        ok = 0;
    end

    if (ref_o_full  !== o_wr_full) begin
        $display("[%0t] ERROR: ref_o_full=%0d, o_wr_full=%0d", $realtime, ref_o_full, o_wr_full);
        ok = 0;
    end

    if (ref_o_empty === 0 && ref_rd_data !== o_rd_data) begin
        $display("[%0t] ERROR: ref_rd_data=0x%0x, o_rd_data=0x%0x", $realtime, ref_rd_data, o_rd_data);
        ok = 0;
    end

    if (!ok) pass = 0;
endfunction

initial begin
    wait(rdy);

    @(negedge clk);
    for (idx = 0; idx < `TEST_SIZE; idx++) begin
        {ref_wr_data, ref_rd_data, ref_rd_en, ref_wr_en, ref_o_empty, ref_o_full} = test[idx];

        check();

        i_wr_en = ref_wr_en;
        i_wr_data = ref_wr_data;
        i_rd_en = ref_rd_en;

        @(negedge clk);
    end

    if (pass)
        $display("[%0t] PASS", $realtime);
    else
        $display("[%0t] FAIL", $realtime);

    $finish;
end

initial begin
    string TEST_DAT_FILE;
    if ($value$plusargs("TEST_DAT_FILE=%s", TEST_DAT_FILE)) begin
        $display("TEST_DAT_FILE=%s", TEST_DAT_FILE);
    end else begin
        $display("ERROR: TEST_DAT_FILE not specified!");
        $finish;
    end

    if($test$plusargs("RAND_SEED"))
        $display("NOTE: RAND_SEED is not used directly in this tb.");

    $display("Compiled with `TEST_SIZE=%0d", `TEST_SIZE);
    $display("Compiled with `DATAW=%0d", `DATAW);
    $display("Compiled with `LOG2DEPTH=%0d", `LOG2DEPTH);

    $readmemh(TEST_DAT_FILE, test);
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
