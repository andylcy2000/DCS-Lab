module Rsa256Core (
	input          i_clk,
	input          i_rst,
	input          i_start,
	input  [255:0] i_a, // cipher text y
	input  [255:0] i_d, // private key
	input  [255:0] i_n,
	output [255:0] o_a_pow_d, // plain text x
	output         o_finished
);

	// operations for RSA256 decryption
	// namely, the Montgomery algorithm

	localparam S_IDLE = 3'd0;
	localparam S_PREP = 3'd1;
	localparam S_MONT = 3'd2;
	localparam S_CALC = 3'd3;
	localparam S_DONE = 3'd4;

	logic [2:0] state, state_nxt;
	logic [8:0] cnt, cnt_nxt;
	logic [255:0] o_a_pow_d_r, o_a_pow_d_o_finished_r;
	logic [255:0] m_w, t_w;
	logic [255:0] m_r, t_r;
	logic [255:0] m_mont, t_mont, t_prep;	// output of m, t from mont and prep
	logic [255:0] N, d, a;	// loaded data
	logic [255:0] N_nxt, d_nxt, a_nxt;
	logic Mont_finish, Mont_finish_m, Mont_finish_t, Prep_finish; // finished signal from mont and prep
	logic Mont_ready, Prep_ready;	// ready signal for mont and prep
	logic [7:0] i_d_index; // 
	logic start_flag, start_flag_nxt;
	
	
	Montgomery Montgomery_m(
		.i_clk(i_clk),
		.i_rst(i_rst),
		.i_start(Mont_ready),
		.o_montgomery(m_mont),
		.i_N(N),
		.i_a(m_r),
		.i_b(t_r),
		.o_finished(Mont_finish_m)
	);
	Montgomery Montgonery_t(
		.i_clk(i_clk),
		.i_rst(i_rst),
		.i_start(Mont_ready),
		.o_montgomery(t_mont),
		.i_N(N),
		.i_a(t_r),
		.i_b(t_r),
		.o_finished(Mont_finish_t)
	);

	ModuloProduct ModuloProduct0(
		.clk(i_clk),
		.rst_n(i_rst),
		.start(Prep_ready),
		.N({1'b0, N}),
		.a({1'b1, 256'b0}),
		.b({1'b0, a}),
		.k(11'd256),
		.result(t_prep),
		.done(Prep_finish)
	);

	assign Mont_finish = Mont_finish_t && Mont_finish_m;
	assign Mont_ready = (state == S_MONT && start_flag);
	assign Prep_ready = (state == S_PREP && start_flag);
	// assign i_d_index = (cnt > 0)? (256-cnt): 0;
	assign i_d_index = cnt>0? cnt-1: 0;
	assign o_a_pow_d = (state == S_DONE)? m_r: 0;
	assign o_finished = (state == S_DONE);

	// Counter
	always @(*) begin
		cnt_nxt = cnt;
		if(state == S_CALC) begin
			if(cnt != 256)	cnt_nxt = cnt + 1;
			else	cnt_nxt = 0;
		end
	end

	// FSM
	always @(*) begin
		state_nxt = state;
		start_flag_nxt = 0;
		case(state)
			S_IDLE: begin
				if(i_start)	begin
					state_nxt = S_PREP;
					start_flag_nxt = 1;
				end
			end
			S_PREP: begin
				if(Prep_finish) state_nxt = S_CALC;
			end
			S_MONT: begin
				if(Mont_finish)	state_nxt = S_CALC;
			end
			S_CALC: begin
				if(cnt != 256) begin
					state_nxt = S_MONT;
					start_flag_nxt = 1;
				end
					
				else state_nxt = S_DONE;
			end
			S_DONE: begin
				state_nxt = S_IDLE;
			end
		endcase
	end


	// load data
	always @(*) begin
		N_nxt = N;
		a_nxt = a;
		d_nxt = d;
		if(i_start && state == S_IDLE) begin
			N_nxt = i_n;
			a_nxt = i_a;
			d_nxt = i_d;
		end
	end
	
	// update t, m
	always @(*) begin
		m_w = m_r;
		t_w = t_r;
		if(state == S_PREP && Prep_finish) begin
			m_w = 1;
			t_w = t_prep;
		end
		else if(state == S_MONT && Mont_finish) begin
			if(d[i_d_index] == 1'b1)
				m_w = m_mont;
			t_w = t_mont;
		end
	end

	always_ff @(posedge i_clk or posedge i_rst) begin
		if (i_rst) begin
			cnt <= 0;
			state <= S_IDLE;
			m_r <= 0;
			t_r <= 0;
			N <= 0;
			a <= 0;
			d <= 0;
			start_flag <= 0;
		end else begin
			cnt <= cnt_nxt;
			state <= state_nxt;
			N <= N_nxt;
			a <= a_nxt;
			d <= d_nxt;
			m_r <= m_w;
			t_r <= t_w;
			start_flag <= start_flag_nxt;
		end
	end

endmodule





module ModuloProduct (
    input  clk,               // 時鐘
    input  rst_n,             // 重置訊號（低電位有效）
    input  start,             // 啟動信號
    input [256:0] N,               // 輸入參數 N
    input [256:0] a,               // 輸入參數 a
    input [256:0] b,               // 輸入參數 b
    input [10:0] k,               // 迴圈次數 k
    output [255:0] result,   // 結果輸出
    output done              // 完成信號
);
    logic [257:0] t;
	logic [257:0] m_r, t_r;
	logic [257:0] m_w, t_w;
	logic [257:0] temp_m [0:4];
	logic [257:0] temp_t [0:4];
    integer i; //modified logic to integer
	integer idx;
    logic [1:0] state, state_nxt;             // 狀態變數
	logic [8:0] cycle, cycle_nxt;
    //logic [256:0] temp_m, temp_t;  // 用於暫存每次迴圈中的 m 和 t 更新
	logic start_flag;
	logic [257:0] comp;
    logic [255:0] result_w, result_r;
    logic done_w, done_r;

	localparam S_IDLE = 2'b00;
	localparam S_CALC = 2'b01;
	localparam S_DONE = 2'b10;
	localparam ITERATIONS_PER_CYCLE = 1;
	localparam CYCLES = 9'd257;
    assign done = done_r;
    assign result = result_r;

	always_ff @(posedge clk or posedge rst_n) begin
		if(rst_n) begin
			start_flag <= 0;
            done_r <= 0;
            result_r <= 0;
			m_r <= 0;
			t_r <= 0;
			cycle <= 0;
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
			m_r <= m_w;
			t_r <= t_w;
			cycle <= cycle_nxt;
		end
	end

	always_ff @(posedge clk or posedge rst_n) begin
		if(rst_n) begin
			state <= 0;
		end
		else begin 
			state <= state_nxt;
		end
	end


	always @(*) begin
		idx = 0;
		comp = 0;
		state_nxt = state;
		cycle_nxt = 0;
		/*
		for (i = 0; i <= 257; i = i + 1) begin
			m_w[i] = 257'b0;
		end
		*/
		if (cycle == 0) begin
			result_w = 256'b0;
			t_w = 258'b0;
			m_w = 258'b0;
		end
		else begin
			result_w = result_r;
			t_w = t_r;
			m_w = m_r;
		end
		for (i = 0; i <= 4; i = i + 1) begin
			temp_m[i] = 257'b0;
			temp_t[i] = 257'b0;
		end
		
		if (state == S_CALC) begin
			//所有計算
			//t = {1'b0,b};
			if (cycle == 0) begin
				temp_t[0] = {1'b0,b};
				temp_m[0] = m_w;
			end
			else begin
				temp_t[0] = t_r;
				temp_m[0] = m_r;
			end
			//m_w[0] = 258'b0;
			cycle_nxt = cycle + 1;
			if (cycle < CYCLES) begin
				for (i = 0; i < 1; i = i + 1) begin
					idx = cycle*ITERATIONS_PER_CYCLE + i;
					if ((idx <= 256) && (idx <= k)) begin
						//$display("%d: %d \n", idx, a[idx]);
						// $display("%d: %d \n", idx, a[idx]);
						if(a[idx]) begin
							comp = temp_m[i] + temp_t[i];
							if (comp >= {1'b0,N}) begin
								temp_m[i+1] = temp_m[i] + temp_t[i] - N;
							end
							else begin
								temp_m[i+1] = temp_m[i] + temp_t[i];
							end
						end 
						else begin
							temp_m[i+1] = temp_m[i];
						end
						//$display("%h: %h \n", idx, temp_m[i]);
						comp = temp_t[i] << 1;
						if (comp >= {1'b0,N}) begin
							temp_t[i+1] = temp_t[i] + temp_t[i] - N;
						end
						else begin
							temp_t[i+1] = temp_t[i] << 1;
						end
						
					end
					else begin
						temp_m[i+1] = temp_m[i];
						temp_t[i+1] = temp_t[i];
					end
				end
				m_w = temp_m[i];
				t_w = temp_t[i];
				result_w = m_w[255:0];
				/*
				if (idx >= 256) begin
					$display("%d (m_w): %h \n", idx, m_w);
				end
				*/
			end
			
			if (cycle >= CYCLES) begin
				state_nxt = S_DONE;
				result_w = m_r[255:0];
				m_w = m_r;
			end
			done_w = 1'b0;
			/*
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
			*/
		end
		else if (state == S_DONE) begin
			//可以輸出結果
			done_w = 1'b1;
			result_w = m_r[255:0];
			//m_w = m_r;//m + 0; modified
			t_w = 258'b0;
			comp = 258'b0;
			state_nxt = S_IDLE;
			/*
			$display("a: %d \n", a);
			$display("b: %d \n", b);
			$display("N: %d \n", N);
			*/
		end
		else begin // state == S_IDLE
			//全部設為0
			done_w = 1'b0;
			//m_w = 258'b0;
			t_w = 258'b0;
			comp = 258'b0;
			result_w = 256'b0;
			if (start_flag) begin
				state_nxt = S_CALC;
			end
			else begin
				state_nxt = S_IDLE;
			end
		end
	end
	
endmodule

module Montgomery (
    input          i_clk,
    input          i_rst,
    input          i_start,
    input  [255:0] i_N, i_a, i_b,
    output [255:0] o_montgomery,
    output         o_finished
);
    typedef enum logic {
        S_IDLE,
        S_CALC
    } state_t;

    localparam m_size = 1;
    localparam cycles = 256 / m_size;

    state_t state, state_nxt;
    logic [257:0] tmp1 [0:m_size-1];
    logic [257:0] tmp2 [0:m_size-1];
    logic [257:0] tmp3 [0:m_size-1];
    logic [257:0] m_r;
    logic [257:0] m_w;
    logic [255:0] N, a, b;
    logic [255:0] o_montgomery_r;
    logic o_finished_r;
    logic [8:0] cycle, cycle_nxt;
    logic [255:0] filter, filter_nxt;
    integer i;

    assign o_finished = o_finished_r;
    assign o_montgomery = o_montgomery_r;

    always @(*) begin
        state_nxt = state;
        cycle_nxt = 0;
        filter_nxt = 1;
        for (i = 0; i < m_size; i = i + 1) begin
            tmp1[i] = 0;
            tmp2[i] = 0;
            tmp3[i] = 0;
        end
        m_w = 0;
        case(state)
            S_IDLE: begin
                if(i_start) begin
                    state_nxt = S_CALC;
                end
                filter_nxt = 1;
            end
            S_CALC: begin
                cycle_nxt = cycle + 1;
                filter_nxt = filter << m_size;
                if(cycle < cycles) begin
                    state_nxt = S_CALC;
                    tmp1[0] = (| (a & filter)) ? m_r +b: m_r;
                    tmp2[0] = (| (tmp1[0] & 1'b1)) ? tmp1[0] + N : tmp1[0];
                    tmp3[0] = tmp2[0] >> 1;
                    for (i = 1; i < m_size; i = i + 1) begin
                        tmp1[i] = (| (a & (filter << i))) ? tmp3[i - 1]+b: tmp3[i - 1];
                        tmp2[i] = (| (tmp1[i] & 1'b1)) ? tmp1[i] + N : tmp1[i];
                        tmp3[i] = tmp2[i] >> 1;
                    end
                    m_w = tmp3[m_size - 1];
                end else begin
                    state_nxt = S_IDLE;
                    cycle_nxt = 0;
                end
            end
        endcase
    end

    always_ff @(posedge i_clk or posedge i_rst) begin
        if (i_rst) begin
            m_r <= 0;
            state <= S_IDLE;
            cycle <= 0;
            o_finished_r <= 0;
            o_montgomery_r <= 0;
            filter <= 1;
            a <= 0;
            b <= 0;
            N <= 0;
        end else begin
            o_finished_r <= 0;
            o_montgomery_r <= (m_r >= {2'b0, N}) ? m_r - N : m_r;
            state <= state_nxt;
            cycle <= cycle_nxt;
            filter <= filter_nxt;
            if (state == S_IDLE && state_nxt == S_CALC) begin
                N <= i_N;
                a <= i_a;
                b <= i_b;
                m_r <= 0;
            end else if (state == S_CALC && state_nxt == S_CALC) begin
                m_r <= m_w;
            end else if (state == S_CALC && state_nxt == S_IDLE) begin
                o_finished_r <= 1;
            end
        end
    end

    
    
endmodule