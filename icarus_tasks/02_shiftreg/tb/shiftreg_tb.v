module shiftreg_tb;

localparam WIDTH = 8;

always #1 clk <= ~clk;

bit pass = 1'b1;

reg clk = 1'b0;
reg rst_n = 1'b1;
reg rdy = 1'b0;

reg [WIDTH-1:0] shiftreg_model;

reg             par_ld_en;
reg [WIDTH-1:0] par_data;

reg sh_en;
reg bit_inp;
reg bit_out;

shiftreg #(
    .WIDTH  (WIDTH)
) shiftreg_inst (
    .clk         (clk),
    .rst_n       (rst_n),

    .i_par_ld_en (par_ld_en),
    .i_par_data  (par_data),
    .i_sh_en     (sh_en),
    .i_bit_inp   (bit_inp),
    .o_bit_out   (bit_out)
);

function automatic void check();
    if (bit_out != shiftreg_model[WIDTH-1]) begin
        $display("[%0t] ERROR: read data is not compliant with the model. See traces.", $realtime);
        pass = 0;
    end
endfunction

initial begin
    shiftreg_model = '0;
    par_ld_en = '0;
    sh_en = '0;

    wait(rdy);

    @(negedge clk);
    repeat(1000) begin

        sh_en = 1'($urandom_range(0, 1));
        par_ld_en = 1'($urandom_range(0,1));

        if (par_ld_en) begin
            par_data = WIDTH'($urandom());
            shiftreg_model = par_data;
        end else if (sh_en) begin
            bit_inp = 1'($urandom());
            shiftreg_model = {shiftreg_model[WIDTH-2:0], bit_inp};
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
