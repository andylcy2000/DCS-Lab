`timescale 1ns/1ps
`define CYCLE       5.0     // CLK period.
`define HCYCLE      (`CYCLE/2)
`define MAX_CYCLE   10000000
`define RST_DELAY   2
`define INFILE      "tb/indata.txt"

module testbed;

reg         clk, rst_n;
logic i2c_start, i2c_oen, o_I2C_SCLK, i2c_sdat, i2c_finished;
logic [3:0] i2c_type;

reg  [ 3:0] indata_mem [0:10];

initial begin
    $dumpfile("i2c.vcd");
    $dumpvars();
end

I2cInitializer uut (
    .i_rst_n(rst_n),
    .i_clk(clk),
    .i_start(i2c_start),
    .i_type(i2c_type),
    .o_finished(i2c_finished),
    .o_sclk(o_I2C_SCLK),
    .o_sdat(i2c_sdat),
    .o_oen(i2c_oen)
);

initial $readmemb(`INFILE, indata_mem);

initial clk = 1'b0;
always begin #(`CYCLE/2) clk = ~clk; end

initial begin
    rst_n = 1; # (               0.25 * `CYCLE);
    rst_n = 0; # ((`RST_DELAY - 0.25) * `CYCLE);
    rst_n = 1; # (         `MAX_CYCLE * `CYCLE);
    $display("Error! Runtime exceeded!");
    $finish;
end

localparam S_IDLE = 0;
localparam S_WAIT = 1;

logic [2:0] state;
logic [3:0] cnt;

initial begin
    wait(rst_n == 0);
    state = S_IDLE;
    cnt = 0;
    i2c_start = 0;
    i2c_type = 0;
    wait(rst_n == 1);
    $display("Start simulation");
    while (1) begin
        @(negedge clk);
        i2c_start = 0;
        i2c_type = 0;
        case (state) 
            S_IDLE: begin
                if (cnt == 10) begin
                    $display("End simulation");
                    $finish;
                end
                i2c_start = 1;
                i2c_type = indata_mem[cnt];
                state = S_WAIT;
            end
            S_WAIT: begin
                if (i2c_finished) begin
                    state = S_IDLE;
                    cnt = cnt + 1;
                end
            end
        endcase
    end
end

endmodule
