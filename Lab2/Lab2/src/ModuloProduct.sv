module ModuloProduct (
    input  clk,               // 時鐘
    input  rst_n,             // 重置訊號（低電位有效）
    input  start,             // 啟動信號
    input [256:0] N,               // 輸入參數 N
    input [256:0] a,               // 輸入參數 a
    input [256:0] b,               // 輸入參數 b
    input [10:0] k,               // 迴圈次數 k
    output [256:0] result,   // 結果輸出
    output done              // 完成信號
);
    logic [257:0] t;
	logic [257:0] m_r;
	logic [257:0] m_w [0:257];
    integer i; //modified logic to integer
    logic [1:0] state, state_nxt;             // 狀態變數
    //logic [256:0] temp_m, temp_t;  // 用於暫存每次迴圈中的 m 和 t 更新
	logic start_flag;
	logic [257:0] comp;
    logic [256:0] result_w, result_r;
    logic done_w, done_r;

	localparam S_IDLE = 2'b00;
	localparam S_CALC = 2'b01;
	localparam S_DONE = 2'b10;

    assign done = done_r;
    assign result = result_r;

	always_ff @(posedge clk or negedge rst_n) begin
		if(!rst_n) begin
			start_flag <= 0;
            done_r <= 0;
            result_r <= 0;
		end
		else begin 
			if (start) begin
				start_flag <= 1;
			end
			else if ((state == S_DONE) || ((state == S_IDLE) && (state_nxt != S_CALC))) begin
				start_flag <= 0;
			end
			else begin
				start_flag <= 1;
			end
            done_r <= done_w;
            result_r <= result_w;
			m_r <= m_w[i];
		end
	end

	always_ff @(posedge clk or negedge rst_n) begin
		if(!rst_n) begin
			state <= 0;
		end
		else begin 
			state <= state_nxt;
		end
	end


	always_comb begin
		state_nxt = state;
		for (i = 0; i <= 257; i = i + 1) begin
			m_w[i] = 257'b0;
		end

		if (state == S_CALC) begin
			//所有計算
			t = {1'b0,b};
			m_w[0] = 258'b0;
			for (i = 0; (i <= k) && (i <= 256); i = i + 1) begin //modified <= to <, add upper bound constraint
				//#5;
				if(a[i]) begin
					comp = m_w[i] + t;
					if (comp >= {1'b0,N}) begin
						m_w[i+1] = m_w[i] + t - N;
					end
					else begin
						m_w[i+1] = m_w[i] + t;
					end
				end
				else begin
					//m_w = m_r;
					m_w[i+1] = m_w[i];
					comp = 0;
				end
				$display("%h: %h \n", i+1, m_w[i+1]);
				comp = t << 1;
				if (comp >= {1'b0,N}) begin
					t = t + t - N;
				end
				else begin
					t = t << 1;
				end
			end
			done_w = 1'b0;
			state_nxt = S_DONE;
			$display("%h: %h \n", i, m_w[i]);
			result_w = m_w[i][256:0];
			
		end
		else if (state == S_DONE) begin
			//可以輸出結果
			done_w = 1'b1;
			result_w = m_r[256:0];
			//m_w = m_r;//m + 0; modified
			t = 258'b0;
			comp = 258'b0;
			state_nxt = S_IDLE;
		end
		else begin // state == S_IDLE
			//全部設為0
			done_w = 1'b0;
			//m_w = 258'b0;
			t = 258'b0;
			comp = 258'b0;
			result_w = 257'b0;
			if (start_flag) begin
				state_nxt = S_CALC;
			end
			else begin
				state_nxt = S_IDLE;
			end
		end
	end
	
endmodule