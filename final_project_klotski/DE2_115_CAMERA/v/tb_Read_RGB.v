module tb_Read_VGA;

  // Inputs
  reg i_Start;
  reg [7:0] i_Red, i_Green, i_Blue;
  reg [12:0] i_H_Counter, i_V_Counter;
  reg i_Clk, i_rst_n;

  // Outputs
  wire [23:0] o_block1_avg, o_block2_avg, o_block3_avg, o_block4_avg, o_block5_avg;
  wire [23:0] o_block6_avg, o_block7_avg, o_block8_avg, o_block9_avg, o_block10_avg;
  wire [23:0] o_block11_avg, o_block12_avg, o_block13_avg, o_block14_avg, o_block15_avg;
  wire [23:0] o_block16_avg;
  wire [7:0][7:0][3:0] o_red_avg;
  wire [7:0] o_Red;
  wire o_done;

  // Instantiate the module
  VGA_Controller uutt(	//	Host Side 
						.iRed(i_Red),
						.iGreen(),
						.iBlue(),
						.oRequest(),
						//	VGA Side
						.oVGA_R(o_Red),
						.oVGA_G(),
						.oVGA_B(),
						.oVGA_H_SYNC(),
						.oVGA_V_SYNC(),
						.oVGA_SYNC(),
						.oVGA_BLANK(),
						.oH_Cont(i_H_Counter),
						.oV_Cont(i_V_Counter),

						//	Control Signal
						.iCLK(i_Clk),
						.iRST_N(i_rst_n),
						iZOOM_MODE_SW(0)
							);

  Read_VGA_Grey uut (
    .i_Start(i_Start),
    .i_Red(o_Red),
    .i_Green(i_Green),
    .i_Blue(i_Blue),
    .i_H_Counter(i_H_Counter),
    .i_V_Counter(i_V_Counter),
    .i_Clk(i_Clk),
    .i_rst_n(i_rst_n),
    .o_red_avg(o_red_avg),
    .o_done(o_done)
  );

  // Clock generation (40 MHz clock)
  always begin
    #12.5 i_Clk = ~i_Clk; // 40 MHz clock period is 25ns
  end

  // Initial block for initializing signals and driving the test
  initial begin
    // Initialize signals
    i_Clk = 0;
    i_rst_n = 0;
    i_Start = 0;
    i_Red = 8'b0;
    i_Green = 8'b0;
    i_Blue = 8'b0;
    i_H_Counter = 13'b0;
    i_V_Counter = 13'b0;
    
    // Set up FSDB dumping
    $fsdbDumpfile("read_vga_wave.fsdb");  // Specify FSDB output file name
    $fsdbDumpvars(0, uut);                // Dump all signals from the uut (Read_VGA module)
    
    // Apply reset
    #50;
    i_rst_n = 1; // Release reset
    
    // Start signal pulse
    #25;
    i_Start = 1; // Assert start signal
    #25;
    i_Start = 0; // Deassert start signal
    
    // Apply pixel data (R, G, B) and H, V counters
    for (int v = 0; v < 600; v = v + 1) begin
      for (int h = 0; h < 800; h = h + 1) begin
        i_H_Counter = h;
        i_V_Counter = v;
        
        // Simulate RGB values
        i_Red = $random % 256;
        i_Green = $random % 256;
        i_Blue = $random % 256;
        
        // Wait for the next clock cycle
        #25;
      end
    end
    
    // Check if the o_done signal is asserted
    wait(o_done == 1);
    
    // End of simulation
    $finish;
  end

  // Monitor outputs
  initial begin
    $monitor("At time %t, o_done = %b, o_block1_avg = %h, o_block2_avg = %h", $time, o_done, o_block1_avg, o_block2_avg);
  end

endmodule
