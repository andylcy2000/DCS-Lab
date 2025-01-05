module AudDSP(
	input i_rst_n,
	input i_clk,
	input i_start,
	input i_pause,
	input i_stop,
	input [7:0] i_speed,
	input i_fast,
	input i_slow_0, // constant interpolation
	input i_slow_1, // linear interpolation
	input i_daclrck,
	input [15:0] i_sram_data,
    input i_player_ack,
	//input [19:0] i_initial_addr,
	output [15:0] o_dac_data,
	output [19:0] o_sram_addr,
    output o_player_en,
    input [19:0] i_last_addr
);

//parameters

//speed definition
localparam xback =  8'b10000000;
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

//

//address
localparam START_ADDR = 20'b0;
localparam END_ADDR = 21'b100000000000000000000;
//


//

//state enumeration
typedef enum logic [2:0] {
    S_IDLE     = 3'b000,
    S_READMEM_AND_PLAY = 3'b001,
    S_PAUSE = 3'b011,
    S_STOP = 3'b100
} state_t;

state_t state_r, state_w;
//

//any register and wire
logic signed [15:0] o_processed_data_r, o_processed_data_w;
logic signed [39:0] temp_data1, temp_data2;
logic signed [39:0] temp_data3;
logic signed [15:0] old_data_r, old_data_w;
logic [19:0] o_sram_addr_r, o_sram_addr_w;
logic daclrck_prev, daclrck_prev2;
logic transmission_en_r, transmission_en_w;
logic [7:0] speed_r, speed_w;
logic [5:0] cnt, cnt_nxt;
logic o_player_en_r, o_player_en_w;
logic [2:0] fall_cnt, fall_cnt_nxt;
logic [26:0] time_cnt, time_cnt_nxt;
logic [5:0] small_time_cnt, small_time_cnt_nxt;
//

//assign
assign o_dac_data = o_processed_data_r;
assign o_sram_addr = o_sram_addr_r;
assign o_player_en = o_player_en_r;
//

//combinational part

//FSM Behavior
always@(*) begin
    state_w = state_r;
    temp_data1 = 40'sb0;
    temp_data2 = 40'sb0;
    temp_data3 = 40'sb0;
    o_sram_addr_w = o_sram_addr_r;
    transmission_en_w = 0; 
    //speed_w = speed_r;
    cnt_nxt = cnt;
    old_data_w = old_data_r;
    o_processed_data_w = o_processed_data_r;
    fall_cnt_nxt = fall_cnt;
    speed_w = i_speed;
    //o_player_en_w = o_player_en_w;
    if (i_player_ack) begin
        o_player_en_w = 1'b0;
    end else begin
        o_player_en_w = o_player_en_r;
    end
    if ((daclrck_prev2 == 1'b1) && (i_daclrck == 1'b1)) begin
        fall_cnt_nxt = 0;
    end
    case (state_r)
        S_IDLE: begin
            if (i_start) begin
                state_w = S_READMEM_AND_PLAY;
            end
            o_sram_addr_w = START_ADDR;
            cnt_nxt = 0;
        end

        S_READMEM_AND_PLAY:begin
            if (i_pause) begin
                state_w = S_PAUSE;
                o_player_en_w = 1'b0;
                //and the output address is still held
            end

            if (i_stop) begin
                state_w = S_STOP;
                o_player_en_w = 1'b0;
            end

            //wait until LRC transition
            //we choose the left channel for transmission
            if ((daclrck_prev2 == 1'b1) && (i_daclrck == 1'b0)) begin
                transmission_en_w = 1'b1;
                o_player_en_w = 1'b1;
            end

            if (transmission_en_r) begin
                fall_cnt_nxt = 2;
                //o_player_en_w = 1'b1;
            end
            //start transmitting aud data
            if ((fall_cnt == 0)) begin
                //we handle the playspeed by sending address with different interval

                if (speed_r >= 8'b00001000) begin
                    o_processed_data_w = $signed(i_sram_data);//data will be segmented in player 
                    if (o_sram_addr_r > (END_ADDR - speed_r - 1)) begin //about to finish playing
                        o_sram_addr_w = o_sram_addr_r;
                        state_w = S_IDLE;
                    end else begin
                        o_sram_addr_w = o_sram_addr_r + speed_r;
                    end
                    transmission_en_w = 0;
                end                
                case(speed_r)
                    x0_5: begin
                        if (i_slow_0 && !i_slow_1) begin //0 interpolation
                            o_processed_data_w = $signed(i_sram_data);
                            if (cnt >= 1) begin
                                cnt_nxt = 0;
                                //o_sram_addr_w = o_sram_addr_r + 20'd1;
                                if (o_sram_addr_r > (END_ADDR - 20'd02)) begin //about to finish playing
                                    o_sram_addr_w = o_sram_addr_r;
                                    state_w = S_IDLE;
                                end else begin
                                    o_sram_addr_w = o_sram_addr_r + 20'd1;
                                end
                            end else begin
                                cnt_nxt = 1;
                                o_sram_addr_w = o_sram_addr_r;
                            end
                        end
                        else if (!i_slow_0 && i_slow_1) begin //1 interpolation
                            if (cnt >= 1) begin
                                cnt_nxt = 0;
                                o_sram_addr_w = o_sram_addr_r;
                                temp_data1 = $signed(i_sram_data) + $signed(old_data_r);//o_processed_data_r);// new data + old data
                                temp_data2 = $signed(temp_data1 >>> 3'sd1);
                                o_processed_data_w = $signed(temp_data2[15:0]);
                            end else begin
                                cnt_nxt = 1;
                                //o_sram_addr_w = o_sram_addr_r + 20'd1;
                                if (o_sram_addr_r > (END_ADDR - 20'd02)) begin //about to finish playing
                                    o_sram_addr_w = o_sram_addr_r;
                                    state_w = S_IDLE;
                                end else begin
                                    o_sram_addr_w = o_sram_addr_r + 20'd1;
                                end
                                o_processed_data_w = $signed(i_sram_data);
                                old_data_w = $signed(i_sram_data);
                            end
                        end
                        transmission_en_w = 0;
                    end

                    x0_25: begin
                        if (i_slow_0 && !i_slow_1) begin //0 interpolation
                            o_processed_data_w = $signed(i_sram_data);
                            if (cnt >= 3) begin
                                cnt_nxt = 0;
                                //o_sram_addr_w = o_sram_addr_r + 20'd1;
                                if (o_sram_addr_r > (END_ADDR - 20'd02)) begin //about to finish playing
                                    o_sram_addr_w = o_sram_addr_r;
                                    state_w = S_IDLE;
                                end else begin
                                    o_sram_addr_w = o_sram_addr_r + 20'd1;
                                end
                            end else begin
                                cnt_nxt = cnt + 1;
                                o_sram_addr_w = o_sram_addr_r;
                            end
                        end
                        else if (!i_slow_0 && i_slow_1) begin //1 interpolation
                            if (cnt >= 1) begin
                                if (cnt >= 3) begin
                                    cnt_nxt = 0;
                                end else begin
                                    cnt_nxt = cnt + 1;
                                end
                                
                                o_sram_addr_w = o_sram_addr_r;
                                temp_data1 = $signed(i_sram_data)*$signed(cnt) + $signed(old_data_r)*(4'sd4 - $signed(cnt));// new data + old data
                                temp_data2 = $signed(temp_data1 >>> 3'sd2);
                                o_processed_data_w = $signed(temp_data2[15:0]);
                            end else begin //cnt == 0
                                cnt_nxt = 1;
                                //o_sram_addr_w = o_sram_addr_r + 20'd1;
                                if (o_sram_addr_r > (END_ADDR - 20'd02)) begin //about to finish playing
                                    o_sram_addr_w = o_sram_addr_r;
                                    state_w = S_IDLE;
                                end else begin
                                    o_sram_addr_w = o_sram_addr_r + 20'd1;
                                end
                                o_processed_data_w = $signed(i_sram_data);
                                old_data_w = $signed(i_sram_data);
                            end
                        end
                        transmission_en_w = 0;
                    end
                    x0_2: begin
                        if (i_slow_0 && !i_slow_1) begin //0 interpolation
                            o_processed_data_w = $signed(i_sram_data);
                            if (cnt >= 4) begin
                                cnt_nxt = 0;
                                //o_sram_addr_w = o_sram_addr_r + 20'd1;
                                if (o_sram_addr_r > (END_ADDR - 20'd02)) begin //about to finish playing
                                    o_sram_addr_w = o_sram_addr_r;
                                    state_w = S_IDLE;
                                end else begin
                                    o_sram_addr_w = o_sram_addr_r + 20'd1;
                                end
                            end else begin
                                cnt_nxt = cnt + 1;
                                o_sram_addr_w = o_sram_addr_r;
                            end
                        end
                        else if (!i_slow_0 && i_slow_1) begin //1 interpolation
                            if (cnt >= 1 ) begin
                                if (cnt >= 4) begin
                                    cnt_nxt = 0;
                                end else begin
                                    cnt_nxt = cnt + 1;
                                end
                                
                                o_sram_addr_w = o_sram_addr_r;
                                if (cnt <= 3) begin
                                    temp_data1 = $signed(i_sram_data)*$signed(cnt) + $signed(old_data_r)*(4'sd04 - $signed(cnt));// new data + old data
                                    //temp_data3 = ($signed(temp_data1)*(8'sb01100110));
                                // temp_data2 = temp_data3 >> 4;
                                // temp_data2 = temp_data1/3;
                                // temp_data3 = $signed(temp_data1 << 2'sd2) + temp_data1;
                                    temp_data2 = $signed(temp_data2 >>> 5'sd2);
                                end
                                else begin
                                    temp_data2 = $signed(o_processed_data_r);
                                end
                                
                                o_processed_data_w = $signed(temp_data2[15:0]);
                            end else begin //cnt == 0
                                cnt_nxt = 1;
                                //o_sram_addr_w = o_sram_addr_r + 20'd1;
                                if (o_sram_addr_r > (END_ADDR - 20'd02)) begin //about to finish playing
                                    o_sram_addr_w = o_sram_addr_r;
                                    state_w = S_IDLE;
                                end else begin
                                    o_sram_addr_w = o_sram_addr_r + 20'd1;
                                end
                                o_processed_data_w = $signed(i_sram_data);
                                old_data_w = $signed(i_sram_data);
                            end
                        end
                        transmission_en_w = 0;
                    end
                    x0_17: begin
                        if (i_slow_0 && !i_slow_1) begin //0 interpolation
                            o_processed_data_w = $signed(i_sram_data);
                            if (cnt >= 5) begin
                                cnt_nxt = 0;
                                //o_sram_addr_w = o_sram_addr_r + 20'd1;
                                if (o_sram_addr_r > (END_ADDR - 20'd02)) begin //about to finish playing
                                    o_sram_addr_w = o_sram_addr_r;
                                    state_w = S_IDLE;
                                end else begin
                                    o_sram_addr_w = o_sram_addr_r + 20'd1;
                                end
                            end else begin
                                cnt_nxt = cnt + 1;
                                o_sram_addr_w = o_sram_addr_r;
                            end
                        end
                        else if (!i_slow_0 && i_slow_1) begin //1 interpolation
                            if (cnt >= 1) begin
                                if (cnt >= 5) begin
                                    cnt_nxt = 0;
                                end else begin
                                    cnt_nxt = cnt + 1;
                                end
                                
                                o_sram_addr_w = o_sram_addr_r;
                                temp_data1 = $signed(i_sram_data)*$signed(cnt) + $signed(old_data_r)*(5'sd8 - $signed(cnt));// new data + old data
                                //temp_data3 = ($signed(temp_data1)*(8'sb01010101));
                                // temp_data2 = temp_data3 >> 4;
                                // temp_data2 = temp_data1/3;
                                // temp_data3 = $signed(temp_data1 << 2'sd2) + temp_data1;
                                temp_data2 = $signed(temp_data1 >>> 5'sd3);
                                o_processed_data_w = $signed(temp_data2[15:0]);
                            end else begin //cnt == 0
                                cnt_nxt = 1;
                                //o_sram_addr_w = o_sram_addr_r + 20'd1;
                                if (o_sram_addr_r > (END_ADDR - 20'd02)) begin //about to finish playing
                                    o_sram_addr_w = o_sram_addr_r;
                                    state_w = S_IDLE;
                                end else begin
                                    o_sram_addr_w = o_sram_addr_r + 20'd1;
                                end
                                o_processed_data_w = $signed(i_sram_data);
                                old_data_w = $signed(i_sram_data);
                            end
                        end
                        transmission_en_w = 0;
                    end
                    x0_14: begin
                        if (i_slow_0 && !i_slow_1) begin //0 interpolation
                            o_processed_data_w = $signed(i_sram_data);
                            if (cnt >= 6) begin
                                cnt_nxt = 0;
                                //o_sram_addr_w = o_sram_addr_r + 20'd1;
                                if (o_sram_addr_r > (END_ADDR - 20'd02)) begin //about to finish playing
                                    o_sram_addr_w = o_sram_addr_r;
                                    state_w = S_IDLE;
                                end else begin
                                    o_sram_addr_w = o_sram_addr_r + 20'd1;
                                end
                            end else begin
                                cnt_nxt = cnt + 1;
                                o_sram_addr_w = o_sram_addr_r;
                            end
                        end
                        else if (!i_slow_0 && i_slow_1) begin //1 interpolation
                            if (cnt >= 1) begin
                                if (cnt >= 6) begin
                                    cnt_nxt = 0;
                                end else begin
                                    cnt_nxt = cnt + 1;
                                end
                                
                                o_sram_addr_w = o_sram_addr_r;
                                temp_data1 = $signed(i_sram_data)*$signed(cnt) + $signed(old_data_r)*(5'sd8 - $signed(cnt));// new data + old data
                                //temp_data3 = ($signed(temp_data1)*(5'sb01001));
                                // temp_data2 = temp_data3 >> 4;
                                // temp_data2 = temp_data1/3;
                                // temp_data3 = $signed(temp_data1 << 2'sd2) + temp_data1;
                                temp_data2 = $signed(temp_data1 >>> 5'sd3);
                                o_processed_data_w = $signed(temp_data2[15:0]);
                            end else begin //cnt == 0
                                cnt_nxt = 1;
                                //o_sram_addr_w = o_sram_addr_r + 20'd1;
                                if (o_sram_addr_r > (END_ADDR - 20'd02)) begin //about to finish playing
                                    o_sram_addr_w = o_sram_addr_r;
                                    state_w = S_IDLE;
                                end else begin
                                    o_sram_addr_w = o_sram_addr_r + 20'd1;
                                end
                                o_processed_data_w = $signed(i_sram_data);
                                old_data_w = $signed(i_sram_data);
                            end
                        end
                        transmission_en_w = 0;
                    end

                    x0_125: begin
                        if (i_slow_0 && !i_slow_1) begin //0 interpolation
                            o_processed_data_w = $signed(i_sram_data);
                            if (cnt >= 7) begin
                                cnt_nxt = 0;
                                //o_sram_addr_w = o_sram_addr_r + 20'd1;
                                if (o_sram_addr_r > (END_ADDR - 20'd02)) begin //about to finish playing
                                    o_sram_addr_w = o_sram_addr_r;
                                    state_w = S_IDLE;
                                end else begin
                                    o_sram_addr_w = o_sram_addr_r + 20'd1;
                                end
                            end else begin
                                cnt_nxt = cnt + 1;
                                o_sram_addr_w = o_sram_addr_r;
                            end
                        end
                        else if (!i_slow_0 && i_slow_1) begin //1 interpolation
                            if (cnt >= 1) begin
                                if (cnt >= 7) begin
                                    cnt_nxt = 0;
                                end else begin
                                    cnt_nxt = cnt + 1;
                                end
                                
                                o_sram_addr_w = o_sram_addr_r;
                                temp_data1 = $signed(i_sram_data)*$signed(cnt) + $signed(old_data_r)*(5'sd8 - $signed(cnt));// new data + old data
                                temp_data2 = $signed(temp_data1 >>> 3'sd3);
                                o_processed_data_w = $signed(temp_data2[15:0]);
                            end else begin //cnt == 0
                                cnt_nxt = 1;
                                //o_sram_addr_w = o_sram_addr_r + 20'd1;
                                if (o_sram_addr_r > (END_ADDR - 20'd02)) begin //about to finish playing
                                    o_sram_addr_w = o_sram_addr_r;
                                    state_w = S_IDLE;
                                end else begin
                                    o_sram_addr_w = o_sram_addr_r + 20'd1;
                                end
                                o_processed_data_w = $signed(i_sram_data);
                                old_data_w = $signed(i_sram_data);
                            end
                        end
                        transmission_en_w = 0;
                    end

                    x0_33: begin
                        if (i_slow_0 && !i_slow_1) begin //0 interpolation
                            o_processed_data_w = $signed(i_sram_data);
                            if (cnt >= 2) begin
                                cnt_nxt = 0;
                                //o_sram_addr_w = o_sram_addr_r + 20'd1;
                                if (o_sram_addr_r > (END_ADDR - 20'd02)) begin //about to finish playing
                                    o_sram_addr_w = o_sram_addr_r;
                                    state_w = S_IDLE;
                                end else begin
                                    o_sram_addr_w = o_sram_addr_r + 20'd1;
                                end
                            end else begin
                                cnt_nxt = cnt + 1;
                                o_sram_addr_w = o_sram_addr_r;
                            end
                        end
                        else if (!i_slow_0 && i_slow_1) begin //1 interpolation
                            if (cnt >= 1) begin
                                if (cnt >= 2) begin
                                    cnt_nxt = 0;
                                end else begin
                                    cnt_nxt = cnt + 1;
                                end
                                
                                o_sram_addr_w = o_sram_addr_r;
                                temp_data1 = $signed(i_sram_data)*$signed(cnt) + $signed(old_data_r)*(4'sd03 - $signed(cnt));// new data + old data
                                // temp_data3 = ($signed(temp_data1)*(4'sb0101));
                                // temp_data2 = temp_data3 >> 4;
                                // temp_data2 = temp_data1/3;
                                temp_data3 = $signed(temp_data1 << 2'sd2) + temp_data1;
                                temp_data2 = $signed(temp_data3 >>> 3'sd4);
                                o_processed_data_w = $signed(temp_data2[15:0]);
                            end else begin //cnt == 0
                                cnt_nxt = 1;
                                //o_sram_addr_w = o_sram_addr_r + 20'd1;
                                if (o_sram_addr_r > (END_ADDR - 20'd02)) begin //about to finish playing
                                    o_sram_addr_w = o_sram_addr_r;
                                    state_w = S_IDLE;
                                end else begin
                                    o_sram_addr_w = o_sram_addr_r + 20'd1;
                                end
                                o_processed_data_w = $signed(i_sram_data);
                                old_data_w = $signed(i_sram_data);
                            end
                        end
                        transmission_en_w = 0;
                    end
                    xback: begin
                        o_processed_data_w = $signed(i_sram_data);//data will be segmented in player
                        //o_sram_addr_w = o_sram_addr_r + 20'd1;
                        if (o_sram_addr_r == START_ADDR || o_sram_addr_r == (START_ADDR + 20'd1)) // beginning of playing
                            o_sram_addr_w = i_last_addr;
                        else if (o_sram_addr_r < (START_ADDR + 20'd02)) begin //about to finish playing
                            o_sram_addr_w = o_sram_addr_r;
                            state_w = S_IDLE;
                        end else begin
                            o_sram_addr_w = o_sram_addr_r - 20'd1;
                        end
                        transmission_en_w = 0;
                    end
                endcase
            end
        end

        S_PAUSE: begin
            if (i_start) begin
                state_w = S_READMEM_AND_PLAY;
            end
            else if (i_stop) begin
                state_w = S_STOP;
            end
            o_player_en_w = 1'b0;
            //start from the same address as before in the next cycle
        end

        S_STOP: begin
            state_w = S_IDLE;
            cnt_nxt = 0;
            o_player_en_w = 1'b0;
        end
        //default: 
    endcase
end
//
//
//sequential part



always_ff @(posedge i_daclrck or negedge i_rst_n) begin
    if (!i_rst_n) begin
        o_sram_addr_r <= START_ADDR;
        cnt <= 0;
        old_data_r <= 16'sb0;
    end
    else begin
        o_sram_addr_r <= o_sram_addr_w;
        cnt <= cnt_nxt;
        old_data_r <= old_data_w;
    end
end

always_ff @(posedge i_clk or negedge i_rst_n) begin
	if (!i_rst_n) begin
		o_processed_data_r <= 16'sb0;
        
        daclrck_prev <= 0;
        daclrck_prev2 <= 0;
        transmission_en_r <= 0;
        speed_r <= 8'b00001000;
        //cnt <= 0;
        //old_data_r <= 16'sb0;
        o_player_en_r <= 0;
        state_r <= S_IDLE;
        fall_cnt <= 0;
	end
	else begin
        o_processed_data_r <= o_processed_data_w;
		
        daclrck_prev <= i_daclrck;
        daclrck_prev2 <= daclrck_prev;
        transmission_en_r <= transmission_en_w;
        /*
        if(state_r == S_IDLE) begin
            speed_r <= i_speed;
        end else begin
            speed_r <= speed_w;
        end
        */
        speed_r <= speed_w;
        //cnt <= cnt_nxt;
        //old_data_r <= old_data_w;
        o_player_en_r <= o_player_en_w;
        state_r <= state_w;
        fall_cnt <= fall_cnt_nxt;
	end
end
//
endmodule