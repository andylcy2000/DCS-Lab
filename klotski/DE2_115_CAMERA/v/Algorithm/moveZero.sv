module MoveZero (
    input i_clk,
    input i_rst_n,
    input i_start,
    input i_continue,
    input [3:0][3:0][3:0] i_klotski,
    input [3:0][3:0] i_mask,
    input [1:0][1:0] i_target,
    input i_flag,
    input [3:0] i_num_pos,
    
    output [3:0] o_start_block,
    output [3:0] o_end_block,
    output o_en,
    output [3:0][3:0][3:0] o_klotski,
    output logic [3:0] o_number,
    output o_finished
);

    typedef enum logic [2:0] {
        S_IDLE,
        S_CHECK_FINISH,
        S_DIR,
        S_WAIT_MOTOR,
        S_MOVE,
        S_FINISH
    } state_t;

    typedef enum logic [1:0] {
        UP,
        DOWN,
        LEFT,
        RIGHT
    } dir_t;

    integer i, j;

    logic flag_r, flag_w;
    logic [0:3][0:3][3:0] klotski_r, klotski_w;
    logic [0:3][0:3] mask_r, mask_w;
    logic [0:1][1:0] target_r, target_w;
    logic [0:1][1:0] num_pos_r, num_pos_w;
    logic [0:1][1:0] start_block;
    state_t state_r, state_w;
    logic o_finished_r, o_finished_w;
    logic [0:1][1:0] zero_pos_r, zero_pos_w;
    logic [0:1][1:0] last_pos_r, last_pos_w;
    logic check_last_pos_r, check_last_pos_w;
    logic o_en_r, o_en_w;
    dir_t dir_r, dir_w;
    logic check_up;
    logic check_down;
    logic check_left;
    logic check_right;
    logic garbage;

    function checkMove;
        input dir_t dir;
        logic [0:1][1:0] new_pos;
        begin
            checkMove = 1;
            case (dir)
                UP: begin
                    new_pos = zero_pos_r - 4'b100;
                    if (zero_pos_r[0] == 2'd0) checkMove = 0;
                end
                DOWN: begin
                    new_pos = zero_pos_r + 4'b100;
                    if (zero_pos_r[0] == 2'd3) checkMove = 0;
                end
                LEFT: begin
                    new_pos = zero_pos_r - 4'b1;
                    if (zero_pos_r[1] == 2'd0) checkMove = 0;
                end
                RIGHT: begin
                    new_pos = zero_pos_r + 4'b1;
                    if (zero_pos_r[1] == 2'd3) checkMove = 0;
                end
            endcase
            if (mask_r[new_pos[0]][new_pos[1]]) checkMove = 0;
            if (check_last_pos_r) begin
                if (new_pos == last_pos_r) checkMove = 0;
            end
        end
    endfunction

    function [0:1][1:0] nextBlock;
        begin
            case (dir_r)
                UP: nextBlock = zero_pos_r - 4'b100;
                DOWN: nextBlock = zero_pos_r + 4'b100;
                LEFT: nextBlock = zero_pos_r - 4'b1;
                RIGHT: nextBlock = zero_pos_r + 4'b1;
            endcase
        end
    endfunction

    function move;
        logic [0:1][1:0] new_pos;
        begin
            case (dir_r)
                UP: new_pos = zero_pos_r - 4'b100;
                DOWN: new_pos = zero_pos_r + 4'b100;
                LEFT: new_pos = zero_pos_r - 4'b1;
                RIGHT: new_pos = zero_pos_r + 4'b1;
            endcase
            klotski_w[zero_pos_r[0]][zero_pos_r[1]] = klotski_r[new_pos[0]][new_pos[1]];
            klotski_w[new_pos[0]][new_pos[1]] = 2'd0;
            last_pos_w = zero_pos_r;
            zero_pos_w = new_pos;
            check_last_pos_w = 0;
            if (zero_pos_r[0] == num_pos_r[0] | zero_pos_r[1] == num_pos_r[1]) begin
                check_last_pos_w = 1;
            end
            move = 0;
        end
    endfunction

    function [0:1][1:0] findNumber;
        input [3:0] number;
        logic [1:0] tmp_i, tmp_j;
        begin
            for (i = 0; i < 4; i = i + 1) begin
                for (j = 0; j < 4; j = j + 1) begin
                    tmp_i = i;
                    tmp_j = j;
                    if (klotski_w[tmp_i][tmp_j] == number) begin
                        findNumber = {tmp_i, tmp_j};
                    end
                end
            end
        end
    endfunction

    assign o_klotski = klotski_r;
    assign o_finished = o_finished_r;
    assign o_start_block = start_block;
    assign o_end_block = zero_pos_r;
    assign o_en = o_en_r;

    always_comb begin
        klotski_w = klotski_r;
        mask_w = mask_r;
        flag_w = flag_r;
        num_pos_w = num_pos_r;
        state_w = state_r;
        o_finished_w = 0;
        o_en_w = 0;
        dir_w = dir_r;
        check_up = checkMove(UP);
        check_down = checkMove(DOWN);
        check_left = checkMove(LEFT);
        check_right = checkMove(RIGHT);
        start_block = nextBlock();
        o_number = klotski_r[start_block[0]][start_block[1]];
        check_last_pos_w = check_last_pos_r;
        target_w = target_r;
        last_pos_w = last_pos_r;
        zero_pos_w = zero_pos_r;
        case (state_r)
            S_IDLE: begin
                if (i_start) begin
                    state_w = S_CHECK_FINISH;
                    klotski_w = i_klotski;
                    mask_w = i_mask;
                    zero_pos_w = findNumber(0);
                    target_w = i_target;
                    flag_w = i_flag;
                    num_pos_w = i_num_pos;
                end
            end
            S_CHECK_FINISH: begin
                state_w = S_DIR;
                if (flag_r) begin
                    if ((zero_pos_r[0] <= target_r[0] & zero_pos_r[0] > num_pos_r[0]) & ((zero_pos_r[1] <= target_r[1] & zero_pos_r[1] >= num_pos_r[1]) | (zero_pos_r[1] >= target_r[1] & zero_pos_r[1] <= num_pos_r[1]))) state_w = S_FINISH;
                    if ((zero_pos_r[1] <= target_r[1] & zero_pos_r[1] > num_pos_r[1]) & ((zero_pos_r[0] <= target_r[0] & zero_pos_r[0] >= num_pos_r[0]) | (zero_pos_r[0] >= target_r[0] & zero_pos_r[0] <= num_pos_r[0]))) state_w = S_FINISH;
                    if ((zero_pos_r[0] >= target_r[0] & zero_pos_r[0] < num_pos_r[0]) & ((zero_pos_r[1] >= target_r[1] & zero_pos_r[1] <= num_pos_r[1]) | (zero_pos_r[1] <= target_r[1] & zero_pos_r[1] >= num_pos_r[1]))) state_w = S_FINISH;
                    if ((zero_pos_r[1] >= target_r[1] & zero_pos_r[1] < num_pos_r[1]) & ((zero_pos_r[0] >= target_r[0] & zero_pos_r[0] <= num_pos_r[0]) | (zero_pos_r[0] <= target_r[0] & zero_pos_r[0] >= num_pos_r[0]))) state_w = S_FINISH;
                end
                if (zero_pos_r[0] == target_r[0] & zero_pos_r[1] == target_r[1]) state_w = S_FINISH;
                // for (i = 0; i < 4; i += 1) begin
                //     $display("%0h%0h%0h%0h %0b%0b%0b%0b", klotski_r[i][0], klotski_r[i][1], klotski_r[i][2], klotski_r[i][3], mask_r[i][0], mask_r[i][1], mask_r[i][2], mask_r[i][3]);
                // end
                // $display("%0b", check_last_pos_r);
                // $display();
            end
            S_DIR: begin
                state_w = S_WAIT_MOTOR;
                o_en_w = 1;
                case (1)
                    (zero_pos_r[0] < target_r[0]): begin
                        case (1)
                            (check_down): dir_w = DOWN;
                            (zero_pos_r[1] < target_r[1]): begin
                                case (1)
                                    (check_right): dir_w = RIGHT;
                                    (check_left): dir_w = LEFT;
                                    default: dir_w = UP;
                                endcase
                            end
                            (zero_pos_r[1] > target_r[1]): begin
                                case (1)
                                    (check_left): dir_w = LEFT;
                                    (check_up): dir_w = UP;
                                    default: dir_w = RIGHT;
                                endcase
                            end
                            default: begin
                                case (1)
                                    (check_left): dir_w = LEFT;
                                    (check_right): dir_w = RIGHT;
                                    default: dir_w = UP;
                                endcase
                            end
                        endcase
                    end
                    (zero_pos_r[0] > target_r[0]): begin
                        case (1)
                            (check_up): dir_w = UP;
                            (zero_pos_r[1] < target_r[1]): begin
                                case (1)
                                    (check_right): dir_w = RIGHT;
                                    (check_down): dir_w = DOWN;
                                    default: dir_w = LEFT;
                                endcase
                            end
                            (zero_pos_r[1] > target_r[1]): begin
                                case (1)
                                    (check_left): dir_w = LEFT;
                                    (check_right): dir_w = RIGHT;
                                    default: dir_w = DOWN;
                                endcase
                            end
                            default: begin
                                case (1)
                                    (check_right): dir_w = RIGHT;
                                    (check_left): dir_w = LEFT;
                                    default: dir_w = DOWN;
                                endcase
                            end
                        endcase
                    end
                    default: begin
                        case (1)
                            (zero_pos_r[1] < target_r[1]): begin
                                case (1)
                                    (check_right): dir_w = RIGHT;
                                    (check_up): dir_w = UP;
                                    (check_down): dir_w = DOWN;
                                    default: dir_w = LEFT;
                                endcase
                            end
                            default: begin
                                case (1)
                                    (check_left): dir_w = LEFT;
                                    (check_up): dir_w = UP;
                                    (check_down): dir_w = DOWN;
                                    default: dir_w = RIGHT;
                                endcase
                            end
                        endcase
                    end
                endcase
            end
            S_WAIT_MOTOR: begin
                if (i_continue) begin
                    state_w = S_MOVE;
                end
            end
            S_MOVE: begin
                state_w = S_CHECK_FINISH;
                garbage = move();
            end
            S_FINISH: begin
                o_finished_w = 1;
                state_w = S_IDLE;
            end
        endcase
    end

    always_ff @(posedge i_clk or negedge i_rst_n) begin
        if (!i_rst_n) begin
            state_r <= S_IDLE;
            flag_r <= 0;
            klotski_r <= 0;
            mask_r <= 0;
            target_r <= 0;
            o_finished_r <= 0;
            zero_pos_r <= 0;
            last_pos_r <= 0;
            check_last_pos_r <= 0;
            dir_r <= UP;
            num_pos_r <= 0;
            o_en_r <= 0;
        end else begin
            state_r <= state_w;
            flag_r <= flag_w;
            klotski_r <= klotski_w;
            mask_r <= mask_w;
            target_r <= target_w;
            o_finished_r <= o_finished_w;
            zero_pos_r <= zero_pos_w;
            last_pos_r <= last_pos_w;
            check_last_pos_r <= check_last_pos_w;
            dir_r <= dir_w;
            num_pos_r <= num_pos_w;
            o_en_r <= o_en_w; 
        end
    end

endmodule