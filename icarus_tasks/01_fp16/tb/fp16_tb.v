module fp16_tb;

reg clk = 1'b0;

always begin
    #1 clk = ~clk;
end

wire [15:0] a, b, add_act, mul_act, add_ref, mul_ref;

wire       add_ref_sign = add_ref[15];
wire [4:0] add_ref_bexp = add_ref[14:10];
wire [9:0] add_ref_mant = add_ref[9:0];

wire       add_act_sign = add_act[15];
wire [4:0] add_act_bexp = add_act[14:10];
wire [9:0] add_act_mant = add_act[9:0];

wire       mul_ref_sign = mul_ref[15];
wire [4:0] mul_ref_bexp = mul_ref[14:10];
wire [9:0] mul_ref_mant = mul_ref[9:0];

wire       mul_act_sign = mul_act[15];
wire [4:0] mul_act_bexp = mul_act[14:10];
wire [9:0] mul_act_mant = mul_act[9:0];

fp16mul fp16mul_inst (
    .i_a      (a),
    .i_b      (b),
    .o_res    (mul_act)
);

fp16add fp16add_inst (
    .i_a      (a),
    .i_b      (b),
    .o_res    (add_act)
);

reg [4*16-1:0] test[`TEST_SIZE];
reg [$clog2(`TEST_SIZE)-1:0] idx = 0;

reg ok_add, ok_mul, pass = 1;

assign {a, b, add_ref, mul_ref} = test[idx];

always @(*) begin
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

    if (mul_ref_bexp == 5'b0) // Zero/denormal
        ok_mul = (mul_act_bexp == 5'h00) && (mul_act_mant == 10'h0) && (mul_act_sign == mul_ref_sign);
    else if (mul_ref_bexp == 5'h1F && mul_ref_mant != 10'b0) // NaN
        ok_mul = (mul_act_bexp == 5'h1F) && (mul_act_mant != 10'b0);
    else if (mul_ref_bexp == 5'h01 && mul_ref_mant == 10'b0) // the smallest normal (abs)
        ok_mul = (mul_act_bexp == 5'h01 && mul_act_mant == 10'b0)  // ok if the same
              || (mul_act_bexp == 5'h01 && mul_act_mant == 10'h1)  // or 1 bit diff in mant
              || (mul_act_bexp == 5'b0  && mul_act_mant == 10'b0); // or got denormal flushed to 0
    else
        ok_mul = (mul_act == mul_ref);
end

always @(posedge clk) begin
    idx <= idx + 1;
    if (!ok_add) begin
        $display("[%d] %h + %h -> %h add_ref=%h ok_add=%d", idx, a, b, add_act, add_ref, ok_add);
    end
    if (!ok_mul) begin
        $display("[%d] %h * %h -> %h mul_ref=%h ok_mul=%d", idx, a, b, mul_act, mul_ref, ok_mul);
    end
    pass <= (ok_add && ok_mul) ? pass : 0;
    if (idx == `TEST_SIZE-1) begin
        $display("Result: %s", pass ? "PASS" : "FAIL");
        $finish;
    end
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
end

endmodule
