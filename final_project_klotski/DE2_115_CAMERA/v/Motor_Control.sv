module Motor_Control (
    input i_Clk,
    input i_rst_n,
    input i_en,
    input i_direction,
    input [31:0] i_total_steps,
    output o_step_control,
    output o_direction,
    output o_done
);

//PWM param
localparam TOTAL_CYCLE = 20000;//20000
localparam HIGH_CYCLE = 10000;//10000
localparam LOW_CYCLE = TOTAL_CYCLE - HIGH_CYCLE;
//

//register & wire
logic direction_r, direction_w;
logic [19:0] cnt_r, cnt_w;
logic [31:0] total_cnt_r, total_cnt_w;
logic en_r, en_w;
logic [31:0] total_steps_r, total_steps_w; 
logic step_control_r, step_control_w;
logic done_r, done_w;
//

//assign
assign o_direction = direction_r;
assign o_step_control = step_control_r;
assign o_done = done_r;
//

//state enumeration
typedef enum logic [2:0] {
    S_IDLE     = 3'b000,
    S_ROTATE_HIGH = 3'b001,
    S_ROTATE_LOW = 3'b010,
    S_DONE =3'b011
} state_t;

state_t state_r, state_w;
//

//combinational part

//FSM
always_comb begin
    state_w = state_r;
    case(state_r)
        S_IDLE: begin
            if (i_en) begin
                state_w = S_ROTATE_HIGH;
            end
        end

        S_ROTATE_HIGH: begin
            if (cnt_r >= HIGH_CYCLE) begin
                state_w = S_ROTATE_LOW;
            end
        end

        S_ROTATE_LOW: begin
            if ((cnt_r >= LOW_CYCLE) && (total_cnt_r < total_steps_r)) begin
                state_w = S_ROTATE_HIGH;
            end
            else if ((cnt_r >= LOW_CYCLE) && (total_cnt_r >= total_steps_r)) begin
                state_w = S_DONE;
            end
        end

        S_DONE: begin
            state_w = S_IDLE;
        end
    endcase
end
//

//state behavior
always_comb begin
    direction_w = direction_r;
    cnt_w = cnt_r;
    total_cnt_w = total_cnt_r;
    total_steps_w = total_steps_r;
    done_w = 0;
    step_control_w = 0;
    case(state_r)
        S_IDLE: begin
            cnt_w = 0;
            total_cnt_w = 0;
            total_steps_w = i_total_steps;
            direction_w = i_direction;
        end

        S_ROTATE_HIGH: begin
            if (cnt_r < HIGH_CYCLE) begin
                step_control_w = 1;
                cnt_w = cnt_r + 1;
            end
            else begin
                step_control_w = 0;
                cnt_w = 0;
            end
        end

        S_ROTATE_LOW: begin
            if (cnt_r < LOW_CYCLE) begin
                step_control_w = 0;
                cnt_w = cnt_r + 1;
            end
            else begin
                cnt_w = 0;
                total_cnt_w = total_cnt_r + 1;
            end

            if (total_cnt_r >= total_steps_r) begin
                done_w = 0;
            end
        end

        S_DONE: begin
            done_w = 1;
            cnt_w = 0;
        end
    endcase

end
//

//

//sequential part
always_ff @(posedge i_Clk or negedge i_rst_n) begin
    if (~i_rst_n) begin
        state_r <= S_IDLE;
        cnt_r <= 20'b0;
        direction_r <= 0;
        total_cnt_r <= 0;
        total_steps_r <= 0;
        step_control_r <= 0;
        done_r <= 0;
    end
    else begin
        state_r <= state_w;
        cnt_r <= cnt_w;
        direction_r <= direction_w;
        total_steps_r <= total_steps_w;
        step_control_r <= step_control_w;
        done_r <= done_w;
        total_cnt_r <= total_cnt_w;
    end
end
//
endmodule