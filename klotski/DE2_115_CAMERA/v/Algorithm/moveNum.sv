module MoveNum (
    input i_clk,
    input i_rst_n,
    input i_start,
    input i_continue,
    input [3:0][3:0][3:0] i_klotski,
    input [3:0][3:0] i_mask,
    input [1:0][1:0] i_target,
    input [3:0] i_number,
    input i_flag,
    
    output logic [3:0] o_start_block,
    output logic [3:0] o_end_block,
    output logic o_en,
    output logic [3:0] o_number,
    output [3:0][3:0][3:0] o_klotski,
    output [3:0][3:0] o_mask,
    output o_finished
);

    typedef enum logic [2:0] { 
        S_IDLE,
        S_FIND,
        S_ZERO_1,
        S_ZERO_2,
        S_WAIT
    } state_t;

    integer i, j;

    logic moveZero_flag_r, moveZero_flag_w;
    logic flag_r, flag_w;
    logic [0:3][0:3][3:0] klotski_r, klotski_w;
    logic [0:3][0:3] mask_r, mask_w;
    logic [0:1][1:0] target_r, target_w;
    logic [0:1][1:0] moveZero_target_r, moveZero_target_w;
    logic [3:0] number_r, number_w;
    logic start_r, start_w;
    state_t state_r, state_w;
    logic o_finished_r, o_finished_w;
    logic [0:1][1:0] num_pos_r, num_pos_w;
    logic [3:0][3:0][3:0] o_moveZero_klotski;
    logic o_moveZero_finished;

    function [0:1][1:0] findNumber;
        input [3:0] number;
        logic [1:0] tmp_i, tmp_j;
        begin
            for (i = 0; i < 4; i = i + 1) begin
                for (j = 0; j < 4; j = j + 1) begin
                    tmp_i = i;
                    tmp_j = j;
                    if (klotski_r[tmp_i][tmp_j] == number) begin
                        findNumber = {tmp_i, tmp_j};
                    end
                end
            end
        end
    endfunction

    MoveZero moveZero (
        .i_clk(i_clk),
        .i_rst_n(i_rst_n),
        .i_start(start_r),
        .i_continue(i_continue),
        .i_klotski(klotski_r),
        .i_mask(mask_r),
        .i_target(moveZero_target_r),
        .i_flag(moveZero_flag_r),
        .i_num_pos(num_pos_r),
        
        .o_start_block(o_start_block),
        .o_end_block(o_end_block),
        .o_en(o_en),
        .o_number(o_number),
        .o_klotski(o_moveZero_klotski),
        .o_finished(o_moveZero_finished)
    );

    assign o_klotski = klotski_r;
    assign o_mask = mask_r;
    assign o_finished = o_finished_r;

    always_comb begin
        klotski_w = klotski_r;
        mask_w = mask_r;
        moveZero_flag_w = 0;
        flag_w = flag_r;
        state_w = state_r;
        o_finished_w = 0;
        num_pos_w = num_pos_r;
        start_w = 0;
        moveZero_target_w = 0;
        target_w = target_r;
        number_w = number_r;
        case (state_r)
            S_IDLE: begin
                if (i_start) begin
                    state_w = S_FIND;
                    klotski_w = i_klotski;
                    mask_w = i_mask;
                    number_w = i_number;
                    target_w = i_target;
                    flag_w = ~i_flag;
                end
            end
            S_FIND: begin
                state_w = S_ZERO_1;
                num_pos_w = findNumber(number_r);
                if (target_r == num_pos_w) begin
                    if (number_r == 11) begin
                        state_w = S_WAIT;
                        number_w = 0;
                        start_w = 1;
                        moveZero_target_w = 15;
                        target_w = 15;
                    end else begin
                        o_finished_w = 1;
                        state_w = S_IDLE;
                        if (flag_r) begin
                            mask_w[num_pos_w[0]][num_pos_w[1]] = 1'b1;
                        end
                    end
                end
                // for (i = 0; i < 4; i += 1) begin
                //     $display("%0h", klotski_r[i]);
                // end
                // $display();
            end
            S_ZERO_1: begin
                state_w = S_ZERO_2;
                start_w = 1;
                moveZero_flag_w = 1;
                mask_w[num_pos_r[0]][num_pos_r[1]] = 1'b1;
                moveZero_target_w = target_r;
            end
            S_ZERO_2: begin
                if (o_moveZero_finished) begin
                    state_w = S_WAIT;
                    klotski_w = o_moveZero_klotski;
                    start_w = 1;
                    mask_w[num_pos_r[0]][num_pos_r[1]] = 1'b0;
                    moveZero_target_w = num_pos_r;
                end
            end
            S_WAIT: begin
                if (o_moveZero_finished) begin
                    state_w = S_FIND;
                    klotski_w = o_moveZero_klotski;
                end
            end
        endcase
    end

    always_ff @(posedge i_clk or negedge i_rst_n) begin
        if (!i_rst_n) begin
            state_r <= S_IDLE;
            moveZero_flag_r <= 0;
            flag_r <= 0;
            klotski_r <= 0;
            mask_r <= 0;
            target_r <= 0;
            o_finished_r <= 0;
            num_pos_r <= 0;
            start_r <= 0;
            moveZero_target_r <= 0;
            number_r <= 0;
        end else begin
            state_r <= state_w;
            moveZero_flag_r <= moveZero_flag_w;
            flag_r <= flag_w;
            klotski_r <= klotski_w;
            mask_r <= mask_w;
            target_r <= target_w;
            o_finished_r <= o_finished_w;
            num_pos_r <= num_pos_w;
            start_r <= start_w;
            moveZero_target_r <= moveZero_target_w;
            number_r <= number_w;
        end
    end

endmodule