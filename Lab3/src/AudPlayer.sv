module AudPlayer(
  input i_rst_n,
  input i_bclk,
  input i_daclrck,
  input i_en,
  input signed [15:0] i_dac_data,
  output signed o_aud_dacdat,
  output o_ack
);
  // FSM states
  localparam S_IDLE = 3'd0;
  localparam S_PLAY = 3'd1;
  // localparam S_PAUSE = 3'd2;
  localparam S_WAIT = 3'd3; // wait for the next lrc left channel (lrc = low)
  localparam S_TMP_FIN = 3'd4;

  
  logic [3:0] cnt, cnt_nxt;
  logic signed [15:0] dac_data, dac_data_nxt;
  logic [2:0] state, state_nxt;
  logic proceed;
  logic ack_flag, ack_flag_nxt;

  assign o_aud_dacdat = (state == S_PLAY)? $signed(dac_data[cnt]):1'sb0;
  assign proceed = (i_en && !i_daclrck);
  assign o_ack = ack_flag;

  // FSM
  always_comb begin
    state_nxt = state;
    ack_flag_nxt = 0;
    case(state) // Synopsys parallel_case full_case
      S_IDLE: begin
        if (proceed) begin
          state_nxt = S_PLAY;
          ack_flag_nxt = 1;
        end
      end
      S_PLAY: begin
        if (cnt == 15) 
          state_nxt = S_TMP_FIN;
      end
      S_TMP_FIN: begin
        if (i_daclrck) 
          state_nxt = S_WAIT;
      end
      S_WAIT: begin
        if (proceed) begin
          state_nxt = S_PLAY;
          ack_flag_nxt = 1;
        end
      end
    endcase
  end

  // Counter
  always_comb begin
    if (state == S_PLAY) begin
      if (cnt == 15) 
        cnt_nxt = 0;
      else 
        cnt_nxt = cnt + 1;
    end
    else 
      cnt_nxt = 0;
  end

  // load data
  always_comb begin
    dac_data_nxt = $signed(dac_data);
    if ((state == S_WAIT || state == S_IDLE) && proceed) 
      dac_data_nxt = $signed(i_dac_data);
  end

  always_ff @(negedge i_bclk or negedge i_rst_n) begin
    if (!i_rst_n) begin
      cnt <= 0;
      state <= S_IDLE;
      dac_data <= 16'sb0;
      ack_flag <= 0;
    end
    else begin
      cnt <= cnt_nxt;
      state <= state_nxt;
      dac_data <= $signed(dac_data_nxt);
      ack_flag <= ack_flag_nxt;
    end
  end


endmodule