module Top_Control(
    input i_Clk,
    input i_rst_n,
    input i_start,
    input i_read_VGA_done,
    input i_move_en,
    input i_alg_done,
    input [0:1][1:0] i_end_block,
    input [3:0] i_end_block_number,
    input i_bm_done,
    input [0:3][0:3][3:0] i_klotski,
    output [3:0][3:0][3:0] o_klotski,
    output reg o_read_vga_start,
    output o_start_alg,
    output o_algo_continue,
    output reg o_bm_en,
    output o_done,
    output logic [3:0] o_tmp,
    output [2:0] o_state
);

logic [3:0][3:0][3:0] klotski_r, klotski_w;

logic done_r, done_w;
logic start_alg_r, start_alg_w;
logic started_r, started_w;
logic algo_continue_r, algo_continue_w;

assign o_klotski = klotski_r;
assign o_start_alg = start_alg_r;
assign o_done = done_r;
assign o_algo_continue = algo_continue_r;
assign o_state = state_r;

typedef enum logic [2:0] {
    S_IDLE,
    S_VGA,
    S_ALGO,
    S_MOTOR,
    S_DONE
} state_t;

state_t state_r, state_w;

always_comb begin
    state_w = state_r;
    started_w = started_r;
    done_w = 0;
    start_alg_w = 0;
    algo_continue_w = 0;
    o_read_vga_start = 0;
    o_bm_en = 0;
    klotski_w = klotski_r;
    o_tmp = i_klotski[i_end_block[0]][i_end_block[1]];
    case (state_r)
        S_IDLE: begin
            if (i_start) begin
                state_w = S_VGA;
                started_w = 0;
                o_read_vga_start = 1;
            end
        end
        S_VGA: begin
            if (i_read_VGA_done) begin
                state_w = S_ALGO;
                started_w = 1;
                if (started_r == 0) begin
                    klotski_w = i_klotski;
                    start_alg_w = 1;
                end
                if (started_r == 1 & i_klotski[i_end_block[0]][i_end_block[1]] != i_end_block_number) begin
                    state_w = S_MOTOR;
                    o_bm_en = 1;
                    algo_continue_w = 0;
                end else begin
                    algo_continue_w = 1;
                end
            end
        end
        S_ALGO: begin
            if (i_move_en) begin
                state_w = S_MOTOR;
                o_bm_en = 1;
            end
            if (i_alg_done) begin
                state_w = S_DONE;
            end
        end
        S_MOTOR: begin
            if (i_bm_done) begin
                state_w = S_VGA;
                o_read_vga_start = 1;
            end
        end
        S_DONE: begin
            state_w = S_IDLE;
            done_w = 1;
        end
    endcase
end

always_ff @(posedge i_Clk or negedge i_rst_n) begin
    if (~i_rst_n) begin
        done_r <= 0;
        start_alg_r <= 0;
        state_r <= S_IDLE;
        klotski_r <= 0;
        started_r <= 0;
        algo_continue_r <= 0;
    end
    else begin
        done_r <= done_w;
        start_alg_r <= start_alg_w;
        state_r <= state_w;
        klotski_r <= klotski_w;
        started_r <= started_w;
        algo_continue_r <= algo_continue_w;
    end
end
endmodule
