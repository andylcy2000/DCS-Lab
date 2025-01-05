module I2cInitializer (
	input i_rst_n,
	input i_clk,
	input i_start,
	input [3:0] i_type,
	output o_start,
	output o_finished,
	output o_sclk,
	output o_sdat,
	output o_oen // you are outputing (you are not outputing only when you are "ack"ing.)
);

localparam I_RESET = 4'b0000;
localparam I_LEFT_LINE_IN  = 4'b1010;
localparam I_RIGHT_LINE_IN = 4'b1001;
localparam I_LEFT_PHONE_OUT = 4'b1000;
localparam I_RIGHT_PHONE_OUT = 4'b0111;
localparam I_ANALOG_PATH = 4'b0001;
localparam I_DIGITAL_PATH = 4'b0010;
localparam I_POWER_DOWN = 4'b0011;
localparam I_DIGITAL_FORMAT = 4'b0100;
localparam I_SAMPLE = 4'b0101;
localparam I_ACTIVE = 4'b0110;

localparam Prefix 		 = 8'b00110100;

localparam Reset         = 16'b0001111000000000;
localparam LeftLineIn    = 16'b0000000010010111;
localparam RightLineIn   = 16'b0000001010010111;
localparam LeftPhoneOut  = 16'b0000010001111001;
localparam RightPhoneOut = 16'b0000011001111001;
localparam AnalogPath	 = 16'b0000100000010101;
localparam DigitalPath	 = 16'b0000101000000000;
localparam PowerDown 	 = 16'b0000110000000000;
localparam DigitalFormat = 16'b0000111001000010;
localparam Sample 		 = 16'b0001000000011001;
localparam Active 		 = 16'b0001001000000001;

localparam S_IDLE 		 = 3'd0;
localparam S_SEND_PREFIX = 3'd1;
localparam S_SEND_DATA   = 3'd2;
localparam S_ACK  		 = 3'd3;
localparam S_START 		 = 3'd4;
localparam S_FINISH		 = 3'd5;


logic [2:0] state_r, state_w;
logic [3:0] cnt_r, cnt_w;
logic [3:0] type_r, type_w;

logic [7:0] o_finished_r, o_finished_w;
logic o_oen_r, o_oen_w;
logic o_sdat_r, o_sdat_w;

assign o_start = (state_r != S_IDLE) ? 1 : 0;
assign o_finished = o_finished_r;
assign o_sclk = (state_r == S_IDLE || state_r == S_START) ? 1 : i_clk;
assign o_sdat = o_sdat_r;
assign o_oen = o_oen_r;

always_comb begin
	state_w = state_r;
	cnt_w = cnt_r;
	type_w = type_r;
	o_sdat_w = 0;
	o_finished_w = 0;
	o_oen_w = 1;
	case (state_r)
		S_IDLE: begin
			o_sdat_w = 1;
			if (i_start) begin
				state_w = S_START;
				type_w = i_type;
			end
		end
		S_START: begin
			state_w = S_SEND_PREFIX;
			cnt_w = 7;
		end
		S_SEND_PREFIX: begin
			cnt_w = cnt_r - 1;
			o_sdat_w = Prefix[cnt_r];
			if (cnt_r == 0) begin
				state_w = S_ACK;
				cnt_w = 15;
			end
		end
		S_SEND_DATA: begin
			cnt_w = cnt_r - 1;
			case (type_r) // synopsys full_case parallel_case
				I_RESET: o_sdat_w = Reset[cnt_r];
				I_LEFT_LINE_IN: o_sdat_w = LeftLineIn[cnt_r];
				I_RIGHT_LINE_IN: o_sdat_w = RightLineIn[cnt_r];
				I_LEFT_PHONE_OUT: o_sdat_w = LeftPhoneOut[cnt_r];
				I_RIGHT_PHONE_OUT: o_sdat_w = RightPhoneOut[cnt_r];
				I_ANALOG_PATH: o_sdat_w = AnalogPath[cnt_r];
				I_DIGITAL_PATH: o_sdat_w = DigitalPath[cnt_r];
				I_POWER_DOWN: o_sdat_w = PowerDown[cnt_r];
				I_DIGITAL_FORMAT: o_sdat_w = DigitalFormat[cnt_r];
				I_SAMPLE: o_sdat_w = Sample[cnt_r];
				I_ACTIVE: o_sdat_w = Active[cnt_r];
			endcase
			if (cnt_r == 8) begin
				state_w = S_ACK;
			end
			if (cnt_r == 0) begin
				state_w = S_ACK;
				cnt_w = 0;
			end
		end
		S_ACK: begin
			o_oen_w = 0;
			if (cnt_r == 0) begin
				state_w = S_FINISH;
			end else begin
				state_w = S_SEND_DATA;
			end
		end
		S_FINISH: begin
			state_w = S_IDLE;
			o_finished_w = 1;
			o_sdat_w = 0;
		end
	endcase
end

always_ff @(posedge i_clk or negedge i_rst_n) begin
	if (~i_rst_n) begin
		state_r <= S_IDLE;
		cnt_r <= 0;
		type_r <= 0;
		o_finished_r <= 0;
		//
		// o_oen_r <= 1;
	end else begin
		state_r <= state_w;
		cnt_r <= cnt_w;
		type_r <= type_w;
		o_finished_r <= o_finished_w;
		//o_sdat_r <= o_sdat_w;
		// o_oen_r <= o_oen_w;
	end
end

always_ff @(negedge i_clk or negedge i_rst_n) begin
	if (~i_rst_n) begin
		o_oen_r <= 1;
		o_sdat_r <= 1;
	end else begin
		o_oen_r <= o_oen_w;
		o_sdat_r <= o_sdat_w;
	end
end

endmodule