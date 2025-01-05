module AudRecorder(
  input i_rst_n,
  input i_clk,
  input i_lrc,  // left/right channel
  input i_start,
  input i_pause,
  input i_stop,
  input signed i_data,
  output [19:0] o_address,
  output signed [15:0] o_data
);
  // FSM states
  localparam S_IDLE = 3'd0;
  localparam S_RECORD = 3'd1;
  localparam S_PAUSE = 3'd2;
  localparam S_WAIT = 3'd3; // wait for the next lrc right channel (lrc = high)
  localparam S_TMP_FIN = 3'd4;
  localparam END_ADDR = 21'b100000000000000000000;
  localparam START_ADDR = 20'b0;
  
  logic [3:0] cnt, cnt_nxt;
  logic [19:0] addr, addr_nxt;
  logic signed [15:0] data, data_nxt;
  logic [2:0] state, state_nxt;
  logic [10:0] cnt_lrc, cnt_lrc_nxt;

  integer i;

  assign o_address = addr;
  assign o_data = $signed(data);
  // assign o_sound = (state == S_RECORD || state == S_WAIT || state == S_TMP_FIN) ? 1 : (state == S_PAUSE) ? 2 : 0;
  // assign o_sound = {|addr[19:15], |addr[14:10], |addr[9:5], |addr[4:0]};
  // FSM
  always_comb begin
    state_nxt = state;
    case(state) // Synopsys parallel_case
      S_IDLE: begin
        if (i_start) 
          state_nxt = S_TMP_FIN;
      end
      S_RECORD: begin
        if (i_pause) 
          state_nxt = S_PAUSE;
        else if (i_stop) 
          state_nxt = S_IDLE;
        else if (cnt == 15) 
          state_nxt = S_TMP_FIN;
      end
      S_TMP_FIN: begin
        if (i_pause)
          state_nxt = S_PAUSE;
        else if (i_stop)  
          state_nxt = S_IDLE;
        else if (!i_lrc) 
          state_nxt = S_WAIT;
      end
      S_WAIT: begin
        if (i_pause) 
          state_nxt = S_PAUSE;
        else if (i_stop) 
          state_nxt = S_IDLE;
        else if (i_lrc) 
          state_nxt = S_RECORD;
      end
      S_PAUSE: begin
        if (i_start) 
          state_nxt = S_TMP_FIN;
        else if (i_stop) 
          state_nxt = S_IDLE;
      end
    endcase
  end

  // Counter
  always@(*) begin
    cnt_nxt = cnt;
    addr_nxt = addr;
    data_nxt = $signed(data);
    cnt_lrc_nxt = cnt_lrc;
    if(i_lrc)
      cnt_lrc_nxt = cnt_lrc + 1;
    case(state) // Synopsys parallel_case full_case
      S_IDLE: begin
        cnt_nxt = 0;
        data_nxt = 16'sb0;
        addr_nxt = 0;
      end
      S_RECORD: begin
        // store data from small address to large address
        data_nxt = $signed(data);
		  data_nxt[cnt] = $signed(i_data);
        if(cnt == 15) begin
          cnt_nxt = 0;
          addr_nxt = addr + 1;
          // if (addr_nxt >= END_ADDR) begin
          //     addr_nxt = START_ADDR;
          // end
        end else begin
          cnt_nxt = cnt + 1;
        end
      end
      S_PAUSE: begin
        cnt_nxt = 0;
        data_nxt = 16'sb0;
      end
      S_WAIT, S_TMP_FIN: begin
        cnt_nxt = 0;
      end
    endcase
  end

  always_ff @(negedge i_clk or negedge i_rst_n) begin
    if (!i_rst_n) begin
      cnt <= 0;
      addr <= 0;
      data <= 16'sb0;
      state <= S_IDLE;
      cnt_lrc <= 0;
    end else begin
      cnt <= cnt_nxt;
      addr <= addr_nxt;
      data <= $signed(data_nxt);
      state <= state_nxt;
      cnt_lrc <= cnt_lrc_nxt;
    end
  end

endmodule