`define CYCLE_TIME 50            

module TestBench;

reg                Clk;
reg                Reset;
integer            i, outfile, counter;
integer            array [0:100];
wire               i_start;
wire               [3:0] o_random_out;

always #(`CYCLE_TIME/2) Clk = ~Clk;

// LFSR lfsr(
// 	.i_clk(Clk),
// 	.i_rst_n(Reset),
// 	.i_start(i_start),
// 	.o_random_out(o_random_out)
// );

Top Top0(
	.i_clk(Clk),
	.i_rst_n(Reset),
	.i_start(i_start),
	.o_random_out(o_random_out)
);
  
initial begin
	$dumpfile("waveform.vcd");
	$dumpvars;

	counter = 0;
	
	// // initialize instruction memory
	// for(i=0; i<256; i=i+1) begin
	//     CPU.Instruction_Memory.memory[i] = 32'b0;
	// end
	
	// // Load instructions into instruction memory
	// $readmemb("instruction.txt", CPU.Instruction_Memory.memory);
	for (i=0; i<100; i=i+1) begin
			array[i] = i % 2;
	end
	
	// Open i_start file
	outfile = $fopen("i_start.txt") | 1;

	Clk = 0;
	Reset = 0;
	
	#(`CYCLE_TIME/4) 
	Reset = 1;
    
end

assign i_start = array[counter];
  
always@(posedge Clk) begin
	if(counter == 100000)    // stop after 30 cycles
		$finish;
	
	counter = counter + 1;

	// $fdisplay(outfile, "counter = %b", counter);
	// $fdisplay(outfile, "o_random_out = %b", o_random_out);
end

endmodule