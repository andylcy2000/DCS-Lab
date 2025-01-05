module tb_VGA_Controller;

  // Inputs
  reg [9:0] iRed, iGreen, iBlue;
  reg [12:0] i_H_Counter, i_V_Counter;
  reg i_CLK, iRST_N, iZOOM_MODE_SW;
  reg [4:0] iFromBlock, iToBlock;

  // Outputs
  wire [9:0] oVGA_B;
  wire oRequest;

  // Instantiate the module
  VGA_Controller uut(	//	Host Side 
						.iRed(iRed),
						.iGreen(iGreen),
						.iBlue(iBlue),
						.oRequest(),
						//	VGA Side
						.oVGA_R(),
						.oVGA_G(),
						.oVGA_B(oVGA_B),
						.oVGA_H_SYNC(),
						.oVGA_V_SYNC(),
						.oVGA_SYNC(),
						.oVGA_BLANK(),
						.oH_Cont(),
						.oV_Cont(),

						//	Control Signal
						.iCLK(i_CLK),
						.iRST_N(iRST_N),
						.iZOOM_MODE_SW(0),
                        .iFromBlock(iFromBlock),
                        .iToBlock(iToBlock)
							);


  // Clock generation (40 MHz clock)
  always begin
    #12.5 i_Clk = ~i_Clk; // 40 MHz clock period is 25ns
  end

  // Initial block for initializing signals and driving the test
  initial begin
    // Initialize signals
    i_CLK = 0;
    iRST_N = 0;
    iFromBlock = 5'b0;
    iToBlock = 5'b0;
    iRed = 10'b0;
    iBlue = 10'b0;
    iGreen = 10'b0;
    
    // Set up FSDB dumping
    $fsdbDumpfile("vga_ontroller.fsdb");  // Specify FSDB output file name
    $fsdbDumpvars(0, uut);                // Dump all signals from the uut (Read_VGA module)
    
    // Apply reset
    #50;
    iRST_N = 1; // Release reset
    
    // Start signal pulse
    
    
    wait(oRequest == 1);
    $display("Request");
    
    #1000000;

    
    // End of simulation
    $finish;
  end


endmodule
