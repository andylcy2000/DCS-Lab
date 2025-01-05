`timescale 1ns/1ps
`define CYCLE       20.0     // CLK period.
`define HCYCLE      (`CYCLE/2)
`define I2C_CYCLE   200.0
`define I2C_HCYCLE  (`I2C_CYCLE/2)
`define I2S_CYCLE   83.3333
`define I2S_HCYCLE  (`I2S_CYCLE/2)
`define DACLRCK_CYCLE (`I2S_CYCLE * 40)
`define DACLRCK_HCYCLE (`DACLRCK_CYCLE / 2)
`define MAX_CYCLE   100000000
`define RST_DELAY   2
`define INFILE      "tb/keys.txt"

module testbed;

logic         clk, rst_n, clk_100k, bclk_driver, daclrck_driver;
wire bclk = bclk_driver;
//wire daclrck = daclrck_driver;
logic keys[4];

logic  [ 3:0] indata_mem [0:9];

// i_daclrck as input (must be wire for inout port)
wire i_daclrck;
reg i_daclrck_driver;

// SRAM and other signals
wire [15:0] i_sram_data;
wire [19:0] o_sram_addr;
wire [15:0] o_dac_data;

// Parameters
localparam SRAM_SIZE = 1024 * 1024;

// Virtual SRAM
reg [15:0] sram [SRAM_SIZE-1:0];

initial begin
    $dumpfile("top.vcd");
    $dumpvars();
end

Top uut (
	.i_rst_n(rst_n),
	.i_clk(clk),
    .i_clk_100k(clk_100k),
    .i_AUD_BCLK(bclk),
    .i_AUD_DACLRCK(i_daclrck),
    .i_AUD_ADCLRCK(i_daclrck),
	.i_key_0(keys[0]),
	.i_key_1(keys[1]),
	.i_key_2(keys[2]),
    .i_key_3(keys[3]),
    .io_SRAM_DQ(i_sram_data),
    .o_SRAM_ADDR(o_sram_addr)
);

initial $readmemb(`INFILE, indata_mem);

initial clk = 1'b0;
always begin #(`CYCLE/2) clk = ~clk; end

initial clk_100k = 1'b0;
always begin #(`I2C_HCYCLE) clk_100k = ~clk_100k; end

initial bclk_driver = 1'b0;
always begin #(`I2S_HCYCLE) bclk_driver = ~bclk_driver; end

initial daclrck_driver = 1'b0;
always begin #(`DACLRCK_HCYCLE) daclrck_driver = ~daclrck_driver; end

initial begin
    rst_n = 1; # (               0.25 * `CYCLE);
    rst_n = 0; # ((`RST_DELAY - 0.25) * `CYCLE);
    rst_n = 1; # (         `MAX_CYCLE * `CYCLE);
    $display("Error! Runtime exceeded!");
    $finish;
end

integer i;
logic [3:0] cnt;

  initial begin
    i_daclrck_driver = 0;
    forever begin
      repeat(100) @(posedge clk);
      i_daclrck_driver = ~i_daclrck_driver;
    end
  end

  // Assign i_daclrck driver to the wire (since it is an inout port in the design)
  assign i_daclrck = i_daclrck_driver;

  // Initialize virtual SRAM with unique data
  initial begin
    integer i;
    for (i = 0; i < SRAM_SIZE; i = i + 1) begin
      sram[i] = i[15:0] ^ 16'hA5A5;  // Ensure each address has unique data
    end
  end

  // Connect SRAM output to i_sram_data based on o_sram_addr
assign i_sram_data = sram[o_sram_addr];


initial begin
    wait(rst_n == 0);
    cnt = 0;
    for (i = 0; i < 4; i = i + 1) begin
        keys[i] = 0;
    end
    wait(rst_n == 1);
    $display("Start simulation");
    # (3200 * `CYCLE);

    while (1) begin
        @(negedge clk);
        if (indata_mem[cnt] === 4'bxxxx) begin
            $display("End simulation");
            $finish;
        end
        # (500 * `CYCLE);
        for (i = 0; i < 4; i = i + 1) begin
            keys[i] = indata_mem[cnt][i];
        end
        # (7 * `CYCLE);
        for (i = 0; i < 4; i = i + 1) begin
            keys[i] = 0;
        end
        cnt = cnt + 1;
    end
end

endmodule
