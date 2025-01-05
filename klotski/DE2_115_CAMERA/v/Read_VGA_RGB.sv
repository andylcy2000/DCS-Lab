module Read_VGA(
    input i_Start,
    input [7:0] i_Red,
    input [7:0] i_Green,
    input [7:0] i_Blue,
    input [12:0] i_H_Counter,
    input [12:0] i_V_Counter,

    input i_Clk,
    input i_rst_n,

    output [23:0] o_block1_avg,
    output [23:0] o_block2_avg,
    output [23:0] o_block3_avg,
    output [23:0] o_block4_avg,
    output [23:0] o_block5_avg,
    output [23:0] o_block6_avg,
    output [23:0] o_block7_avg,
    output [23:0] o_block8_avg,
    output [23:0] o_block9_avg,
    output [23:0] o_block10_avg,
    output [23:0] o_block11_avg,
    output [23:0] o_block12_avg,
    output [23:0] o_block13_avg,
    output [23:0] o_block14_avg,
    output [23:0] o_block15_avg,
    output [23:0] o_block16_avg,

    output o_done

);

//	Horizontal Parameter	( Pixel )
parameter	H_SYNC_CYC	=	128;         //Peli
parameter	H_SYNC_BACK	=	88;
parameter	H_SYNC_ACT	=	800;	
parameter	H_SYNC_FRONT=	40;
parameter	H_SYNC_TOTAL=	1056;
//	Virtical Parameter		( Line )
parameter	V_SYNC_CYC	=	4;
parameter	V_SYNC_BACK	=	23;
parameter	V_SYNC_ACT	=	600;	
parameter	V_SYNC_FRONT=	1;
parameter	V_SYNC_TOTAL=	628;

//	Start Offset
parameter	X_START		=	40;
parameter	Y_START		=	45;

localparam START_H_POS = 120;
localparam START_V_POS = 10;

localparam H_intra_block_width = 15;
localparam H_inter_block_width = 140;

localparam V_intra_block_width = 15;
localparam V_inter_block_width = 145;

localparam block1_h1 = X_START+START_H_POS;
localparam block1_h2 = X_START+START_H_POS + H_intra_block_width;
localparam block1_h3 = X_START+START_H_POS + (H_intra_block_width << 1);
localparam block1_h4 = X_START+START_H_POS + (H_intra_block_width << 1) + H_intra_block_width;

localparam block2_h1 = X_START+START_H_POS + H_inter_block_width;
localparam block2_h2 = X_START+START_H_POS + H_inter_block_width + H_intra_block_width;
localparam block2_h3 = X_START+START_H_POS + H_inter_block_width + (H_intra_block_width << 1);
localparam block2_h4 = X_START+START_H_POS + H_inter_block_width + (H_intra_block_width << 1) + H_intra_block_width;

localparam block3_h1 = X_START+START_H_POS + (H_inter_block_width << 1);
localparam block3_h2 = X_START+START_H_POS + (H_inter_block_width << 1) + H_intra_block_width;
localparam block3_h3 = X_START+START_H_POS + (H_inter_block_width << 1) + (H_intra_block_width << 1);
localparam block3_h4 = X_START+START_H_POS + (H_inter_block_width << 1) + (H_intra_block_width << 1) + H_intra_block_width;

localparam block4_h1 = X_START+START_H_POS + H_inter_block_width + (H_inter_block_width << 1);
localparam block4_h2 = X_START+START_H_POS + H_inter_block_width + (H_inter_block_width << 1) + H_intra_block_width;
localparam block4_h3 = X_START+START_H_POS + H_inter_block_width + (H_inter_block_width << 1) + (H_intra_block_width << 1);
localparam block4_h4 = X_START+START_H_POS + H_inter_block_width + (H_inter_block_width << 1) + (H_intra_block_width << 1) + H_intra_block_width;

localparam block5_h1 = block1_h1;
localparam block5_h2 = block1_h2;
localparam block5_h3 = block1_h3;
localparam block5_h4 = block1_h4;

localparam block6_h1 = block2_h1;
localparam block6_h2 = block2_h2;
localparam block6_h3 = block2_h3;
localparam block6_h4 = block2_h4;

localparam block7_h1 = block3_h1;
localparam block7_h2 = block3_h2;
localparam block7_h3 = block3_h3;
localparam block7_h4 = block3_h4;

localparam block8_h1 = block4_h1;
localparam block8_h2 = block4_h2;
localparam block8_h3 = block4_h3;
localparam block8_h4 = block4_h4;

localparam block9_h1 = block5_h1;
localparam block9_h2 = block5_h2;
localparam block9_h3 = block5_h3;
localparam block9_h4 = block5_h4;

localparam block10_h1 = block6_h1;
localparam block10_h2 = block6_h2;
localparam block10_h3 = block6_h3;
localparam block10_h4 = block6_h4;

localparam block11_h1 = block7_h1;
localparam block11_h2 = block7_h2;
localparam block11_h3 = block7_h3;
localparam block11_h4 = block7_h4;

localparam block12_h1 = block8_h1;
localparam block12_h2 = block8_h2;
localparam block12_h3 = block8_h3;
localparam block12_h4 = block8_h4;

localparam block13_h1 = block9_h1;
localparam block13_h2 = block9_h2;
localparam block13_h3 = block9_h3;
localparam block13_h4 = block9_h4;

localparam block14_h1 = block10_h1;
localparam block14_h2 = block10_h2;
localparam block14_h3 = block10_h3;
localparam block14_h4 = block10_h4;

localparam block15_h1 = block11_h1;
localparam block15_h2 = block11_h2;
localparam block15_h3 = block11_h3;
localparam block15_h4 = block11_h4;

localparam block16_h1 = block12_h1;
localparam block16_h2 = block12_h2;
localparam block16_h3 = block12_h3;
localparam block16_h4 = block12_h4;

localparam block_16_h1 = block13_h1;
localparam block_16_h2 = block13_h2;
localparam block_16_h3 = block13_h3;
localparam block_16_h4 = block13_h4;



localparam block1_v1 = Y_START+START_V_POS;
localparam block1_v2 = Y_START+START_V_POS + V_intra_block_width;

localparam block2_v1 = block1_v1;
localparam block2_v2 = block1_v2;

localparam block3_v1 = block1_v1;
localparam block3_v2 = block1_v2;

localparam block4_v1 = block1_v1;
localparam block4_v2 = block1_v2;

localparam block5_v1 = Y_START+START_V_POS + V_inter_block_width;
localparam block5_v2 = Y_START+START_V_POS + V_inter_block_width + V_intra_block_width;

localparam block6_v1 = block5_v1;
localparam block6_v2 = block5_v2;

localparam block7_v1 = block5_v1;
localparam block7_v2 = block5_v2;

localparam block8_v1 = block5_v1;
localparam block8_v2 = block5_v2;

localparam block9_v1 = Y_START+START_V_POS + (V_inter_block_width << 1);
localparam block9_v2 = Y_START+START_V_POS + (V_inter_block_width << 1) + V_intra_block_width;

localparam block10_v1 = block9_v1;
localparam block10_v2 = block9_v2;

localparam block11_v1 = block9_v1;
localparam block11_v2 = block9_v2;

localparam block12_v1 = block9_v1;
localparam block12_v2 = block9_v2;

localparam block13_v1 = Y_START+START_V_POS + V_inter_block_width + (V_inter_block_width << 1) ;
localparam block13_v2 = Y_START+START_V_POS + V_inter_block_width + (V_inter_block_width << 1) + V_intra_block_width;

localparam block14_v1 = block13_v1;
localparam block14_v2 = block13_v2;

localparam block15_v1 = block13_v1;
localparam block15_v2 = block13_v2;

localparam block16_v1 = block13_v1;
localparam block16_v2 = block13_v2;

logic [12:0] block_Red_value_r [0:15];
logic [12:0] block_Green_value_r [0:15];
logic [12:0] block_Blue_value_r [0:15];
logic [12:0] block_Red_value_w [0:15];
logic [12:0] block_Green_value_w [0:15];
logic [12:0] block_Blue_value_w [0:15];

logic [12:0] Red_r, Green_r, Blue_r;
logic [12:0] H_Counter_r, V_Counter_r;

logic o_done_r, o_done_w;


integer i, j;
//assign
assign o_block1_avg  = {block_Red_value_r[0][7:0], block_Green_value_r[0][7:0], block_Blue_value_r[0][7:0]};
assign o_block2_avg  = {block_Red_value_r[1][7:0], block_Green_value_r[1][7:0], block_Blue_value_r[1][7:0]};
assign o_block3_avg  = {block_Red_value_r[2][7:0], block_Green_value_r[2][7:0], block_Blue_value_r[2][7:0]};
assign o_block4_avg  = {block_Red_value_r[3][7:0], block_Green_value_r[3][7:0], block_Blue_value_r[3][7:0]};
assign o_block5_avg  = {block_Red_value_r[4][7:0], block_Green_value_r[4][7:0], block_Blue_value_r[4][7:0]};
assign o_block6_avg  = {block_Red_value_r[5][7:0], block_Green_value_r[5][7:0], block_Blue_value_r[5][7:0]};
assign o_block7_avg  = {block_Red_value_r[6][7:0], block_Green_value_r[6][7:0], block_Blue_value_r[6][7:0]};
assign o_block8_avg  = {block_Red_value_r[7][7:0], block_Green_value_r[7][7:0], block_Blue_value_r[7][7:0]};
assign o_block9_avg  = {block_Red_value_r[8][7:0], block_Green_value_r[8][7:0], block_Blue_value_r[8][7:0]};
assign o_block10_avg = {block_Red_value_r[9][7:0], block_Green_value_r[9][7:0], block_Blue_value_r[9][7:0]};
assign o_block11_avg = {block_Red_value_r[10][7:0], block_Green_value_r[10][7:0], block_Blue_value_r[10][7:0]};
assign o_block12_avg = {block_Red_value_r[11][7:0], block_Green_value_r[11][7:0], block_Blue_value_r[11][7:0]};
assign o_block13_avg = {block_Red_value_r[12][7:0], block_Green_value_r[12][7:0], block_Blue_value_r[12][7:0]};
assign o_block14_avg = {block_Red_value_r[13][7:0], block_Green_value_r[13][7:0], block_Blue_value_r[13][7:0]};
assign o_block15_avg = {block_Red_value_r[14][7:0], block_Green_value_r[14][7:0], block_Blue_value_r[14][7:0]};
assign o_block16_avg = {block_Red_value_r[15][7:0], block_Green_value_r[15][7:0], block_Blue_value_r[15][7:0]};

assign o_done = o_done_r;
//

//state enumeration
typedef enum logic [2:0] {
    S_IDLE     = 3'b000,
    S_WAIT_V_CONT_0 = 3'b001,
    S_RECEIVE = 3'b010,
    S_AVG = 3'b011,
    S_DONE = 3'b100
} state_t;

state_t state_r, state_w;
//

///////////////////combinational part///////////////////

//FSM
always_comb begin
    state_w = state_r;
    case (state_r)
        S_IDLE: begin
            if (i_Start) begin
                state_w = S_WAIT_V_CONT_0;
            end
            else begin
                state_w = S_IDLE;
            end
        end

        S_WAIT_V_CONT_0: begin
            if (V_Counter_r == 0) begin
                state_w = S_RECEIVE;
            end
            else begin
                state_w = S_WAIT_V_CONT_0;
            end
        end

        S_RECEIVE: begin
            if ((H_Counter_r >= 742) && (V_Counter_r >= 542)) begin
                state_w = S_AVG;
            end
        end

        S_AVG: begin
            state_w = S_DONE;
        end

        S_DONE: begin
            state_w = S_IDLE;
        end
    endcase
end
//

//state_behavior
always_comb begin
    o_done_w = 0;
    for (j = 0; j < 16; j = j + 1) begin
        block_Red_value_w[j] = block_Red_value_r[j];
        block_Green_value_w[j] = block_Green_value_r[j];
        block_Blue_value_w[j] = block_Blue_value_r[j];
    end
    case (state_r)
        S_IDLE: begin
            if (i_Start) begin
                for (j = 0; j < 16; j = j + 1) begin
                    block_Red_value_w[j] <= 13'b0;
                    block_Green_value_w[j] <= 13'b0;
                    block_Blue_value_w[j] <= 13'b0;
                end
            end
        end

        S_WAIT_V_CONT_0: begin
            
        end

        S_RECEIVE: begin
            if (((H_Counter_r == block1_h1) || // block1
                (H_Counter_r == block1_h2) ||
                (H_Counter_r == block1_h3) ||
                (H_Counter_r == block1_h4)) &&
                ((V_Counter_r == block1_v1) || (V_Counter_r == block1_v2))) begin
                block_Red_value_w[0] = block_Red_value_r[0] + Red_r;
                block_Green_value_w[0] = block_Green_value_r[0] + Green_r;
                block_Blue_value_w[0] = block_Blue_value_r[0] + Blue_r;
            end
            else if (((H_Counter_r == block2_h1) || // block2
                    (H_Counter_r == block2_h2) ||
                    (H_Counter_r == block2_h3) ||
                    (H_Counter_r == block2_h4)) &&
                    ((V_Counter_r == block2_v1) || (V_Counter_r == block2_v2))) begin
                block_Red_value_w[1] = block_Red_value_r[1] + Red_r;
                block_Green_value_w[1] = block_Green_value_r[1] + Green_r;
                block_Blue_value_w[1] = block_Blue_value_r[1] + Blue_r;
            end
            else if (((H_Counter_r == block3_h1) || // block3
                    (H_Counter_r == block3_h2) ||
                    (H_Counter_r == block3_h3) ||
                    (H_Counter_r == block3_h4)) &&
                    ((V_Counter_r == block3_v1) || (V_Counter_r == block3_v2))) begin
                block_Red_value_w[2] = block_Red_value_r[2] + Red_r;
                block_Green_value_w[2] = block_Green_value_r[2] + Green_r;
                block_Blue_value_w[2] = block_Blue_value_r[2] + Blue_r;
            end
            else if (((H_Counter_r == block4_h1) || // block4
                    (H_Counter_r == block4_h2) ||
                    (H_Counter_r == block4_h3) ||
                    (H_Counter_r == block4_h4)) &&
                    ((V_Counter_r == block4_v1) || (V_Counter_r == block4_v2))) begin
                block_Red_value_w[3] = block_Red_value_r[3] + Red_r;
                block_Green_value_w[3] = block_Green_value_r[3] + Green_r;
                block_Blue_value_w[3] = block_Blue_value_r[3] + Blue_r;
            end
            else if (((H_Counter_r == block5_h1) || // block5
                    (H_Counter_r == block5_h2) ||
                    (H_Counter_r == block5_h3) ||
                    (H_Counter_r == block5_h4)) &&
                    ((V_Counter_r == block5_v1) || (V_Counter_r == block5_v2))) begin
                block_Red_value_w[4] = block_Red_value_r[4] + Red_r;
                block_Green_value_w[4] = block_Green_value_r[4] + Green_r;
                block_Blue_value_w[4] = block_Blue_value_r[4] + Blue_r;
            end
            else if (((H_Counter_r == block6_h1) || // block6
                    (H_Counter_r == block6_h2) ||
                    (H_Counter_r == block6_h3) ||
                    (H_Counter_r == block6_h4)) &&
                    ((V_Counter_r == block6_v1) || (V_Counter_r == block6_v2))) begin
                block_Red_value_w[5] = block_Red_value_r[5] + Red_r;
                block_Green_value_w[5] = block_Green_value_r[5] + Green_r;
                block_Blue_value_w[5] = block_Blue_value_r[5] + Blue_r;
            end
            else if (((H_Counter_r == block7_h1) || // block7
                    (H_Counter_r == block7_h2) ||
                    (H_Counter_r == block7_h3) ||
                    (H_Counter_r == block7_h4)) &&
                    ((V_Counter_r == block7_v1) || (V_Counter_r == block7_v2))) begin
                block_Red_value_w[6] = block_Red_value_r[6] + Red_r;
                block_Green_value_w[6] = block_Green_value_r[6] + Green_r;
                block_Blue_value_w[6] = block_Blue_value_r[6] + Blue_r;
            end
            else if (((H_Counter_r == block8_h1) || // block8
                    (H_Counter_r == block8_h2) ||
                    (H_Counter_r == block8_h3) ||
                    (H_Counter_r == block8_h4)) &&
                    ((V_Counter_r == block8_v1) || (V_Counter_r == block8_v2))) begin
                block_Red_value_w[7] = block_Red_value_r[7] + Red_r;
                block_Green_value_w[7] = block_Green_value_r[7] + Green_r;
                block_Blue_value_w[7] = block_Blue_value_r[7] + Blue_r;
            end
            else if (((H_Counter_r == block9_h1) || // block9
                    (H_Counter_r == block9_h2) ||
                    (H_Counter_r == block9_h3) ||
                    (H_Counter_r == block9_h4)) &&
                    ((V_Counter_r == block9_v1) || (V_Counter_r == block9_v2))) begin
                block_Red_value_w[8] = block_Red_value_r[8] + Red_r;
                block_Green_value_w[8] = block_Green_value_r[8] + Green_r;
                block_Blue_value_w[8] = block_Blue_value_r[8] + Blue_r;
            end
            else if (((H_Counter_r == block10_h1) || // block10
                    (H_Counter_r == block10_h2) ||
                    (H_Counter_r == block10_h3) ||
                    (H_Counter_r == block10_h4)) &&
                    ((V_Counter_r == block10_v1) || (V_Counter_r == block10_v2))) begin
                block_Red_value_w[9] = block_Red_value_r[9] + Red_r;
                block_Green_value_w[9] = block_Green_value_r[9] + Green_r;
                block_Blue_value_w[9] = block_Blue_value_r[9] + Blue_r;
            end
            else if (((H_Counter_r == block11_h1) || // block11
                    (H_Counter_r == block11_h2) ||
                    (H_Counter_r == block11_h3) ||
                    (H_Counter_r == block11_h4)) &&
                    ((V_Counter_r == block11_v1) || (V_Counter_r == block11_v2))) begin
                block_Red_value_w[10] = block_Red_value_r[10] + Red_r;
                block_Green_value_w[10] = block_Green_value_r[10] + Green_r;
                block_Blue_value_w[10] = block_Blue_value_r[10] + Blue_r;
            end
            else if (((H_Counter_r == block12_h1) || // block12
                    (H_Counter_r == block12_h2) ||
                    (H_Counter_r == block12_h3) ||
                    (H_Counter_r == block12_h4)) &&
                    ((V_Counter_r == block12_v1) || (V_Counter_r == block12_v2))) begin
                block_Red_value_w[11] = block_Red_value_r[11] + Red_r;
                block_Green_value_w[11] = block_Green_value_r[11] + Green_r;
                block_Blue_value_w[11] = block_Blue_value_r[11] + Blue_r;
            end
            else if (((H_Counter_r == block13_h1) || // block13
                    (H_Counter_r == block13_h2) ||
                    (H_Counter_r == block13_h3) ||
                    (H_Counter_r == block13_h4)) &&
                    ((V_Counter_r == block13_v1) || (V_Counter_r == block13_v2))) begin
                block_Red_value_w[12] = block_Red_value_r[12] + Red_r;
                block_Green_value_w[12] = block_Green_value_r[12] + Green_r;
                block_Blue_value_w[12] = block_Blue_value_r[12] + Blue_r;
            end
            else if (((H_Counter_r == block14_h1) || // block14
                    (H_Counter_r == block14_h2) ||
                    (H_Counter_r == block14_h3) ||
                    (H_Counter_r == block14_h4)) &&
                    ((V_Counter_r == block14_v1) || (V_Counter_r == block14_v2))) begin
                block_Red_value_w[13] = block_Red_value_r[13] + Red_r;
                block_Green_value_w[13] = block_Green_value_r[13] + Green_r;
                block_Blue_value_w[13] = block_Blue_value_r[13] + Blue_r;
            end
            else if (((H_Counter_r == block15_h1) || // block15
                    (H_Counter_r == block15_h2) ||
                    (H_Counter_r == block15_h3) ||
                    (H_Counter_r == block15_h4)) &&
                    ((V_Counter_r == block15_v1) || (V_Counter_r == block15_v2))) begin
                block_Red_value_w[14] = block_Red_value_r[14] + Red_r;
                block_Green_value_w[14] = block_Green_value_r[14] + Green_r;
                block_Blue_value_w[14] = block_Blue_value_r[14] + Blue_r;
            end
            else if (((H_Counter_r == block16_h1) || // block16
                    (H_Counter_r == block16_h2) ||
                    (H_Counter_r == block16_h3) ||
                    (H_Counter_r == block16_h4)) &&
                    ((V_Counter_r == block16_v1) || (V_Counter_r == block16_v2))) begin
                block_Red_value_w[15] = block_Red_value_r[15] + Red_r;
                block_Green_value_w[15] = block_Green_value_r[15] + Green_r;
                block_Blue_value_w[15] = block_Blue_value_r[15] + Blue_r;
            end

        end

        
        S_AVG: begin
            for (j = 0; j < 16; j = j + 1) begin
                block_Red_value_w[j] = block_Red_value_r[j] >> 3;
                block_Green_value_w[j] = block_Green_value_r[j] >> 3;
                block_Blue_value_w[j] = block_Blue_value_r[j] >> 3;
            end
        end

        S_DONE: begin
            o_done_w = 1;
        end
        default: begin
            for (j = 0; j < 16; j = j + 1) begin
                block_Red_value_w[j] = block_Red_value_r[j];
                block_Green_value_w[j] = block_Green_value_r[j];
                block_Blue_value_w[j] = block_Blue_value_r[j];
            end
        end
    endcase
end
//

////////////////////////////////////////////////////////

///////////////////sequential part///////////////////
always_ff @(posedge i_Clk or negedge i_rst_n) begin 
    if(!i_rst_n) begin
        state_r <= S_IDLE;
        for (i = 0; i < 16; i = i + 1) begin
            block_Red_value_r[i] <= 13'b0;
            block_Green_value_r[i] <= 13'b0;
            block_Blue_value_r[i] <= 13'b0;
        end
        o_done_r <= 0;
        Red_r <= 0;
        Green_r <= 0;
        Blue_r <= 0;
        H_Counter_r <= 0;
        V_Counter_r <= 0;
    end
    else begin
        state_r <= state_w;
        for (i = 0; i < 16; i = i + 1) begin
            block_Red_value_r[i] <= block_Red_value_w[i];
            block_Green_value_r[i] <= block_Green_value_w[i];
            block_Blue_value_r[i] <= block_Blue_value_w[i]; 
        end
        o_done_r <= o_done_w;
        Red_r <= i_Red;
        Green_r <= i_Green;
        Blue_r <= i_Blue;
        H_Counter_r <= i_H_Counter;
        V_Counter_r <= i_V_Counter;
    end
    
end

/////////////////////////////////////////////////////
endmodule