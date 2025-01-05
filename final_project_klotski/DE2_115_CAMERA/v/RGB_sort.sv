module RGBSort (
  input i_clk, i_rst_n,
  input [23:0] i_block0, i_block1, i_block2, i_block3, i_block4, i_block5, i_block6, i_block7, i_block8, i_block9, i_block10, i_block11, i_block12, i_block13, i_block14, i_block15,
  input i_start,
  output [63:0] o_order,
  output o_done
);
  typedef enum logic [3:0] {
    S_IDLE,  // 2'b00
    S_1,
    S_2,
    S_3,
    S_4,  
    S_5,
    S_6,
    S_POST1,
    S_POST2,
    S_DONE
  } state_t;

  state_t state, state_nxt;
  logic [7:0] number_r [2:0][15:0], number_w [2:0][15:0]; // RGB
  logic [3:0] order_r [2:0][15:0], order_w [2:0][15:0]; // RGB
  logic [7:0] tocomp_data1 [2:0][7:0], tocomp_data2 [2:0][7:0]; // RGB
  logic [3:0] tocomp_pos1 [2:0][7:0], tocomp_pos2 [2:0][7:0];
  logic [7:0] fromcomp_data1 [2:0][7:0], fromcomp_data2 [2:0][7:0];
  logic [3:0] fromcomp_pos1 [2:0][7:0], fromcomp_pos2 [2:0][7:0];
  logic [1:0] counter, counter_nxt;
  logic counter_big, counter_big_nxt;

  const logic [3:0] LUT [0:2][0:2][0:2] = '{'{'{4'd15, 4'd14, 4'd14}, '{4'd13, 4'd0, 4'd12}, '{4'd11, 4'd0, 4'd10}}, '{'{4'd9, 4'd0, 4'd8}, '{4'd7, 4'd0, 4'd0}, '{4'd0, 4'd6, 4'd0}}, '{'{4'd5, 4'd4, 4'd0}, '{4'd3, 4'd0, 4'd0}, '{4'd2, 4'd0, 4'd1}}};
  // RGB
  integer i, j, k, p, q;

  assign o_done = (state == S_DONE);
  assign o_order = {order_r[0][0], order_r[0][1], order_r[0][2], order_r[0][3], order_r[0][4], order_r[0][5], order_r[0][6], order_r[0][7], order_r[0][8], order_r[0][9], order_r[0][10], order_r[0][11], order_r[0][12], order_r[0][13], order_r[0][14], order_r[0][15]};

  genvar gi, gj;
  generate
    for (gi = 0; gi < 3; gi++) begin : color_gen
      for (gj = 0; gj < 8; gj++) begin : which_gen
        compare2 u_compare2 (
          .i_data1(tocomp_data1[gi][gj]),
          .i_data2(tocomp_data2[gi][gj]),
          .i_pos1(tocomp_pos1[gi][gj]),
          .i_pos2(tocomp_pos2[gi][gj]),
          .o_data1(fromcomp_data1[gi][gj]),
          .o_data2(fromcomp_data2[gi][gj]),
          .o_pos1(fromcomp_pos1[gi][gj]),
          .o_pos2(fromcomp_pos2[gi][gj])
        );
      end
    end
  endgenerate


  always_comb begin
    state_nxt = state;
    counter_nxt = counter;
    counter_big_nxt = counter_big;
    i = 0;
    j = 0;
    k = 0;
    p = 0;
    q = 0;
    for (i = 0; i < 3; i += 1) begin
        for(j = 0; j < 8 ; j += 1) begin
            tocomp_data1[i][j] = 0;
            tocomp_data2[i][j] = 0;
            tocomp_pos1[i][j] = 0;
            tocomp_pos2[i][j] = 0;
            
        end
    end
    for(i=0; i<3; i=i+1) begin
      for(j=0; j<16; j=j+1) begin
        number_w[i][j] = number_r[i][j]; //R=2, G=1, B=0
        order_w[i][j] = order_r[i][j];
      end
    end
    /*
    for (i = 0; i < 3; i += 1) begin
        for (j = 0; j < 3; j += 1) begin
              for  (k = 0 ; j < 3; j += 1){
                LUT[i][j][k]
              }
        end
    end
    */
    case(state)
      S_IDLE: begin
        if(i_start) begin
          state_nxt = S_1;
          for(i=0; i<3; i=i+1) begin
            for(j=0; j<16; j=j+1) begin
              order_w[i][j] = j;
            end
            number_w[i][0] = i_block0[8*i+7-:8]; //R=2, G=1, B=0
            number_w[i][1] = i_block1[8*i+7-:8];
            number_w[i][2] = i_block2[8*i+7-:8];
            number_w[i][3] = i_block3[8*i+7-:8];
            number_w[i][4] = i_block4[8*i+7-:8];
            number_w[i][5] = i_block5[8*i+7-:8];
            number_w[i][6] = i_block6[8*i+7-:8];
            number_w[i][7] = i_block7[8*i+7-:8];
            number_w[i][8] = i_block8[8*i+7-:8];
            number_w[i][9] = i_block9[8*i+7-:8];
            number_w[i][10] = i_block10[8*i+7-:8];
            number_w[i][11] = i_block11[8*i+7-:8];
            number_w[i][12] = i_block12[8*i+7-:8];
            number_w[i][13] = i_block13[8*i+7-:8];
            number_w[i][14] = i_block14[8*i+7-:8];
            number_w[i][15] = i_block15[8*i+7-:8];
          end
          counter_nxt = 0;
          counter_big_nxt = 0;
        end
      end
      S_1: begin
        if(counter == 0)
          state_nxt = S_2;
        else if(counter == 1)
          state_nxt = S_3;
        else if(counter == 2)
          state_nxt = S_5;
        else if(counter == 3)
          state_nxt = S_POST1;
        counter_nxt = counter+1;
        for(i=0; i<3; i=i+1) begin
          for(j=0; j<8; j=j+1) begin
            tocomp_data1[i][j] = number_r[i][2*j];
            tocomp_data2[i][j] = number_r[i][2*j+1];
            tocomp_pos1[i][j] = order_r[i][2*j];
            tocomp_pos2[i][j] = order_r[i][2*j+1];
            number_w[i][2*j] = fromcomp_data1[i][j];
            number_w[i][2*j+1] = fromcomp_data2[i][j];
            order_w[i][2*j] = fromcomp_pos1[i][j];
            order_w[i][2*j+1] = fromcomp_pos2[i][j];
          end
        end
      end
      S_2: begin
        state_nxt = S_1;
        for(i=0; i<3; i=i+1) begin
          for(j=0; j<4; j=j+1) begin
            for(k=0; k<2; k=k+1) begin
              tocomp_data1[i][2*j+k] = number_r[i][4*j+k];
              tocomp_data2[i][2*j+k] = number_r[i][4*j+3-k];
              tocomp_pos1[i][2*j+k] = order_r[i][4*j+k];
              tocomp_pos2[i][2*j+k] = order_r[i][4*j+3-k];
              number_w[i][4*j+k] = fromcomp_data1[i][2*j+k];
              number_w[i][4*j+3-k] = fromcomp_data2[i][2*j+k];
              order_w[i][4*j+k] = fromcomp_pos1[i][2*j+k];
              order_w[i][4*j+3-k] = fromcomp_pos2[i][2*j+k];
            end
          end
        end
      end
      S_3: begin
        state_nxt = S_4;
        for(i=0; i<3; i=i+1) begin
          for(j=0; j<2; j=j+1) begin
            for(k=0; k<4; k=k+1) begin
              tocomp_data1[i][4*j+k] = number_r[i][8*j+k];
              tocomp_data2[i][4*j+k] = number_r[i][8*j-k+7];
              tocomp_pos1[i][4*j+k] = order_r[i][8*j+k];
              tocomp_pos2[i][4*j+k] = order_r[i][8*j-k+7];
              number_w[i][8*j+k] = fromcomp_data1[i][4*j+k];
              number_w[i][8*j-k+7] = fromcomp_data2[i][4*j+k];
              order_w[i][8*j+k] = fromcomp_pos1[i][4*j+k];
              order_w[i][8*j-k+7] = fromcomp_pos2[i][4*j+k];
            end
          end
        end
      end
      S_4: begin
        counter_big_nxt = counter_big+1;
        if(counter_big == 0)
          state_nxt = S_1;
        else
          state_nxt = S_1;
        for(i=0; i<3; i=i+1) begin
          for(j=0; j<4; j=j+1) begin
            tocomp_data1[i][2*j] = number_r[i][4*j];
            tocomp_data2[i][2*j] = number_r[i][4*j+2];
            tocomp_pos1[i][2*j] = order_r[i][4*j];
            tocomp_pos2[i][2*j] = order_r[i][4*j+2];
            tocomp_data1[i][2*j+1] = number_r[i][4*j+1];
            tocomp_data2[i][2*j+1] = number_r[i][4*j+3];
            tocomp_pos1[i][2*j+1] = order_r[i][4*j+1];
            tocomp_pos2[i][2*j+1] = order_r[i][4*j+3];
          end
          for(k=0; k<4; k=k+1) begin
            number_w[i][4*k] = fromcomp_data1[i][2*k];
            number_w[i][4*k+1] = fromcomp_data1[i][2*k+1];
            number_w[i][4*k+2] = fromcomp_data2[i][2*k];
            number_w[i][4*k+3] = fromcomp_data2[i][2*k+1];
            order_w[i][4*k] = fromcomp_pos1[i][2*k];
            order_w[i][4*k+1] = fromcomp_pos1[i][2*k+1];
            order_w[i][4*k+2] = fromcomp_pos2[i][2*k];
            order_w[i][4*k+3] = fromcomp_pos2[i][2*k+1];
          end
        end
      end
      S_5: begin
        state_nxt = S_6;
        for(i=0; i<3; i=i+1) begin
          for(j=0; j<8; j=j+1) begin
            tocomp_data1[i][j] = number_r[i][j];
            tocomp_data2[i][j] = number_r[i][15-j];
            tocomp_pos1[i][j] = order_r[i][j];
            tocomp_pos2[i][j] = order_r[i][15-j];
          end
          for(k=0; k<8; k=k+1) begin
            number_w[i][k] = fromcomp_data1[i][k];
            number_w[i][15-k] = fromcomp_data2[i][k];
            order_w[i][k] = fromcomp_pos1[i][k];
            order_w[i][15-k] = fromcomp_pos2[i][k];
          end
        end
      end
      S_6: begin
        state_nxt = S_4;
        for(i=0; i<3; i=i+1) begin
          for(j=0; j<2; j=j+1) begin
            for(k=0; k<4; k=k+1) begin
              tocomp_data1[i][4*j+k] = number_r[i][8*j+k];
              tocomp_data2[i][4*j+k] = number_r[i][8*j+k+4];
              tocomp_pos1[i][4*j+k] = order_r[i][8*j+k];
              tocomp_pos2[i][4*j+k] = order_r[i][8*j+k+4];
              number_w[i][8*j+k] = fromcomp_data1[i][4*j+k];
              number_w[i][8*j+k+4] = fromcomp_data2[i][4*j+k];
              order_w[i][8*j+k] = fromcomp_pos1[i][4*j+k];
              order_w[i][8*j+k+4] = fromcomp_pos2[i][4*j+k];
            end
          end
        end
      end
      S_POST1: begin
        state_nxt = S_POST2;
        for(i=0; i<16; i=i+1) begin
          if((order_r[2][0] == i) || (order_r[2][1] == i) || (order_r[2][2] == i) || (order_r[2][3] == i) || (order_r[2][4] == i) || (order_r[2][5] == i))
            number_w[0][i] = 0;
          else if((order_r[2][6] == i) || (order_r[2][7] == i) || (order_r[2][8] == i) || (order_r[2][9] == i))
            number_w[0][i] = 1;
          else
            number_w[0][i] = 2;
          if((order_r[1][0] == i) || (order_r[1][1] == i) || (order_r[1][2] == i) || (order_r[1][3] == i) || (order_r[1][4] == i) || (order_r[1][5] == i))
            number_w[1][i] = 0;
          else if((order_r[1][6] == i) || (order_r[1][7] == i) || (order_r[1][8] == i) || (order_r[1][9] == i) || (order_r[1][10] == i))
            number_w[1][i] = 1;
          else
            number_w[1][i] = 2;
          if((order_r[0][0] == i) || (order_r[0][1] == i) || (order_r[0][2] == i) || (order_r[0][3] == i) || (order_r[0][4] == i) || (order_r[0][5] == i) || (order_r[0][6] == i) || (order_r[0][7] == i))
            number_w[2][i] = 0;
          else if((order_r[0][8] == i) || (order_r[0][9] == i))
            number_w[2][i] = 1; 
          else
            number_w[2][i] = 2;
        end
      end
      S_POST2: begin
        state_nxt = S_DONE;
        for(i=0; i<16; i=i+1) begin
          order_w[0][i] = LUT[number_r[0][i]][number_r[1][i]][number_r[2][i]];
        end
      end
      S_DONE: begin
        state_nxt = S_IDLE;
      end
    endcase
  end
  
  always_ff @(posedge i_clk or negedge i_rst_n) begin
    if(~i_rst_n) begin
      state <= S_IDLE;
      for(p=0; p<3; p=p+1) begin
        for(q=0; q<16; q=q+1) begin
          number_r[p][q] <= 0;
          order_r[p][q] <= 0;
        end
      end
      counter <= 0;
      counter_big <= 0;
    end else begin
      state <= state_nxt;
      counter <= counter_nxt;
      counter_big <= counter_big_nxt;
      for(p=0; p<3; p=p+1) begin
        for(q=0; q<16; q=q+1) begin
          number_r[p][q] <= number_w[p][q];
          order_r[p][q] <= order_w[p][q];
        end
      end
    end
  end

endmodule
  
module compare2 (
  input [7:0] i_data1, i_data2,
  input [3:0] i_pos1, i_pos2,
  output [7:0] o_data1, o_data2,
  output [3:0] o_pos1, o_pos2
);
  logic [7:0] o_data1_w, o_data2_w;
  logic [3:0] o_pos1_w, o_pos2_w;
  
  assign o_data1 = o_data1_w;
  assign o_data2 = o_data2_w;
  assign o_pos1 = o_pos1_w;
  assign o_pos2 = o_pos2_w;

  always_comb begin
    if(i_data1 > i_data2) begin
      o_data1_w = i_data2;
      o_data2_w = i_data1;
      o_pos1_w = i_pos2;
      o_pos2_w = i_pos1;
    end else begin
      o_data1_w = i_data1;
      o_data2_w = i_data2;
      o_pos1_w = i_pos1;
      o_pos2_w = i_pos2;
    end
  end
endmodule