module fp16add_pipe_tb;

reg clk = 1'b0;
bit rdy = 0;

always begin
    #1 clk = ~clk;
end

reg [15:0] a, b, add_ref;
wire [15:0] add_act;

wire       add_ref_sign = add_ref[15];
wire [4:0] add_ref_bexp = add_ref[14:10];
wire [9:0] add_ref_mant = add_ref[9:0];

wire       add_act_sign = add_act[15];
wire [4:0] add_act_bexp = add_act[14:10];
wire [9:0] add_act_mant = add_act[9:0];

fp16add_pipe fp16add_pipe_inst (
    .clk      (clk),
    .i_a      (a),
    .i_b      (b),
    .o_res    (add_act)
);

reg [3*16-1:0] test[`TEST_SIZE];
reg [$clog2(`TEST_SIZE)-1:0] idx = 0;

reg pass = 1;

// assign {a, b, add_ref} = test[idx];

function bit ok_add();
    if (add_ref_bexp == 5'b0) // Zero/denormal (although the script does DAZ & FTZ also)
        ok_add = (add_act_bexp == 5'h00) && (add_act_mant == 10'h0) && (add_act_sign == add_ref_sign);
    else if (add_ref_bexp == 5'h1F && add_ref_mant != 10'b0) // NaN
        ok_add = (add_act_bexp == 5'h1F) && (add_act_mant != 10'b0);
    else if (add_ref_bexp == 5'h01 && add_ref_mant == 10'b0) // the smallest normal (abs)
        ok_add = (add_act_bexp == 5'h01 && add_act_mant == 10'b0)  // ok if the same
              || (add_act_bexp == 5'h01 && add_act_mant == 10'h1)  // or 1 bit diff in mant
              || (add_act_bexp == 5'b0  && add_act_mant == 10'b0); // or got denormal flushed to 0
    else
        ok_add = (add_act == add_ref); 
endfunction

initial begin
    wait(rdy);

    @(negedge clk);
    {a, b, add_ref} = test[idx];

    while (idx < `TEST_SIZE) begin
        @(negedge clk);
        if (!ok_add()) begin
            $display("[%d] ERROR %h + %h -> %h add_ref=%h", idx, a, b, add_act, add_ref);
            pass = 0;
        end

        idx = idx + 1;
        {a, b, add_ref} = test[idx];
    end

    $display("Result: %s", pass ? "PASS" : "FAIL");
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

    $readmemh(TEST_DAT_FILE, test);

    $dumpvars;
    $display("[%0t] Start", $realtime);

    rdy = 1;
end

endmodule
