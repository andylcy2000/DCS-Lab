module tb_Read_VGA;

  // Inputs
  reg i_en;
  reg i_direction;
  reg [31:0] i_total_steps;
  reg i_Clk, i_rst_n;

  // Outputs
  wire o_step_control;
  wire o_direction;
  wire o_done;

  // Instantiate the module
  Motor_Control uut (
    .i_Clk(i_Clk),
    .i_rst_n(i_rst_n),
    .i_en(i_en),
    .i_direction(i_direction),
    .i_total_steps(i_total_steps),
    .o_step_control(o_step_control),
    .o_direction(o_direction),
    .o_done(o_done)
  );

  // Clock generation (50 MHz clock)
  always begin
    #10 i_Clk = ~i_Clk; // 50 MHz clock period is 20ns
  end

  // Initial block for initializing signals and driving the test
  initial begin
    // Initialize signals
    i_Clk = 0;
    i_rst_n = 0;
    i_en = 0;
    i_direction = 0;
    i_total_steps = 0;
    
    // Set up FSDB dumping
    $fsdbDumpfile("motor_control_wave.fsdb");  // Specify FSDB output file name
    $fsdbDumpvars(0, uut);                // Dump all signals from the uut (Read_VGA module)
    
    // Apply reset
    #50;
    i_rst_n = 1; // Release reset
    
    // Start signal pulse
    #20;
    i_en = 1; // Assert start signal
    i_direction = 1;
    i_total_steps = 10;
    #20;
    i_en = 0; // Deassert start signal
    i_direction = 0;
    i_total_steps = 0;
    
    
    // Check if the o_done signal is asserted
    wait(o_done == 1);
    
    // End of simulation
    $finish;
  end

endmodule
