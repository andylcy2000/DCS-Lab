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
	

	// FSM

	logic [255:0] o_a_pow_d_r, o_a_pow_d_o_finished_r;

	assign o_a_pow_d = o_a_pow_d_r;
	assign o_finished = o_finished_r;

	function [255:0] montgomery;
		input [255:0] N, a, b;
		logic   [257:0] m;
		integer i;
		begin
			m = 0;
			for (i = 0; i < 256; i = i + 1) begin
				if (a[0] == 1) begin
					m = m + b;
				end
				if (m[0] == 1) begin
					m = m + N;
				end
				m = m >> 1;
				a = a >> 1;
			end
			if (m >= N) begin
				m = m - N;
			end
			montgomery = m;
		end
	endfunction

	function [255:0] RSA256;
		input [255:0] N, y, d;
		logic [255:0] t, m;
		integer i;
		begin
			for (i = 0; i < 256; i = i + 1) begin
				if (d[i] == 1) begin
					m = montgomery(N, m, t);
				end
				t = montgomery(N, t, t);
			end
			RSA256 = m;
		end
	endfunction
	
	always_ff @(posedge i_clk or posedge i_rst) begin
		if (i_rst) begin
			o_a_pow_d <= 0;
			o_finished <= 0;
		end else begin
			o_finished <= 0;
			if (i_start) begin
				o_a_pow_d_r <= RSA256(i_n, i_a, i_d);
				o_finished_r <= 1;
			end
		end
	end

endmodule

