module Solver (
    input i_clk,
    input i_rst_n,
    input i_start,
    input i_continue,
    input [3:0][3:0][3:0] i_klotski,

    output logic [3:0] o_start_block,
    output logic [3:0] o_end_block,
    output logic o_en,
    output logic [3:0] o_number,
    output o_finished
);

    typedef enum logic [5:0] { 
        S_IDLE,
        S1_1,
        S1_2,
        S1_3,
        S1_4,
        S1_5,
        S1_6,
        S1_7,
        S2_1,
        S2_2,
        S2_3,
        S2_4,
        S2_5,
        S2_6,
        S2_7,
        S3_1,
        S3_2,
        S3_3,
        S3_4,
        S3_5,
        S4_1,
        S4_2,
        S4_3,
        S4_4,
        S4_5,
        S5,
        S_FINISH
    } state_t;

    integer i, j;

    logic [0:3][0:3][3:0] klotski_r, klotski_w;
    logic [0:3][0:3] mask_r, mask_w;
    logic [0:1][1:0] target_r, target_w;
    logic [3:0] number_r, number_w;
    logic flag_r, flag_w; // unmask the one just moved and masked
    logic start_r, start_w;
    state_t state_r, state_w;
    logic o_finished_r, o_finished_w;
    logic [0:3][0:3][3:0] o_moveNum_klotski;
    logic [0:3][0:3] o_moveNum_mask;
    logic o_moveNum_finished;

    assign o_finished = o_finished_r;

    MoveNum moveNum (
        .i_clk(i_clk),
        .i_rst_n(i_rst_n),
        .i_start(start_r),
        .i_continue(i_continue),
        .i_klotski(klotski_r),
        .i_mask(mask_r),
        .i_number(number_r),
        .i_target(target_r),
        .i_flag(flag_r),
        
        .o_start_block(o_start_block),
        .o_end_block(o_end_block),
        .o_en(o_en),
        .o_number(o_number),
        .o_klotski(o_moveNum_klotski),
        .o_mask(o_moveNum_mask),
        .o_finished(o_moveNum_finished)
    );

    always_comb begin
        klotski_w = klotski_r;
        mask_w = mask_r;
        state_w = state_r;
        o_finished_w = 0;
        number_w = number_r;
        start_w = 0;
        flag_w = 0;
        target_w = target_r;
        case (state_r)
            S_IDLE: begin
                if (i_start) begin
                    state_w = S1_1;
                    klotski_w = i_klotski;
                    mask_w = 0;
                end
            end
            S1_1: begin
                state_w = S1_2;
                start_w = 1;
                number_w = 1;
                target_w = 0;
            end
            S1_2: begin
                if (o_moveNum_finished) begin
                    klotski_w = o_moveNum_klotski;
                    mask_w = o_moveNum_mask;
                    state_w = S1_3;
                    start_w = 1;
                    number_w = 2;
                    target_w = 1;
                end
            end
            S1_3: begin
                if (o_moveNum_finished) begin
                    klotski_w = o_moveNum_klotski;
                    mask_w = o_moveNum_mask;
                    state_w = S1_4;
                    start_w = 1;
                    number_w = 4;
                    target_w = 15;
                    if (o_moveNum_klotski[0][2] == 4'd3 & o_moveNum_klotski[0][3] == 4'd4) begin
                        mask_w[0][2] = 1;
                        mask_w[0][3] = 1;
                        state_w = S2_2;
                        start_w = 1;
                        number_w = 5;
                        target_w = 4;
                    end
                end
            end
            S1_4: begin
                if (o_moveNum_finished) begin
                    klotski_w = o_moveNum_klotski;
                    mask_w = o_moveNum_mask;
                    state_w = S1_5;
                    start_w = 1;
                    number_w = 3;
                    target_w = 3;
                end
            end
            S1_5: begin
                if (o_moveNum_finished) begin
                    klotski_w = o_moveNum_klotski;
                    mask_w = o_moveNum_mask;
                    state_w = S1_6;
                    start_w = 1;
                    number_w = 4;
                    target_w = 7;
                end
            end
            S1_6: begin
                if (o_moveNum_finished) begin
                    klotski_w = o_moveNum_klotski;
                    mask_w = o_moveNum_mask;
                    state_w = S1_7;
                    start_w = 1;
                    number_w = 3;
                    target_w = 2;
                end
            end
            S1_7: begin
                if (o_moveNum_finished) begin
                    klotski_w = o_moveNum_klotski;
                    mask_w = o_moveNum_mask;
                    state_w = S2_1;
                    start_w = 1;
                    number_w = 4;
                    target_w = 3;
                end
            end
            S2_1: begin
                if (o_moveNum_finished) begin
                    klotski_w = o_moveNum_klotski;
                    mask_w = o_moveNum_mask;
                    state_w = S2_2;
                    start_w = 1;
                    number_w = 5;
                    target_w = 4;
                end
            end
            S2_2: begin
                if (o_moveNum_finished) begin
                    klotski_w = o_moveNum_klotski;
                    mask_w = o_moveNum_mask;
                    state_w = S2_3;
                    start_w = 1;
                    number_w = 6;
                    target_w = 5;
                end
            end
            S2_3: begin
                if (o_moveNum_finished) begin
                    klotski_w = o_moveNum_klotski;
                    mask_w = o_moveNum_mask;
                    state_w = S2_4;
                    start_w = 1;
                    number_w = 8;
                    target_w = 15;
                    flag_w = 1;
                    if (o_moveNum_klotski[1][2] == 7 & o_moveNum_klotski[1][3] == 8) begin
                        mask_w[1][2] = 1;
                        mask_w[1][3] = 1;
                        state_w = S3_2;
                        start_w = 1;
                        number_w = 13;
                        target_w = 15;
                        if (o_moveNum_klotski[2][0] == 9 & o_moveNum_klotski[3][0] == 13) begin
                            mask_w[2][0] = 1;
                            mask_w[3][0] = 1;
                            state_w = S4_2;
                            start_w = 1;
                            number_w = 14;
                            target_w = 15;
                            if (o_moveNum_klotski[2][1] == 10 & o_moveNum_klotski[3][1] == 14) begin
                                mask_w[2][1] = 1;
                                mask_w[3][1] = 1;
                                state_w = S_FINISH;
                                start_w = 1;
                                number_w = 11;
                                target_w = 10;
                            end
                        end
                    end
                end
            end
            S2_4: begin
                if (o_moveNum_finished) begin
                    klotski_w = o_moveNum_klotski;
                    mask_w = o_moveNum_mask;
                    state_w = S2_5;
                    start_w = 1;
                    number_w = 7;
                    target_w = 7;
                end
            end
            S2_5: begin
                if (o_moveNum_finished) begin
                    klotski_w = o_moveNum_klotski;
                    mask_w = o_moveNum_mask;
                    state_w = S2_6;
                    start_w = 1;
                    number_w = 8;
                    target_w = 11;
                end
            end
            S2_6: begin
                if (o_moveNum_finished) begin
                    klotski_w = o_moveNum_klotski;
                    mask_w = o_moveNum_mask;
                    state_w = S2_7;
                    start_w = 1;
                    number_w = 7;
                    target_w = 6;
                end
            end
            S2_7: begin
                if (o_moveNum_finished) begin
                    klotski_w = o_moveNum_klotski;
                    mask_w = o_moveNum_mask;
                    state_w = S3_1;
                    start_w = 1;
                    number_w = 8;
                    target_w = 7;
                end
            end
            S3_1: begin
                if (o_moveNum_finished) begin
                    klotski_w = o_moveNum_klotski;
                    mask_w = o_moveNum_mask;
                    state_w = S3_2;
                    start_w = 1;
                    number_w = 13;
                    target_w = 15;
                    flag_w = 1;
                    if (o_moveNum_klotski[2][0] == 9 & o_moveNum_klotski[3][0] == 13) begin
                        mask_w[2][0] = 1;
                        mask_w[3][0] = 1;
                        state_w = S4_2;
                        start_w = 1;
                        number_w = 14;
                        target_w = 15;
                        flag_w = 1;
                        if (o_moveNum_klotski[2][1] == 10 & o_moveNum_klotski[3][1] == 14) begin
                            mask_w[2][1] = 1;
                            mask_w[3][1] = 1;
                            state_w = S_FINISH;
                            start_w = 1;
                            number_w = 11;
                            target_w = 10;
                        end
                    end
                end
            end
            S3_2: begin
                if (o_moveNum_finished) begin
                    klotski_w = o_moveNum_klotski;
                    mask_w = o_moveNum_mask;
                    state_w = S3_3;
                    start_w = 1;
                    number_w = 9;
                    target_w = 12;
                end
            end
            S3_3: begin
                if (o_moveNum_finished) begin
                    klotski_w = o_moveNum_klotski;
                    mask_w = o_moveNum_mask;
                    state_w = S3_4;
                    start_w = 1;
                    number_w = 13;
                    target_w = 13;
                end
            end
            S3_4: begin
                if (o_moveNum_finished) begin
                    klotski_w = o_moveNum_klotski;
                    mask_w = o_moveNum_mask;
                    state_w = S3_5;
                    start_w = 1;
                    number_w = 9;
                    target_w = 8;
                end
            end
            S3_5: begin
                if (o_moveNum_finished) begin
                    klotski_w = o_moveNum_klotski;
                    mask_w = o_moveNum_mask;
                    state_w = S4_1;
                    start_w = 1;
                    number_w = 13;
                    target_w = 12;
                end
            end
            S4_1: begin
                if (o_moveNum_finished) begin
                    klotski_w = o_moveNum_klotski;
                    mask_w = o_moveNum_mask;
                    state_w = S4_2;
                    start_w = 1;
                    number_w = 14;
                    target_w = 15;
                    flag_w = 1;
                    if (o_moveNum_klotski[2][1] == 10 & o_moveNum_klotski[3][1] == 14) begin
                        mask_w[2][1] = 1;
                        mask_w[3][1] = 1;
                        state_w = S_FINISH;
                        start_w = 1;
                        number_w = 11;
                        target_w = 10;
                    end
                end
            end
            S4_2: begin
                if (o_moveNum_finished) begin
                    klotski_w = o_moveNum_klotski;
                    mask_w = o_moveNum_mask;
                    state_w = S4_3;
                    start_w = 1;
                    number_w = 10;
                    target_w = 13;
                end
            end
            S4_3: begin
                if (o_moveNum_finished) begin
                    klotski_w = o_moveNum_klotski;
                    mask_w = o_moveNum_mask;
                    state_w = S4_4;
                    start_w = 1;
                    number_w = 14;
                    target_w = 14;
                end
            end
            S4_4: begin
                if (o_moveNum_finished) begin
                    klotski_w = o_moveNum_klotski;
                    mask_w = o_moveNum_mask;
                    state_w = S4_5;
                    start_w = 1;
                    number_w = 10;
                    target_w = 9;
                end
            end
            S4_5: begin
                if (o_moveNum_finished) begin
                    klotski_w = o_moveNum_klotski;
                    mask_w = o_moveNum_mask;
                    state_w = S5;
                    start_w = 1;
                    number_w = 14;
                    target_w = 13;
                end
            end
            S5: begin
                if (o_moveNum_finished) begin
                    klotski_w = o_moveNum_klotski;
                    mask_w = o_moveNum_mask;
                    state_w = S_FINISH;
                    start_w = 1;
                    number_w = 11;
                    target_w = 10;
                end
            end
            // S6: begin
            //     if (o_moveNum_finished) begin
            //         klotski_w = o_moveNum_klotski;
            //         mask_w = o_moveNum_mask;
            //         state_w = S7;
            //         start_w = 1;
            //         number_w = 12;
            //         target_w = 11;
            //     end
            // end
            // S7: begin
            //     if (o_moveNum_finished) begin
            //         klotski_w = o_moveNum_klotski;
            //         mask_w = o_moveNum_mask;
            //         state_w = S_FINISH;
            //         start_w = 1;
            //         number_w = 15;
            //         target_w = 14;
            //     end
            // end
            S_FINISH: begin
                if (o_moveNum_finished) begin
                    klotski_w = o_moveNum_klotski;
                    mask_w = o_moveNum_mask;
                    o_finished_w = 1;
                    state_w = S_IDLE;
                end
            end
        endcase
    end

    always_ff @(posedge i_clk or negedge i_rst_n) begin
        if (!i_rst_n) begin
            state_r <= S_IDLE;
            klotski_r <= 0;
            mask_r <= 0;
            target_r <= 0;
            o_finished_r <= 0;
            start_r <= 0;
            flag_r <= 0;
            number_r <= 0;
        end else begin
            state_r <= state_w;
            klotski_r <= klotski_w;
            mask_r <= mask_w;
            target_r <= target_w;
            o_finished_r <= o_finished_w;
            start_r <= start_w;
            flag_r <= flag_w;
            number_r <= number_w;
        end
    end

    

endmodule