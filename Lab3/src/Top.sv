module Top (
	input i_rst_n,
	input i_clk,
	input i_key_0,
	input i_key_1,
	input i_key_2,
	input i_key_3,
	// input [3:0] i_speed, // design how user can decide mode on your own
	
	// AudDSP and SRAM
	output [19:0] o_SRAM_ADDR,
	inout  [15:0] io_SRAM_DQ,
	output        o_SRAM_WE_N,
	output        o_SRAM_CE_N,
	output        o_SRAM_OE_N,
	output        o_SRAM_LB_N,
	output        o_SRAM_UB_N,
	input 	[7:0] i_speed,
	input 		  i_slow_0,
	input         i_slow_1,
	input		  i_left_en,
	input		  i_right_en,
	// I2C
	input  i_clk_100k,
	output o_I2C_SCLK,
	inout  io_I2C_SDAT,
	
	// AudPlayer
	input  signed i_AUD_ADCDAT,
	input  i_AUD_ADCLRCK,
	input  i_AUD_BCLK,
	input  i_AUD_DACLRCK,
	output signed o_AUD_DACDAT,
	output [3:0] o_SHD_debug,

	output [2:0] state,
	output [5:0] times
	// SEVENDECODER (optional display)
	// output [5:0] o_record_time,
	// output [5:0] o_play_time,

	// LCD (optional display)
	// input        i_clk_800k,
	// inout  [7:0] o_LCD_DATA,
	// output       o_LCD_EN,
	// output       o_LCD_RS,
	// output       o_LCD_RW,
	// output       o_LCD_ON,
	// output       o_LCD_BLON,

	// LED
	// output  [8:0] o_ledg,
	// output [17:0] o_ledr
);

// design the FSM and states as you like

parameter S_START      = 0;
parameter S_START_I2C  = 1;
parameter S_WAIT_I2C   = 2;
parameter S_IDLE       = 3;
parameter S_RECD       = 4;
parameter S_RECD_PAUSE = 5;
parameter S_PLAY       = 6;
parameter S_PLAY_PAUSE = 7;

logic [2:0] state_r, state_w;
logic [3:0] cnt_r, cnt_w;

localparam I_LEFT_LINE_IN  = 4'b0000;
localparam I_RIGHT_LINE_IN = 4'b0001;
localparam I_LEFT_PHONE_OUT = 4'b0010;
localparam I_RIGHT_PHONE_OUT = 4'b0011;
localparam I_ANALOG_PATH = 4'b0100;
localparam I_DIGITAL_PATH = 4'b0101;
localparam I_POWER_DOWN = 4'b0110;
localparam I_DIGITAL_FORMAT = 4'b0111;
localparam I_SAMPLE = 4'b1000;
localparam I_ACTIVE = 4'b1001;

localparam x8 =     8'b01000000;
localparam x7 =     8'b00111000;
localparam x6 =     8'b00110000;
localparam x5 =     8'b00101000;
localparam x4 =     8'b00100000;
localparam x3 =     8'b00011000;
localparam x2 =     8'b00010000;
localparam x1 =     8'b00001000;
localparam x0_5 =   8'b00000001;
localparam x0_33 =  8'b00000010;
localparam x0_25 =  8'b00000011;
localparam x0_2 =   8'b00000100;
localparam x0_17 =  8'b00000101;
localparam x0_14 =  8'b00000110;
localparam x0_125 = 8'b00000111;

localparam CYCLES_S = 27'd12000000; 

logic i2c_start, i2c_started, i2c_oen, i2c_sdat, i2c_finished;
logic [3:0] i2c_type;
logic [19:0] addr_record, addr_play;
logic recorder_start, recorder_pause, recorder_stop;
logic signed [15:0] data_record, data_play, dac_data;
logic [7:0]  speed_r, speed_w;
logic slow0_r, slow0_w;
logic slow1_r, slow1_w;
logic player_en, player_start, player_pause, player_stop;
logic player_start_r, player_start_w;
logic player_pause_r, player_pause_w;
logic player_stop_r, player_stop_w;
logic ack_Ply2Dsp;
logic [7:0] speed;
logic slow0, slow1;
logic [26:0] time_cnt, time_cnt_nxt;
logic [5:0] small_time_cnt, small_time_cnt_nxt;
logic [19:0] last_time_r, last_time_w;
logic [3:0] big_time_cnt, big_time_cnt_nxt;

assign player_start = player_start_r;
assign player_pause = player_pause_r;
assign player_stop = player_stop_r;
assign speed = speed_r;
assign slow0 = slow0_r;
assign slow1 = slow1_r;

assign io_I2C_SDAT = (i2c_oen) ? i2c_sdat : 1'bz;

assign o_SRAM_ADDR = (state_r == S_RECD) ? addr_record : addr_play[19:0];
assign io_SRAM_DQ  = (state_r == S_RECD) ? $signed(data_record) : 16'sdz; // sram_dq as output
assign data_play   = (state_r != S_RECD) ? $signed(io_SRAM_DQ) : 16'sd0; // sram_dq as input

assign o_SRAM_WE_N = (state_r == S_RECD) ? 1'b0 : 1'b1;
assign o_SRAM_CE_N = 1'b0;
assign o_SRAM_OE_N = 1'b0;
assign o_SRAM_LB_N = 1'b0;
assign o_SRAM_UB_N = 1'b0;
// assign o_SHD_debug = (recorder_start)? 1: (recorder_pause)? 2: 3;
assign o_SHD_debug = 4'b0000;

assign state = state_r;
assign times = small_time_cnt;
// below is a simple example for module division
// you can design these as you like

// === I2cInitializer ===
// sequentially sent out settings to initialize WM8731 with I2C protocal
I2cInitializer init0(
	.i_rst_n(i_rst_n),
	.i_clk(i_clk_100k),
	.i_start(i2c_start),//是否要改成r
	.i_type(i2c_type),
	.o_start(i2c_started),
	.o_finished(i2c_finished),
	.o_sclk(o_I2C_SCLK),
	.o_sdat(i2c_sdat),
	.o_oen(i2c_oen) // you are outputing (you are not outputing only when you are "ack"ing.)
);

// === AudDSP ===
// responsible for DSP operations including fast play and slow play at different speed
// in other words, determine which data addr to be fetch for player 

logic signed [15:0] dac_data0, dac_data1;
logic [19:0] addr_play0, addr_play1;
logic player_en0, player_en1;

assign addr_play = i_left_en ? addr_play0 : addr_play1;

AudDSP dsp0(
	.i_rst_n(i_rst_n),
	.i_clk(i_clk),
	.i_start(player_start),
	.i_pause(player_pause),
	.i_stop(player_stop),
	.i_speed(speed),
	.i_fast(1'b0),
	.i_slow_0(slow0), // constant interpolation
	.i_slow_1(slow1), // linear interpolation
	.i_daclrck(i_AUD_DACLRCK),
	.i_sram_data(data_play),
	.i_player_ack(ack_Ply2Dsp),
	//.i_initial_addr(initial_addr),
	.o_dac_data(dac_data0),
	.o_sram_addr(addr_play0),
	.o_player_en(player_en0),
	.i_last_addr(last_time_r)
);

AudDSP dsp1(
	.i_rst_n(i_rst_n),
	.i_clk(i_clk),
	.i_start(player_start),
	.i_pause(player_pause),
	.i_stop(player_stop),
	.i_speed(speed),
	.i_fast(1'b0),
	.i_slow_0(slow0), // constant interpolation
	.i_slow_1(slow1), // linear interpolation
	.i_daclrck(~i_AUD_DACLRCK),
	.i_sram_data(data_play),
	.i_player_ack(ack_Ply2Dsp1),
	//.i_initial_addr(initial_addr),
	.o_dac_data(dac_data1),
	.o_sram_addr(addr_play1),
	.o_player_en(player_en1),
	.i_last_addr(last_time_r)
);

// === AudPlayer ===
// receive data address from DSP and fetch data to sent to WM8731 with I2S protocal
// player will handle the segmentation of the bits of the data

logic ack_Ply2Dsp1;

AudPlayer player0(
	.i_rst_n(i_rst_n),
	.i_bclk(i_AUD_BCLK),
	.i_daclrck(i_AUD_DACLRCK),
	.i_en(player_en0), // enable AudPlayer only when playing audio, work with AudDSP
	.i_dac_data(dac_data0), //dac_data
	.o_ack(ack_Ply2Dsp),
	.o_aud_dacdat(o_AUD_DACDAT0)
);

AudPlayer player1(
	.i_rst_n(i_rst_n),
	.i_bclk(i_AUD_BCLK),
	.i_daclrck(~i_AUD_DACLRCK),
	.i_en(player_en1), // enable AudPlayer only when playing audio, work with AudDSP
	.i_dac_data(dac_data1), //dac_data
	.o_ack(ack_Ply2Dsp1),
	.o_aud_dacdat(o_AUD_DACDAT1)
);

// === AudRecorder ===
// receive data from WM8731 with I2S protocal and save to SRAM
logic [15:0] data_record0, data_record1;
logic [19:0] addr_record0, addr_record1;

AudRecorder recorder0(
	.i_rst_n(i_rst_n),
	.i_clk(i_AUD_BCLK),
	.i_lrc(i_AUD_ADCLRCK),
	.i_start(recorder_start & i_left_en),
	.i_pause(recorder_pause),
	.i_stop(recorder_stop),
	.i_data(i_AUD_ADCDAT),
	.o_address(addr_record0),
	.o_data(data_record0)
);

assign addr_record = i_left_en ? addr_record0 : addr_record1;
assign data_record = i_left_en ? data_record0 : data_record1;

AudRecorder recorder1(
	.i_rst_n(i_rst_n),
	.i_clk(i_AUD_BCLK),
	.i_lrc(i_AUD_ADCLRCK),
	.i_start(recorder_start & i_right_en),
	.i_pause(recorder_pause),
	.i_stop(recorder_stop),
	.i_data(i_AUD_ADCDAT),
	.o_address(addr_record1),
	.o_data(data_record1)
);

always_comb begin
	// design your control here
	state_w = state_r;
	cnt_w = cnt_r;
	i2c_start = 0;
	i2c_type = 0;
	recorder_start = 0;
	recorder_pause = 0;
	recorder_stop = 0;
	player_start_w = 0;
	player_pause_w = 0;
	player_stop_w = 0;
	speed_w = speed_r;
	slow0_w = i_slow_0;
	slow1_w = i_slow_1;
	small_time_cnt_nxt = small_time_cnt;
	time_cnt_nxt = time_cnt;
	big_time_cnt_nxt = 0;
	last_time_w = last_time_r;
	case (state_r)
		S_START: begin
			state_w = S_START_I2C;
			cnt_w = 0;
		end
		S_START_I2C: begin
			if (~i2c_finished) begin
				i2c_start = 1;
				i2c_type = cnt_r;
				if (i2c_started) begin
					state_w = S_WAIT_I2C;
				end
			end
		end
		S_WAIT_I2C: begin
			if (i2c_finished) begin
				if (cnt_r >= 10) begin
					state_w = S_IDLE;
					cnt_w = 0;
				end else begin
					cnt_w = cnt_r + 1;
					state_w = S_START_I2C;
				end
			end
		end
		S_IDLE: begin
			small_time_cnt_nxt = 0;
			time_cnt_nxt = 27'b0;
			big_time_cnt_nxt = 0;
			speed_w = i_speed;
			if (i_key_0) begin
				state_w = S_RECD;
				recorder_start = 1;
			end else if (i_key_1) begin
				state_w = S_PLAY;
				player_start_w = 1;
			end
		end
		S_RECD: begin
			recorder_start = 1;
			last_time_w = addr_record;
			if (time_cnt >= CYCLES_S) begin
				if (small_time_cnt < 31) begin
					small_time_cnt_nxt = small_time_cnt + 1;
					time_cnt_nxt = 27'b0;
				end
				else begin
					small_time_cnt_nxt = 0;
					time_cnt_nxt = 27'b0;
				end
			end else begin
				time_cnt_nxt = time_cnt + 1;
			end
			if (i_key_2) begin
				state_w = S_RECD_PAUSE;
				recorder_pause = 1;
			end else if (i_key_3) begin
				state_w = S_IDLE;
				recorder_stop = 1;
			end
		end
		S_RECD_PAUSE: begin
			recorder_pause = 1;
			if (i_key_0) begin
				state_w = S_RECD;
				recorder_start = 1;
			end else if (i_key_3) begin
				state_w = S_IDLE;
				recorder_stop = 1;
			end
		end
		S_PLAY: begin
			if (time_cnt >= CYCLES_S) begin
				if (small_time_cnt < 31) begin
					small_time_cnt_nxt = small_time_cnt + 1;
					time_cnt_nxt = 27'b0;
				end
				else begin
					small_time_cnt_nxt = 0;
					time_cnt_nxt = 27'b0;
				end
			end
			else begin
				case(speed_r)
					x8: time_cnt_nxt = time_cnt + 8;
					x7: time_cnt_nxt = time_cnt + 7;
					x6: time_cnt_nxt = time_cnt + 6;
					x5: time_cnt_nxt = time_cnt + 5;
					x4: time_cnt_nxt = time_cnt + 4;
					x3: time_cnt_nxt = time_cnt + 3;
					x2: time_cnt_nxt = time_cnt + 2;
					x1: time_cnt_nxt = time_cnt + 1;
					x0_5: begin
						if (big_time_cnt < 1) begin
							big_time_cnt_nxt = big_time_cnt + 1;
						end
						else begin
							big_time_cnt_nxt = 0;
							time_cnt_nxt = time_cnt + 1;
						end
					end
					x0_33: begin
						if (big_time_cnt < 2) begin
							big_time_cnt_nxt = big_time_cnt + 1;
						end
						else begin
							big_time_cnt_nxt = 0;
							time_cnt_nxt = time_cnt + 1;
						end
					end
					x0_25: begin
						if (big_time_cnt < 3) begin
							big_time_cnt_nxt = big_time_cnt + 1;
						end
						else begin
							big_time_cnt_nxt = 0;
							time_cnt_nxt = time_cnt + 1;
						end
					end
					x0_2: begin
						if (big_time_cnt < 4) begin
							big_time_cnt_nxt = big_time_cnt + 1;
						end
						else begin
							big_time_cnt_nxt = 0;
							time_cnt_nxt = time_cnt + 1;
						end
					end
					x0_17: begin
						if (big_time_cnt < 5) begin
							big_time_cnt_nxt = big_time_cnt + 1;
						end
						else begin
							big_time_cnt_nxt = 0;
							time_cnt_nxt = time_cnt + 1;
						end
					end	
					x0_14: begin
						if (big_time_cnt < 6) begin
							big_time_cnt_nxt = big_time_cnt + 1;
						end
						else begin
							big_time_cnt_nxt = 0;
							time_cnt_nxt = time_cnt + 1;
						end
					end
					x0_125: begin
						if (big_time_cnt < 7) begin
							big_time_cnt_nxt = big_time_cnt + 1;
						end
						else begin
							big_time_cnt_nxt = 0;
							time_cnt_nxt = time_cnt + 1;
						end
					end
				endcase
				//time_cnt_nxt = time_cnt + 1;
			end
			if (i_key_2) begin
				state_w = S_PLAY_PAUSE;
				player_pause_w = 1;
			end else if (i_key_3) begin
				state_w = S_IDLE;
				player_stop_w = 1;
			end
		end
		S_PLAY_PAUSE: begin
			if (i_key_1) begin
				state_w = S_PLAY;
				player_start_w = 1;
			end else if (i_key_3) begin
				state_w = S_IDLE;
				player_stop_w = 1;
			end
		end
	endcase
end

always_ff @(posedge i_clk or negedge i_rst_n) begin
	if (!i_rst_n) begin
		state_r <= S_START;
		cnt_r <= 0;
		player_start_r <= 0;
		player_pause_r <= 0;
		player_stop_r <= 0;
		speed_r <= 8'b00001000;
		slow0_r <= 0;
		slow1_r <= 0;
		small_time_cnt <= 0;
		time_cnt <= 27'b0;
		big_time_cnt <= 0;
		last_time_r <= 0;
	end else begin
		state_r <= state_w;
		cnt_r <= cnt_w;
		player_start_r <= player_start_w;
		player_pause_r <= player_pause_w;
		player_stop_r <= player_stop_w;
		speed_r <= speed_w;
		slow0_r <= slow0_w;
		slow1_r <= slow1_w;
		small_time_cnt <= small_time_cnt_nxt;
		time_cnt <= time_cnt_nxt;
		big_time_cnt <= big_time_cnt_nxt;
		last_time_r <= last_time_w;
	end
end

endmodule

