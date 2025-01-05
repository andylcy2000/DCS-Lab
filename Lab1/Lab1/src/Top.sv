module Top (
	input        i_clk,
	input        i_rst_n,
	input        i_start,
	output [3:0] o_random_out,
	output [3:0] o_last_result
);



// ===== States =====
parameter S_IDLE = 1'b0;
parameter S_PROC = 1'b1;

// counter size
parameter CNT_SIZE = 5'd23;

//Registers and Wires
//state
logic state_r, state_w;

//output
logic [3:0] o_random_out_r, o_random_out_w, o_random_out_LFSR;

//counter for output speed
logic [CNT_SIZE-1:0] cnt, cnt_nxt;
logic [7:0] cnt_small, cnt_small_nxt;
logic LFSR_start, LFSR_start_nxt;
logic [3:0] last_result, last_result_nxt, last_result_show;

// LFSR instantiation
LFSR LFSR0(
	.i_clk(i_clk),
	.i_rst_n(i_rst_n),
	.i_start(LFSR_start),
	.o_random_out(o_random_out_LFSR)
);

//assign
assign o_random_out = o_random_out_r;
assign o_last_result = last_result;

//counter
always_comb begin
	if(state_r == S_PROC) begin
		cnt_small_nxt = cnt_small;
		if(cnt == {2'b0, {21{1'b1}}}) begin
			cnt_nxt = 23'b0;
			cnt_small_nxt = cnt_small + 1;
		end
		else
			cnt_nxt = cnt + 1;
	end
	else begin
		cnt_nxt = 23'b0;
		cnt_small_nxt = 8'b0;
	end
end

// last result
always_comb begin

	last_result_nxt = last_result;
	if(state_w == S_PROC && state_r == S_IDLE) // start next random procedure
		last_result_nxt = o_random_out;
end

//FSM

always_comb begin
	//Default
	o_random_out_w = o_random_out_r;
	state_w        = state_r;
	LFSR_start_nxt = 1'b0;
	// FSM
	case(state_r)
	S_IDLE: begin
		if (i_start) begin
			// key0 is pressed
			state_w = S_PROC;
			//cnt_small_nxt = 0;
			//o_random_out_w = 4'd00;
		end
	end

	S_PROC: begin
		state_w = (cnt_small == 8'd55) ? S_IDLE : state_r;
		o_random_out_w = o_random_out_LFSR;
		case (cnt_small)
			8'd01, 8'd03, 8'd06, 8'd10, 8'd15, 8'd21, 8'd28, 8'd36, 8'd45, 8'd55: begin
				if(cnt == 23'b0) begin
					LFSR_start_nxt = 1'b1;
				end
			end
			default: LFSR_start_nxt = 1'b0;
		endcase
	end

	endcase
end

// please check out the working example in lab1 README (or Top_exmaple.sv) first
always_ff @(posedge i_clk or negedge i_rst_n) begin
	if (!i_rst_n) begin
		o_random_out_r <= 4'd0;
		state_r <= S_IDLE;
		cnt <= 23'd0;
		cnt_small <= 8'd0;
		LFSR_start <= 1'b0;
		last_result <= 4'b0;
	end
	else begin
		o_random_out_r <= o_random_out_w;
		state_r        <= state_w;
		cnt <= cnt_nxt;
		cnt_small <= cnt_small_nxt;
		LFSR_start <= LFSR_start_nxt;
		last_result <= last_result_nxt;
	end
end
endmodule