module Block_Movement2Motor(
    input i_Clk,
    input i_rst_n,
    input [4:0] i_Start_Block,
    input [4:0] i_End_Block,
    input i_en,
    output o_step_control_x,
    output o_direction_x,
    output o_step_control_y,
    output o_direction_y,
    output o_magnet,
    output o_done
);

//parameters
localparam X_OFFSET = 1600;
localparam Y_OFFSET = 1728;

localparam X_ORIGINAL_STEPS_PER_BLOCK = 672;
localparam Y_ORIGINAL_STEPS_PER_BLOCK = 678;

localparam X_EXCESS_STEPS = 150;
localparam Y_EXCESS_STEPS = 150;

localparam CALIBRATE_X_EXCESS = 80;
localparam CALIBRATE_Y_EXCESS = 80;

/*
localparam BLOCK0_XPOS = X_OFFSET;
localparam BLOCK1_XPOS = X_OFFSET + X_ORIGINAL_STEPS_PER_BLOCK;
localparam BLOCK2_XPOS = X_OFFSET + (X_ORIGINAL_STEPS_PER_BLOCK << 1);
localparam BLOCK3_XPOS = X_OFFSET + X_ORIGINAL_STEPS_PER_BLOCK + (X_ORIGINAL_STEPS_PER_BLOCK << 1);
localparam BLOCK4_XPOS = BLOCK0_XPOS;
localparam BLOCK5_XPOS = BLOCK1_XPOS;
localparam BLOCK6_XPOS = BLOCK2_XPOS;
localparam BLOCK7_XPOS = BLOCK3_XPOS;
localparam BLOCK8_XPOS = BLOCK0_XPOS;
localparam BLOCK9_XPOS = BLOCK1_XPOS;
localparam BLOCK10_XPOS = BLOCK2_XPOS;
localparam BLOCK11_XPOS = BLOCK3_XPOS;
localparam BLOCK12_XPOS = BLOCK0_XPOS;
localparam BLOCK13_XPOS = BLOCK1_XPOS;
localparam BLOCK14_XPOS = BLOCK2_XPOS;
localparam BLOCK15_XPOS = BLOCK3_XPOS;
*/

localparam BLOCK0_XPOS = X_OFFSET;
localparam BLOCK1_XPOS = BLOCK0_XPOS;
localparam BLOCK2_XPOS = BLOCK0_XPOS;
localparam BLOCK3_XPOS = BLOCK0_XPOS;
localparam BLOCK4_XPOS = X_OFFSET + X_ORIGINAL_STEPS_PER_BLOCK;
localparam BLOCK5_XPOS = BLOCK4_XPOS;
localparam BLOCK6_XPOS = BLOCK4_XPOS;
localparam BLOCK7_XPOS = BLOCK4_XPOS;
localparam BLOCK8_XPOS = X_OFFSET + (X_ORIGINAL_STEPS_PER_BLOCK << 1);
localparam BLOCK9_XPOS = BLOCK8_XPOS;
localparam BLOCK10_XPOS = BLOCK8_XPOS;
localparam BLOCK11_XPOS = BLOCK8_XPOS;
localparam BLOCK12_XPOS = X_OFFSET + X_ORIGINAL_STEPS_PER_BLOCK + (X_ORIGINAL_STEPS_PER_BLOCK << 1);
localparam BLOCK13_XPOS = BLOCK12_XPOS;
localparam BLOCK14_XPOS = BLOCK12_XPOS;
localparam BLOCK15_XPOS = BLOCK12_XPOS;

localparam BLOCK0_YPOS = Y_OFFSET;
localparam BLOCK1_YPOS = Y_OFFSET + Y_ORIGINAL_STEPS_PER_BLOCK;
localparam BLOCK2_YPOS = Y_OFFSET + (Y_ORIGINAL_STEPS_PER_BLOCK << 1);
localparam BLOCK3_YPOS = Y_OFFSET + Y_ORIGINAL_STEPS_PER_BLOCK + (Y_ORIGINAL_STEPS_PER_BLOCK << 1);
localparam BLOCK4_YPOS = BLOCK0_YPOS;
localparam BLOCK5_YPOS = BLOCK1_YPOS;
localparam BLOCK6_YPOS = BLOCK2_YPOS;
localparam BLOCK7_YPOS = BLOCK3_YPOS;
localparam BLOCK8_YPOS = BLOCK0_YPOS;
localparam BLOCK9_YPOS = BLOCK1_YPOS;
localparam BLOCK10_YPOS = BLOCK2_YPOS;
localparam BLOCK11_YPOS = BLOCK3_YPOS;
localparam BLOCK12_YPOS = BLOCK0_YPOS;
localparam BLOCK13_YPOS = BLOCK1_YPOS;
localparam BLOCK14_YPOS = BLOCK2_YPOS;
localparam BLOCK15_YPOS = BLOCK3_YPOS;

localparam CALIBRATE_THESHOLD = 4;
localparam CALIBRATE_HALT = 40000000;
localparam MOVE_HALT = 40000000;
//

//int
const int block_xpos[16] = '{BLOCK0_XPOS, BLOCK1_XPOS, BLOCK2_XPOS, BLOCK3_XPOS, 
BLOCK4_XPOS, BLOCK5_XPOS, BLOCK6_XPOS, BLOCK7_XPOS, BLOCK8_XPOS, BLOCK9_XPOS,
BLOCK10_XPOS, BLOCK11_XPOS, BLOCK12_XPOS, BLOCK13_XPOS, BLOCK14_XPOS, BLOCK15_XPOS};

const int block_ypos[16] = '{BLOCK0_YPOS, BLOCK1_YPOS, BLOCK2_YPOS, BLOCK3_YPOS, 
BLOCK4_YPOS, BLOCK5_YPOS, BLOCK6_YPOS, BLOCK7_YPOS, BLOCK8_YPOS, BLOCK9_YPOS,
BLOCK10_YPOS, BLOCK11_YPOS, BLOCK12_YPOS, BLOCK13_YPOS, BLOCK14_YPOS, BLOCK15_YPOS};

//

//logic
logic finish_move_to_start_r, finish_move_to_start_w;
logic finish_move_to_start_x_r, finish_move_to_start_x_w;
logic finish_move_to_start_y_r, finish_move_to_start_y_w;
logic finish_move_block_r, finish_move_block_w;
logic finish_move_block_x_r, finish_move_block_x_w;
logic finish_move_block_y_r, finish_move_block_y_w;
logic finish_return_to_end_block_r, finish_return_to_end_block_w;
logic finish_return_to_end_block_x_r, finish_return_to_end_block_x_w;
logic finish_return_to_end_block_y_r, finish_return_to_end_block_y_w;
logic finish_calibrate_r, finish_calibrate_w;
logic finish_calibrate_x_r, finish_calibrate_x_w;
logic finish_calibrate_y_r, finish_calibrate_y_w;

logic [1:0] move_to_start_x_cnt_r, move_to_start_x_cnt_w;
logic [1:0] move_to_start_y_cnt_r, move_to_start_y_cnt_w;
logic [1:0] move_block_x_cnt_r, move_block_x_cnt_w;
logic [1:0] move_block_y_cnt_r, move_block_y_cnt_w;
logic [1:0] calibrate_move_x_cnt_r, calibrate_move_x_cnt_w;
logic [1:0] calibrate_move_y_cnt_r, calibrate_move_y_cnt_w;
logic [1:0] return_to_end_block_x_cnt_r, return_to_end_block_x_cnt_w;
logic [1:0] return_to_end_block_y_cnt_r, return_to_end_block_y_cnt_w;

logic last_xy_move_r, last_xy_move_w; //0：上一步為x，1：上一步為y
logic x_en_r, x_en_w;
logic y_en_r, y_en_w;

logic [4:0] start_block_r, start_block_w;
logic [4:0] end_block_r, end_block_w;
logic [4:0] calibrate_cnt_r, calibrate_cnt_w;

logic x_dir_r, x_dir_w;
logic y_dir_r, y_dir_w;
logic [31:0] to_motor_x_total_steps_r, to_motor_x_total_steps_w;
logic [31:0] to_motor_y_total_steps_r, to_motor_y_total_steps_w;

logic o_to_camera_x_step, o_to_camera_y_step;
logic o_to_camera_x_direction, o_to_camera_y_direction;

logic [31:0] start_block_x_pos, end_block_x_pos;
logic [31:0] start_block_y_pos, end_block_y_pos;

logic [31:0] current_x_pos_r, current_x_pos_w;
logic [31:0] current_y_pos_r, current_y_pos_w;

logic motor_x_done, motor_y_done;
logic magnet_r, magnet_w;
logic to_camera_done_r, to_camera_done_w;

logic [31:0] halt_calibrate_cnt_r, halt_calibrate_cnt_w;
logic [31:0] halt_move_cnt_r, halt_move_cnt_w;
//

//assignment
assign o_step_control_x = o_to_camera_x_step;
assign o_direction_x = o_to_camera_x_direction;
assign o_step_control_y = o_to_camera_y_step;
assign o_direction_y = o_to_camera_y_direction;

assign o_magnet = magnet_r;
assign o_done = to_camera_done_r;
//

//state enumeration
typedef enum logic [3:0] {
    S_IDLE     = 4'b0000,
    S_CALC_XY_MOVEMENT = 4'b0001,
    S_MOVE_TO_START_BLOCK = 4'b0010,
    S_MOVE_BLOCK = 4'b0011,
    S_RETURN_TO_END_BLOCK = 4'b0100,
    S_CALIBRATE = 4'b0101,
    S_HALT_CALIBRATE = 4'b0110,
    S_HALT_MOVE = 4'b0111,
    S_DONE = 4'b1000
} state_t;

state_t state_r, state_w;
//

//FSM
always_comb begin
    state_w = state_r;
    case(state_r)
        S_IDLE: begin
            if(i_en) begin
                state_w = S_MOVE_TO_START_BLOCK;
            end
            else begin
                state_w = S_IDLE;
            end
        end

        //no function
        S_CALC_XY_MOVEMENT: begin
            state_w = S_MOVE_TO_START_BLOCK;
        end
        //

        S_MOVE_TO_START_BLOCK: begin
            if (finish_move_to_start_r) begin
                state_w = S_MOVE_BLOCK;
            end
            else begin
                state_w = S_MOVE_TO_START_BLOCK;
            end
        end

        S_MOVE_BLOCK: begin
            if (finish_move_block_r)  begin
                state_w = S_HALT_MOVE;
            end
            else begin
                state_w = S_MOVE_BLOCK;
            end
        end

        S_RETURN_TO_END_BLOCK: begin
            if (finish_return_to_end_block_r) begin
                state_w = S_DONE;
            end
            else begin
                state_w = S_RETURN_TO_END_BLOCK;
            end
        end

        S_CALIBRATE: begin
            if (finish_calibrate_r) begin
                state_w = S_HALT_CALIBRATE;
            end
            else begin
                state_w = S_CALIBRATE;
            end
        end

        S_HALT_CALIBRATE: begin
            if (halt_calibrate_cnt_r >= CALIBRATE_HALT) begin
                state_w = S_DONE;
            end
            else begin
                state_w = S_HALT_CALIBRATE;
            end
        end

        S_HALT_MOVE: begin
            if ((halt_move_cnt_r >= MOVE_HALT) && (calibrate_cnt_r >= CALIBRATE_THESHOLD)) begin
                state_w = S_CALIBRATE;
            end
            else if ((halt_move_cnt_r >= MOVE_HALT) && (calibrate_cnt_r < CALIBRATE_THESHOLD))begin
                state_w = S_RETURN_TO_END_BLOCK;
            end
            else begin
                state_w = S_HALT_MOVE;
            end
        end

        S_DONE: begin
            state_w = S_IDLE;
        end

    endcase
end
//

//Combinational Part

//state_behavior
always_comb begin
    //logic set
    finish_move_to_start_w = 0;
    finish_move_to_start_x_w = 0;
    finish_move_to_start_y_w = 0;
    finish_move_block_w = 0;
    finish_move_block_x_w = 0;
    finish_move_block_y_w = 0;
    finish_return_to_end_block_w = 0;
    finish_return_to_end_block_x_w = 0;
    finish_return_to_end_block_y_w = 0;
    finish_calibrate_w = 0;
    finish_calibrate_x_w = 0;
    finish_calibrate_y_w = 0;
    move_to_start_x_cnt_w = move_to_start_x_cnt_r;
    move_to_start_y_cnt_w = move_to_start_y_cnt_r;
    move_block_x_cnt_w = move_block_x_cnt_r;
    move_block_y_cnt_w = move_block_y_cnt_r;
    calibrate_move_x_cnt_w = calibrate_move_x_cnt_r;
    calibrate_move_y_cnt_w = calibrate_move_y_cnt_r;
    return_to_end_block_x_cnt_w = return_to_end_block_x_cnt_r;
    return_to_end_block_y_cnt_w = return_to_end_block_y_cnt_r;
    last_xy_move_w = last_xy_move_r;
    x_en_w = 0;
    y_en_w = 0;
    start_block_w = start_block_r;
    end_block_w = end_block_r;
    calibrate_cnt_w = calibrate_cnt_r;
    x_dir_w = x_dir_r;
    y_dir_w = y_dir_r;
    to_motor_x_total_steps_w = to_motor_x_total_steps_r;
    to_motor_y_total_steps_w = to_motor_y_total_steps_r;
    current_x_pos_w = current_x_pos_r;
    current_y_pos_w = current_y_pos_r;
    magnet_w = 0;
    to_camera_done_w = 0;
    start_block_x_pos = 0;
    start_block_y_pos = 0;
    end_block_x_pos = 0;
    end_block_y_pos = 0;
    halt_calibrate_cnt_w = halt_calibrate_cnt_r;
    halt_move_cnt_w = halt_move_cnt_r;
    //
    case(state_r)
    S_IDLE: begin
        finish_move_to_start_w = 0;
        finish_move_to_start_x_w = 0;
        finish_move_to_start_y_w = 0;
        move_to_start_x_cnt_w = 0;
        move_to_start_y_cnt_w = 0;
        finish_move_block_w = finish_move_block_r;
        finish_move_block_x_w = finish_calibrate_x_r;
        finish_move_block_y_w = finish_calibrate_y_r;
        finish_return_to_end_block_w = 0;
        finish_return_to_end_block_x_w = 0;
        finish_return_to_end_block_y_w = 0;
        finish_calibrate_w = 0;
        finish_calibrate_x_w = 0;
        finish_calibrate_y_w = 0;
        move_to_start_x_cnt_w = 0;
        move_to_start_y_cnt_w = 0;
        move_block_x_cnt_w = 0;
        move_block_y_cnt_w = 0;
        calibrate_move_x_cnt_w = 0;
        calibrate_move_y_cnt_w = 0;
        return_to_end_block_x_cnt_w = 0;
        return_to_end_block_y_cnt_w = 0;
        halt_calibrate_cnt_w = 0;
        halt_move_cnt_w = 0;
    end

    S_CALC_XY_MOVEMENT: begin
        /*
        start_block_x_pos = block_xpos[start_block_r];
        start_block_y_pos = block_ypos[start_block_r];
        end_block_x_pos = block_xpos[end_block_r];
        end_block_y_pos = block_ypos[end_block_r];
        */
        
    end

    S_MOVE_TO_START_BLOCK: begin
        start_block_x_pos = block_xpos[start_block_r];
        start_block_y_pos = block_ypos[start_block_r];
        if (start_block_x_pos >= current_x_pos_r) begin
            x_dir_w = 1;
            to_motor_x_total_steps_w = start_block_x_pos - current_x_pos_r;
        end
        else begin
            x_dir_w = 0;
            to_motor_x_total_steps_w = current_x_pos_r - start_block_x_pos;
        end

        if (start_block_y_pos >= current_y_pos_r) begin
            y_dir_w = 1;
            to_motor_y_total_steps_w = start_block_y_pos - current_y_pos_r;
        end
        else begin
            y_dir_w = 0;
            to_motor_y_total_steps_w = current_y_pos_r - start_block_y_pos;
        end

        if ((last_xy_move_r) && (move_to_start_x_cnt_r <= 0)) begin
            x_en_w = 1;
            move_to_start_x_cnt_w = 1;
            
        end
        else if ((~last_xy_move_r) && (move_to_start_y_cnt_r <= 0)) begin
            y_en_w = 1;
            move_to_start_y_cnt_w = 1;
            
        end

        if (motor_x_done) begin
            current_x_pos_w = start_block_x_pos;
            if (move_to_start_y_cnt_r >= 1) begin
                finish_move_to_start_w = 1;
            end
            x_en_w = 0;
            last_xy_move_w = 0;
        end

        if (motor_y_done) begin
            current_y_pos_w = start_block_y_pos;
            if (move_to_start_x_cnt_r >= 1) begin
                finish_move_to_start_w = 1;
            end
            y_en_w = 0;
            last_xy_move_w = 1;
        end

    end

    S_MOVE_BLOCK: begin
        end_block_x_pos = block_xpos[end_block_r];
        end_block_y_pos = block_ypos[end_block_r];
        magnet_w = 1;
        if (end_block_x_pos > current_x_pos_r) begin
            x_dir_w = 1;
            if (move_block_x_cnt_r <= 0) begin
                x_en_w = 1;
            end
            move_block_x_cnt_w = 1;
            to_motor_x_total_steps_w = end_block_x_pos - current_x_pos_r + X_EXCESS_STEPS;
            last_xy_move_w = 0;
        end
        else if (end_block_x_pos < current_x_pos_r) begin
            x_dir_w = 0;
            if (move_block_x_cnt_r <= 0) begin
                x_en_w = 1;
            end
            move_block_x_cnt_w = 1;
            to_motor_x_total_steps_w = current_x_pos_r - end_block_x_pos + X_EXCESS_STEPS;
            last_xy_move_w = 0;
        end
        else begin
            x_dir_w = 0;
            x_en_w = 0;
            to_motor_x_total_steps_w = 0;
        end

        if (end_block_y_pos > current_y_pos_r) begin
            y_dir_w = 1;
            if (move_block_y_cnt_r <= 0) begin
                y_en_w = 1;
            end
            move_block_y_cnt_w = 1;
            to_motor_y_total_steps_w = end_block_y_pos - current_y_pos_r + Y_EXCESS_STEPS;
            last_xy_move_w = 1;
        end
        else if (end_block_y_pos < current_y_pos_r) begin
            y_dir_w = 0;
            if (move_block_y_cnt_r <= 0) begin
                y_en_w = 1;
            end
            move_block_y_cnt_w = 1;
            to_motor_y_total_steps_w = current_y_pos_r - end_block_y_pos + Y_EXCESS_STEPS;
            last_xy_move_w = 1;
        end
        else begin
            y_dir_w = 0;
            y_en_w = 0;
            to_motor_y_total_steps_w = 0;
        end

        if (motor_x_done || motor_y_done) begin
            if (end_block_x_pos > current_x_pos_r) begin
                current_x_pos_w = end_block_x_pos + X_EXCESS_STEPS;
            end
            else if (end_block_x_pos < current_x_pos_r) begin
                current_x_pos_w = end_block_x_pos - X_EXCESS_STEPS;
            end
            else begin
                current_x_pos_w = end_block_x_pos;
            end

            if (end_block_y_pos > current_y_pos_r) begin
                current_y_pos_w = end_block_y_pos + Y_EXCESS_STEPS;
            end
            else if (end_block_y_pos < current_y_pos_r) begin
                current_y_pos_w = end_block_y_pos - Y_EXCESS_STEPS;
            end
            else begin
                current_y_pos_w = end_block_y_pos;
            end
            
            finish_move_block_w = 1;
            x_en_w = 0;
            y_en_w = 0;
            calibrate_cnt_w = calibrate_cnt_r + 1;
        end
  
    end

    S_RETURN_TO_END_BLOCK: begin
        start_block_x_pos = block_xpos[start_block_r];
        start_block_y_pos = block_ypos[start_block_r];
        end_block_x_pos = block_xpos[end_block_r];
        end_block_y_pos = block_ypos[end_block_r];
        if(~last_xy_move_r) begin
            if ((~x_dir_r) && (return_to_end_block_x_cnt_r <= 0)) begin
                //x_dir_w = 1;
                if (start_block_x_pos >= end_block_x_pos) begin
                    x_dir_w = 1;
                end
                else begin
                    x_dir_w = 0;
                end
                return_to_end_block_x_cnt_w = 1;
                x_en_w = 1;
            end 
            else if ((x_dir_r) && (return_to_end_block_x_cnt_r <= 0))begin
                //x_dir_w = 0;
                if (start_block_x_pos >= end_block_x_pos) begin
                    x_dir_w = 1;
                end
                else begin
                    x_dir_w = 0;
                end
                return_to_end_block_x_cnt_w = 1;
                x_en_w = 1;
            end
            else begin
                x_dir_w = x_dir_r;
                x_en_w = 0;
            end
            to_motor_x_total_steps_w = X_EXCESS_STEPS;
            
            y_en_w = 0;
        end
        else if (last_xy_move_r) begin
            if ((~y_dir_r) && (return_to_end_block_y_cnt_r <= 0)) begin
                //y_dir_w = 1;
                if (start_block_y_pos >= end_block_y_pos) begin
                    y_dir_w = 1;
                end
                else begin
                    y_dir_w = 0;
                end
                return_to_end_block_y_cnt_w = 1;
                y_en_w = 1;
            end
            else if ((y_dir_r) && (return_to_end_block_y_cnt_r <= 0))begin
                //y_dir_w = 0;
                if (start_block_y_pos >= end_block_y_pos) begin
                    y_dir_w = 1;
                end
                else begin
                    y_dir_w = 0;
                end
                return_to_end_block_y_cnt_w = 1;
                y_en_w = 1;
            end
            else begin
                y_dir_w = y_dir_r;
                y_en_w = 0;
            end
            to_motor_y_total_steps_w = Y_EXCESS_STEPS;
            x_en_w = 0;
            
        end

        if (motor_x_done || motor_y_done) begin
            current_x_pos_w = end_block_x_pos;
            current_y_pos_w = end_block_y_pos;
            finish_return_to_end_block_w = 1;
            x_en_w = 0;
            y_en_w = 0;
        end
    end

    S_CALIBRATE: begin
        calibrate_cnt_w = 0;
        if ((last_xy_move_r) && (calibrate_move_x_cnt_r <= 0)) begin
            x_en_w = 1;
            calibrate_move_x_cnt_w = 1;
            to_motor_x_total_steps_w = current_x_pos_r + 2;
            x_dir_w = 0;
        end
        else if ((~last_xy_move_r) && (calibrate_move_y_cnt_r <= 0)) begin
            y_en_w = 1;
            calibrate_move_y_cnt_w = 1;
            to_motor_y_total_steps_w = current_y_pos_r + 2;
            y_dir_w = 0;
        end

        if (motor_x_done) begin
            current_x_pos_w = 0;
            if (calibrate_move_y_cnt_r >= 1) begin
                finish_calibrate_w = 1;
            end
            x_en_w = 0;
            last_xy_move_w = 0;
        end

        if (motor_y_done) begin
            current_y_pos_w = 0;
            if (calibrate_move_x_cnt_r >= 1) begin
                finish_calibrate_w = 1;
            end
            y_en_w = 0;
            last_xy_move_w = 1;
        end
    end

    S_HALT_CALIBRATE: begin
        halt_calibrate_cnt_w = halt_calibrate_cnt_r + 1;
    end

    S_HALT_MOVE: begin
        halt_move_cnt_w = halt_move_cnt_r + 1;
    end

    S_DONE: begin
        to_camera_done_w = 1;
    end

    default: begin
        finish_move_to_start_w = 0;
        finish_move_to_start_x_w = 0;
        finish_move_to_start_y_w = 0;
        finish_move_block_w = 0;
        finish_move_block_x_w = 0;
        finish_move_block_y_w = 0;
        finish_return_to_end_block_w = 0;
        finish_return_to_end_block_x_w = 0;
        finish_return_to_end_block_y_w = 0;
        finish_calibrate_w = 0;
        finish_calibrate_x_w = 0;
        finish_calibrate_y_w = 0;
        move_to_start_x_cnt_w = move_to_start_x_cnt_r;
        move_to_start_y_cnt_w = move_to_start_y_cnt_r;
        move_block_x_cnt_w = move_block_x_cnt_r;
        move_block_y_cnt_w = move_block_y_cnt_r;
        calibrate_move_x_cnt_w = calibrate_move_x_cnt_r;
        calibrate_move_y_cnt_w = calibrate_move_y_cnt_r;
        return_to_end_block_x_cnt_w = return_to_end_block_x_cnt_r;
        return_to_end_block_y_cnt_w = return_to_end_block_y_cnt_r;
        last_xy_move_w = last_xy_move_r;
        x_en_w = 0;
        y_en_w = 0;
        start_block_w = start_block_r;
        end_block_w = end_block_r;
        calibrate_cnt_w = calibrate_cnt_r;
        x_dir_w = x_dir_r;
        y_dir_w = y_dir_r;
        to_motor_x_total_steps_w = to_motor_x_total_steps_r;
        to_motor_y_total_steps_w = to_motor_y_total_steps_r;
        current_x_pos_w = current_x_pos_r;
        current_y_pos_w = current_y_pos_r;
        magnet_w = 0;
        to_camera_done_w = 0;
    end
    endcase
end
//

//

//Sequential Part

always_ff @( posedge i_Clk or negedge i_rst_n ) begin 
    if (~i_rst_n) begin
        state_r <= S_IDLE;
        start_block_r <= 0;
        end_block_r <= 0;
        finish_move_to_start_r <= 0;
        finish_move_to_start_x_r <= 0;
        finish_move_to_start_y_r <= 0;
        finish_move_block_r <= 0;
        finish_move_block_x_r <= 0;
        finish_move_block_y_r <= 0;
        finish_return_to_end_block_r <= 0;
        finish_return_to_end_block_x_r <= 0;
        finish_return_to_end_block_y_r <= 0;
        finish_calibrate_r <= 0;
        finish_calibrate_x_r <= 0;
        finish_calibrate_y_r <= 0;
        move_to_start_x_cnt_r <= 0;
        move_to_start_y_cnt_r <= 0;
        move_block_x_cnt_r <= 0;
        move_block_y_cnt_r <= 0;
        calibrate_move_x_cnt_r <= 0;
        calibrate_move_y_cnt_r <= 0;
        return_to_end_block_x_cnt_r <= 0;
        return_to_end_block_y_cnt_r <= 0;
        last_xy_move_r <= 0;
        x_en_r <= 0;
        y_en_r <= 0;
        calibrate_cnt_r <= 0;
        x_dir_r <= 0;
        y_dir_r <= 0;
        to_motor_x_total_steps_r <= 0;
        to_motor_y_total_steps_r <= 0;
        current_x_pos_r <= 0;
        current_y_pos_r <= 0;
        magnet_r <= 0;
        to_camera_done_r <= 0;
        halt_calibrate_cnt_r <= 0;
        halt_move_cnt_r <= 0;
    end
    else begin
        state_r <= state_w;
        if (state_r == S_IDLE) begin
            start_block_r <= i_Start_Block;
            end_block_r <= i_End_Block;
        end
        else begin
            start_block_r <= start_block_w;
            end_block_r <= end_block_w;
        end
        finish_move_to_start_r <= finish_move_to_start_w;
        finish_move_to_start_x_r <= finish_move_to_start_x_w;
        finish_move_to_start_y_r <= finish_move_to_start_y_w;
        finish_move_block_r <= finish_move_block_w;
        finish_move_block_x_r <= finish_move_block_x_w;
        finish_move_block_y_r <= finish_move_block_y_w;
        finish_return_to_end_block_r <= finish_return_to_end_block_w;
        finish_return_to_end_block_x_r <= finish_return_to_end_block_x_w;
        finish_return_to_end_block_y_r <= finish_return_to_end_block_y_w;
        finish_calibrate_r <= finish_calibrate_w;
        finish_calibrate_x_r <= finish_calibrate_x_w;
        finish_calibrate_y_r <= finish_calibrate_y_w;
        move_to_start_x_cnt_r <= move_to_start_x_cnt_w;
        move_to_start_y_cnt_r <= move_to_start_y_cnt_w;
        move_block_x_cnt_r <= move_block_x_cnt_w;
        move_block_y_cnt_r <= move_block_y_cnt_w;
        calibrate_move_x_cnt_r <= calibrate_move_x_cnt_w;
        calibrate_move_y_cnt_r <= calibrate_move_y_cnt_w;
        return_to_end_block_x_cnt_r <= return_to_end_block_x_cnt_w;
        return_to_end_block_y_cnt_r <= return_to_end_block_y_cnt_w;
        last_xy_move_r <= last_xy_move_w;
        x_en_r <= x_en_w;
        y_en_r <= y_en_w;
        calibrate_cnt_r <= calibrate_cnt_w;
        x_dir_r <= x_dir_w;
        y_dir_r <= y_dir_w;
        to_motor_x_total_steps_r <= to_motor_x_total_steps_w;
        to_motor_y_total_steps_r <= to_motor_y_total_steps_w;
        current_x_pos_r <= current_x_pos_w;
        current_y_pos_r <= current_y_pos_w;
        magnet_r <= magnet_w;
        to_camera_done_r <= to_camera_done_w; 
        halt_calibrate_cnt_r <= halt_calibrate_cnt_w;
        halt_move_cnt_r <= halt_move_cnt_w;
    end
end
//

//submodule
Motor_Control x_motor(
    .i_Clk(i_Clk),
    .i_rst_n(i_rst_n),
    .i_en(x_en_r),
    .i_direction(x_dir_r),
    .i_total_steps(to_motor_x_total_steps_r),
    .o_step_control(o_to_camera_x_step),
    .o_direction(o_to_camera_x_direction),
    .o_done(motor_x_done)
);

Motor_Control y_motor(
    .i_Clk(i_Clk),
    .i_rst_n(i_rst_n),
    .i_en(y_en_r),
    .i_direction(y_dir_r),
    .i_total_steps(to_motor_y_total_steps_r),
    .o_step_control(o_to_camera_y_step),
    .o_direction(o_to_camera_y_direction),
    .o_done(motor_y_done)
);
//
endmodule