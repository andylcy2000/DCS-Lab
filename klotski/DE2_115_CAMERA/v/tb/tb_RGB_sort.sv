module tb_RGB_sort;

  // Inputs
  reg start;
  reg [23:0] block [15:0];
  reg Clk, rst_n;

  // Outputs
  wire [63:0] o_result;
  wire done;

  integer i, j;

  localparam MAX_CYCLE = 1000;
  localparam [23:0] ZERO = 24'hff7fff;
  localparam [23:0] ONE = 24'hffffff;
  localparam [23:0] TWO = 24'hffff00;
  localparam [23:0] THREE = 24'hff7f00;
  localparam [23:0] FOUR = 24'hff007f;
  localparam [23:0] FIVE = 24'hff0000;
  localparam [23:0] SIX = 24'h7fff7f;
  localparam [23:0] SEVEN = 24'h7f7f00;
  localparam [23:0] EIGHT = 24'h7f00ff;
  localparam [23:0] NINE = 24'h7f0000;
  localparam [23:0] TEN = 24'h00ffff;
  localparam [23:0] ELEVEN = 24'h00ff00;
  localparam [23:0] TWELVE = 24'h007fff;
  localparam [23:0] THIRTEEN = 24'h007f00;
  localparam [23:0] FOURTEEN = 24'h00007f;
  localparam [23:0] FIFTEEN = 24'h000000;
  localparam [23:0] testcase [15:0] = '{NINE, FIVE, THREE, SEVEN, ONE, FIFTEEN, ELEVEN, THIRTEEN, TWO, SIX, FOUR, EIGHT, ZERO, FOURTEEN, TEN, TWELVE};
  localparam [63:0] golden_result = {{4'd9, 4'd5, 4'd3, 4'd7, 4'd1, 4'd15, 4'd11, 4'd13, 4'd2, 4'd6, 4'd4, 4'd8, 4'd0, 4'd14, 4'd10, 4'd12}};
  // Instantiate the module
  RGBSort uut (
    .i_start(start),
    .i_clk(Clk),
    .i_rst_n(rst_n),
    .i_block0(block[0]),
    .i_block1(block[1]),
    .i_block2(block[2]),
    .i_block3(block[3]),
    .i_block4(block[4]),
    .i_block5(block[5]),
    .i_block6(block[6]),
    .i_block7(block[7]),
    .i_block8(block[8]),
    .i_block9(block[9]),
    .i_block10(block[10]),
    .i_block11(block[11]),
    .i_block12(block[12]),
    .i_block13(block[13]),
    .i_block14(block[14]),
    .i_block15(block[15]),
    .o_order(o_result),
    .o_done(done)
  );


  function verify_result;
    input [63:0] output_result;
    input [63:0] golden_result;
    reg [63:0] reversed_result;
    for(i=0; i<16; i=i+1) begin
      for(j=0; j<4; j=j+1) begin
        reversed_result[i*4+j] = golden_result[(60-i*4)+j];
      end
    end
    if(output_result !== reversed_result) begin
      $display("Test failed: output_result = %h, golden_result = %h", output_result, reversed_result);
      $finish;
    end
    else begin
      $display("=====================================");
      $display("*********  Test passed  *************");
      $display("=====================================");
      $finish;
    end
  endfunction


  // Clock generation (50 MHz clock)
  always begin
    for(i=0; i<MAX_CYCLE*2; i=i+1)
      #10 Clk = ~Clk; // 50 MHz clock period is 20ns
    $display("Runtime exceeded");
    $finish;
  end

  // Initial block for initializing signals and driving the test
  initial begin
    // Initialize signals
    Clk = 0;
    rst_n = 0;
    start = 0;
    
    // Set up FSDB dumping
    $fsdbDumpfile("RGB_sort.fsdb");  // Specify FSDB output file name
    $fsdbDumpvars(0, "+mda");                // Dump all signals from the uut (Read_VGA module)
    
    // $fsdbDumpfile("core.fsdb");
    // $fsdbDumpvars(0, "+mda");
    // $dumpfile("core.vcd");
    // $dumpvars(0, "+mda");

    
    // Apply reset
    #50;
    rst_n = 1; // Release reset
    
    // Start signal pulse
    #20;
    @ (posedge Clk);
    for(i=0; i<16; i=i+1) begin
      block[i] = testcase[i];
    end
    start = 1; // Assert start signal
    #20;

    
    
    // Check if the o_done signal is asserted
    wait(done == 1);
    @(negedge Clk);
    verify_result(o_result, golden_result);
    
    // End of simulation
    $finish;
  end

endmodule