module AudDSP_tb;

  // Clock and reset
  reg clk;
  reg i_rst_n;

  // Control signals
  reg i_start, i_pause, i_stop;
  reg [7:0] i_speed;
  reg i_slow_0, i_slow_1;

  // i_daclrck as input (must be wire for inout port)
  wire i_daclrck;
  reg i_daclrck_driver;

  // SRAM and other signals
  reg [15:0] i_sram_data;
  wire [19:0] o_sram_addr;
  wire [15:0] o_dac_data;
  wire o_player_en;
  reg i_player_ack;

  // Parameters
  localparam SRAM_SIZE = 1024 * 1024;

  // Virtual SRAM
  reg [15:0] sram [SRAM_SIZE-1:0];

  // Clock generation
  initial begin
    clk = 0;
    forever #5 clk = ~clk;  // 100MHz clock (10ns period)
  end

  // Simulate i_daclrck with 30 cycles low, 30 cycles high (input signal)
  initial begin
    i_daclrck_driver = 0;
    forever begin
      repeat(30) @(posedge clk);
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
  always @(posedge clk) begin
    i_sram_data <= sram[o_sram_addr];
  end

  // Simulate player acknowledgment (i_player_ack)
  always @(posedge clk) begin
    if (o_player_en) begin
      // When o_player_en is high, i_player_ack goes high after a few cycles
      #10 i_player_ack <= 1;
      #20 i_player_ack <= 0;  // Acknowledge for 20 time units
    end
  end

  // Simulation setup
  initial begin
    // Dump fsdb file for waveform viewing
    // $fsdbDumpfile("AudDSP_waveform.fsdb");  // Output fsdb file
    // $fsdbDumpvars(0, AudDSP_tb);  // Dump all variables in the testbenc
    $dumpfile("AudDSP_waveform.vcd");
    $dumpvars();
    // Reset system
    i_rst_n = 0;
    i_start = 0;
    i_pause = 0;
    i_stop = 0;
    i_speed = 8'b00000010;  // 0.25x speed
    i_slow_0 = 0;
    i_slow_1 = 1;
    i_player_ack = 0;
    #50;

    // Release reset
    i_rst_n = 1;
    #50;

    // Start playback
    i_start = 1;
    #100;
    i_start = 0;

    // Stop playback and reset to start
  
    #5000;
    i_pause = 1;
    #1000;
    i_pause = 0;
    i_start = 1;

    #100;
    i_start = 0;

    // End simulation
    #300000;
    $finish;
  end

  // Instantiate AudDSP module
  AudDSP dut (
    .i_clk(clk),
    .i_rst_n(i_rst_n),
    .i_start(i_start),
    .i_pause(i_pause),
    .i_stop(i_stop),
    .i_speed(i_speed),
    .i_slow_0(i_slow_0),
    .i_slow_1(i_slow_1),
    .i_daclrck(i_daclrck),  // i_daclrck as input (connected to wire)
    .i_sram_data(i_sram_data),
    .i_fast(),
    .o_sram_addr(o_sram_addr),
    .o_dac_data(o_dac_data),
    .o_player_en(o_player_en),
    .i_player_ack(i_player_ack)
  );

endmodule
