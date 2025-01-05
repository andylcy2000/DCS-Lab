// --------------------------------------------------------------------
// Copyright (c) 2010 by Terasic Technologies Inc. 
// --------------------------------------------------------------------
//
// Permission:
//
//   Terasic grants permission to use and modify this code for use
//   in synthesis for all Terasic Development Boards and Altera Development 
//   Kits made by Terasic.  Other use of this code, including the selling 
//   ,duplication, or modification of any portion is strictly prohibited.
//
// Disclaimer:
//
//   This VHDL/Verilog or C/C++ source code is intended as a design reference
//   which illustrates how these types of functions can be implemented.
//   It is the user's responsibility to verify their design for
//   consistency and functionality through the use of formal
//   verification methods.  Terasic provides no warranty regarding the use 
//   or functionality of this code.
//
// --------------------------------------------------------------------
//           
//                     Terasic Technologies Inc
//                     356 Fu-Shin E. Rd Sec. 1. JhuBei City,
//                                                                                                                            HsinChu County, Taiwan
//                     302
//
//                     web: http://www.terasic.com/
//                     email: support@terasic.com
//
// --------------------------------------------------------------------
//
// Major Functions:	VGA_Controller
//
// --------------------------------------------------------------------
//
// Revision History :
// --------------------------------------------------------------------
//   Ver  :| Author            :| Mod. Date :| Changes Made:
//   V1.0 :| Johnny FAN Peli Li:| 22/07/2010:| Initial Revision
// --------------------------------------------------------------------

module	VGA_Controller(	//	Host Side
						iRed,
						iGreen,
						iBlue,
						oRequest,
						//	VGA Side
						oVGA_R,
						oVGA_G,
						oVGA_B,
						oDecoder_G,
						oVGA_H_SYNC,
						oVGA_V_SYNC,
						oVGA_SYNC,
						oVGA_BLANK,
						oH_Cont,
						oV_Cont,

						//	Control Signal
						iCLK,
						iRST_N,
						iZOOM_MODE_SW,
						iFromBlock,
						iToBlock, 
						i_bm_en
							);
`include "VGA_Param.h"

`ifdef VGA_640x480p60
//	Horizontal Parameter	( Pixel )
parameter	H_SYNC_CYC	=	96;
parameter	H_SYNC_BACK	=	48;
parameter	H_SYNC_ACT	=	640;	
parameter	H_SYNC_FRONT=	16;
parameter	H_SYNC_TOTAL=	800;

//	Virtical Parameter		( Line )
parameter	V_SYNC_CYC	=	2;
parameter	V_SYNC_BACK	=	33;
parameter	V_SYNC_ACT	=	480;	
parameter	V_SYNC_FRONT=	10;
parameter	V_SYNC_TOTAL=	525; 

`else
 // SVGA_800x600p60
////	Horizontal Parameter	( Pixel )
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

`endif
//	Start Offset
parameter	X_START		=	H_SYNC_CYC+H_SYNC_BACK;
parameter	Y_START		=	V_SYNC_CYC+V_SYNC_BACK;
//	Host Side
input		[9:0]	iRed;
input		[9:0]	iGreen;
input		[9:0]	iBlue;
output	reg			oRequest;
//	VGA Side
output	reg	[9:0]	oVGA_R;
output	reg	[9:0]	oVGA_G;
output	reg	[9:0]	oVGA_B;
output 	reg [9:0] oDecoder_G;
output	reg			oVGA_H_SYNC;
output	reg			oVGA_V_SYNC;
output	reg			oVGA_SYNC;
output	reg			oVGA_BLANK;
output  wire[12:0]  oH_Cont;
output  wire[12:0]  oV_Cont;

wire		[9:0]	mVGA_R;
wire		[9:0]	mVGA_G;
wire		[9:0]	mVGA_B;
reg					mVGA_H_SYNC;
reg					mVGA_V_SYNC;
wire				mVGA_SYNC;
wire				mVGA_BLANK;

//	Control Signal
input				iCLK;
input				iRST_N;
input 				iZOOM_MODE_SW;
input [3:0]			iFromBlock;
input [3:0]			iToBlock;
input				i_bm_en;

//	Internal Registers and Wires
reg		[12:0]		H_Cont;
reg		[12:0]		V_Cont;

wire	[12:0]		v_mask;

assign v_mask = 13'd0 ;//iZOOM_MODE_SW ? 13'd0 : 13'd26;

////////////////////////////////////////////////////////

assign	mVGA_BLANK	=	mVGA_H_SYNC & mVGA_V_SYNC;
assign	mVGA_SYNC	=	1'b0;

// assign	mVGA_R	=	(	H_Cont>=X_START 	&& H_Cont<X_START+H_SYNC_ACT &&
// 						V_Cont>=Y_START+v_mask 	&& V_Cont<Y_START+V_SYNC_ACT )
// 						?	iRed	:	0;
// assign	mVGA_G	=	(	H_Cont>=X_START 	&& H_Cont<X_START+H_SYNC_ACT &&
// 						V_Cont>=Y_START+v_mask 	&& V_Cont<Y_START+V_SYNC_ACT )
// 						?	iGreen	:	0;
// assign	mVGA_B	=	(	H_Cont>=X_START 	&& H_Cont<X_START+H_SYNC_ACT &&
// 						V_Cont>=Y_START+v_mask 	&& V_Cont<Y_START+V_SYNC_ACT )
// 						?	iBlue	:	0;
localparam START_H_POS = 120;
localparam START_V_POS = 10;

// localparam H_intra_block_width = 15;
// localparam H_inter_block_width = 140;

// localparam V_intra_block_width = 15;
// localparam V_inter_block_width = 145;

localparam H_intra_block_width = 5;
localparam H_inter_block_width = 68;

localparam V_intra_block_width = 5;
localparam V_inter_block_width = 68;

localparam REC_H_L = 5;
localparam REC_V_L = 5;

localparam LEFT_ORIGIN = 36 + START_H_POS;
localparam UP_ORIGIN = 37 + START_V_POS;
localparam REC_LEFT_ORIGIN = H_inter_block_width + START_H_POS;
localparam REC_UP_ORIGIN = V_inter_block_width + START_V_POS;

const logic [9:0] BLOCK_H [0:7][0:1] = '{'{LEFT_ORIGIN, LEFT_ORIGIN + H_intra_block_width}, 
'{LEFT_ORIGIN + H_inter_block_width, LEFT_ORIGIN + H_inter_block_width + H_intra_block_width}, 
'{LEFT_ORIGIN + 2*H_inter_block_width, LEFT_ORIGIN + 2*H_inter_block_width + H_intra_block_width}, 
'{LEFT_ORIGIN + 3*H_inter_block_width, LEFT_ORIGIN + 3*H_inter_block_width + H_intra_block_width}, 
'{LEFT_ORIGIN + 4*H_inter_block_width, LEFT_ORIGIN + 4*H_inter_block_width + H_intra_block_width},
'{LEFT_ORIGIN + 5*H_inter_block_width, LEFT_ORIGIN + 5*H_inter_block_width + H_intra_block_width},
'{LEFT_ORIGIN + 6*H_inter_block_width, LEFT_ORIGIN + 6*H_inter_block_width + H_intra_block_width},
'{LEFT_ORIGIN + 7*H_inter_block_width, LEFT_ORIGIN + 7*H_inter_block_width + H_intra_block_width}};

const logic [9:0] BLOCK_V [0:7][0:1] = '{'{UP_ORIGIN, UP_ORIGIN + V_intra_block_width},
'{UP_ORIGIN + V_inter_block_width, UP_ORIGIN + V_inter_block_width + V_intra_block_width},
'{UP_ORIGIN + 2*V_inter_block_width, UP_ORIGIN + 2*V_inter_block_width + V_intra_block_width},
'{UP_ORIGIN + 3*V_inter_block_width, UP_ORIGIN + 3*V_inter_block_width + V_intra_block_width},
'{UP_ORIGIN + 4*V_inter_block_width, UP_ORIGIN + 4*V_inter_block_width + V_intra_block_width},
'{UP_ORIGIN + 5*V_inter_block_width, UP_ORIGIN + 5*V_inter_block_width + V_intra_block_width},
'{UP_ORIGIN + 6*V_inter_block_width, UP_ORIGIN + 6*V_inter_block_width + V_intra_block_width},
'{UP_ORIGIN + 7*V_inter_block_width, UP_ORIGIN + 7*V_inter_block_width + V_intra_block_width}};

const logic [9:0] REC_H [0:3][0:1] = '{'{REC_LEFT_ORIGIN, REC_LEFT_ORIGIN + REC_H_L},
'{REC_LEFT_ORIGIN + 2*H_inter_block_width, REC_LEFT_ORIGIN + 2*H_inter_block_width + REC_H_L},
'{REC_LEFT_ORIGIN + 4*H_inter_block_width, REC_LEFT_ORIGIN + 4*H_inter_block_width + REC_H_L},
'{REC_LEFT_ORIGIN + 6*H_inter_block_width, REC_LEFT_ORIGIN + 6*H_inter_block_width + REC_H_L}};

const logic [9:0] REC_V [0:3][0:1] = '{'{REC_UP_ORIGIN, REC_UP_ORIGIN + REC_V_L},
'{REC_UP_ORIGIN + 2*V_inter_block_width, REC_UP_ORIGIN + 2*V_inter_block_width + REC_V_L},
'{REC_UP_ORIGIN + 4*V_inter_block_width, REC_UP_ORIGIN + 4*V_inter_block_width + REC_V_L},
'{REC_UP_ORIGIN + 6*V_inter_block_width, REC_UP_ORIGIN + 6*V_inter_block_width + REC_V_L}};

reg [9:0] tmp_R;
integer j, k;
always @(*) begin
	tmp_R = iRed;
	for (j=0; j<8; j=j+1) begin
		for (k=0; k<8; k=k+1) begin
			if (((H_Cont-X_START == BLOCK_H[j][0]) || // block1
			(H_Cont-X_START == BLOCK_H[j][1])) &&
			((V_Cont-Y_START == BLOCK_V[k][0]) || (V_Cont-Y_START == BLOCK_V[k][1]))) begin
				tmp_R = {10{1'b1}};
			end
		end
	end
end
reg [9:0] tmp_B;
reg [9:0] left_bound, right_bound, up_bound, down_bound;
reg [1:0] FromBlock_H, ToBlock_H, FromBlock_V, ToBlock_V;
reg [4:0] from_block_r, from_block_w, to_block_r, to_block_w;
always @(*) begin
	tmp_B = iBlue;
	from_block_w = from_block_r;
	to_block_w = to_block_r;
	FromBlock_H = from_block_r[1:0];
	ToBlock_H = to_block_r[1:0];
	FromBlock_V = from_block_r >> 2;
	ToBlock_V = to_block_r >> 2;
	if (i_bm_en) begin
		from_block_w = iFromBlock;
		to_block_w = iToBlock;
	end
	if(from_block_r == to_block_r - 1) begin //left to right
		
		left_bound = REC_H[FromBlock_H][0];
		//$display("left bound: %d", left_bound);
		right_bound = REC_H[ToBlock_H][1];
		//$display("right bound: %d", right_bound);
		up_bound = REC_V[FromBlock_V][0];
		down_bound = REC_V[ToBlock_V][1];
	end else if(from_block_r == to_block_r - 4) begin //up to down
		left_bound = REC_H[FromBlock_H][0]; 
		right_bound = REC_H[ToBlock_H][1];
		up_bound = REC_V[FromBlock_V][0];
		down_bound = REC_V[ToBlock_V][1];
	end else if (from_block_r == to_block_r + 1) begin //right to left
		left_bound = REC_H[ToBlock_H][0];
		right_bound = REC_H[FromBlock_H][1];
		up_bound = REC_V[ToBlock_V][0];
		down_bound = REC_V[FromBlock_V][1];
	end else begin								   //down to up
		left_bound = REC_H[ToBlock_H][0];
		right_bound = REC_H[FromBlock_H][1];
		up_bound = REC_V[ToBlock_V][0];
		down_bound = REC_V[FromBlock_V][1];
	end
	if (((H_Cont-X_START >= left_bound) && // block1
			(H_Cont-X_START <= right_bound)) &&
			((V_Cont-Y_START >= up_bound) && (V_Cont-Y_START <= down_bound)) && (from_block_r != to_block_r)) begin
				//$display("\nset tmp_B\n");
				tmp_B = {10{1'b1}};
	end
end

assign	mVGA_R	=	(	H_Cont>=X_START+START_H_POS 	&& H_Cont<X_START+START_H_POS+(H_inter_block_width<<3) &&
						V_Cont>=Y_START+v_mask+START_V_POS 	&& V_Cont+v_mask+START_V_POS+(V_inter_block_width<<3) )
						?	tmp_R	:	0;
assign	mVGA_G	=	(	H_Cont>=X_START+START_H_POS 	&& H_Cont<X_START+START_H_POS+(H_inter_block_width<<3) &&
						V_Cont>=Y_START+v_mask+START_V_POS 	&& V_Cont+v_mask+START_V_POS+(V_inter_block_width<<3) )
						?	iGreen	:	0;
assign	mVGA_B	=	(	H_Cont>=X_START+START_H_POS 	&& H_Cont<X_START+START_H_POS+(H_inter_block_width<<3) &&
						V_Cont>=Y_START+v_mask+START_V_POS 	&& V_Cont+v_mask+START_V_POS+(V_inter_block_width<<3) )
						?	tmp_B	:	0;

// assign  oH_Cont = (H_Cont >= X_START) ? (H_Cont - X_START) : 0;
// assign  oV_Cont = (V_Cont >= Y_START) ? (V_Cont - Y_START) : 0;
assign  oH_Cont = (H_Cont - X_START);
assign  oV_Cont = (V_Cont - Y_START);
always@(posedge iCLK or negedge iRST_N)
	begin
		if (!iRST_N)
			begin
				oVGA_R <= 0;
				oVGA_G <= 0;
                oVGA_B <= 0;
				oVGA_BLANK <= 0;
				oVGA_SYNC <= 0;
				oVGA_H_SYNC <= 0;
				oVGA_V_SYNC <= 0;
				from_block_r <= 0;
				to_block_r <= 0; 
			end
		else
			begin
				oVGA_R <= mVGA_R;
				oVGA_G <= mVGA_G;
                oVGA_B <= mVGA_B;
				oVGA_BLANK <= mVGA_BLANK;
				oVGA_SYNC <= mVGA_SYNC;
				oVGA_H_SYNC <= mVGA_H_SYNC;
				oVGA_V_SYNC <= mVGA_V_SYNC;
				from_block_r <= from_block_w;
				to_block_r <= to_block_w;
			end               
	end



//	Pixel LUT Address Generator
always@(posedge iCLK or negedge iRST_N)
begin
	if(!iRST_N)
	oRequest	<=	0;
	else
	begin
		if(	H_Cont>=X_START-2 && H_Cont<X_START+H_SYNC_ACT-2 &&
			V_Cont>=Y_START && V_Cont<Y_START+V_SYNC_ACT )
		oRequest	<=	1;
		else
		oRequest	<=	0;
	end
end

//	H_Sync Generator, Ref. 40 MHz Clock
always@(posedge iCLK or negedge iRST_N)
begin
	if(!iRST_N)
	begin
		H_Cont		<=	0;
		mVGA_H_SYNC	<=	0;
	end
	else
	begin
		//	H_Sync Counter
		if( H_Cont < H_SYNC_TOTAL )
		H_Cont	<=	H_Cont+1;
		else
		H_Cont	<=	0;
		//	H_Sync Generator
		if( H_Cont < H_SYNC_CYC )
		mVGA_H_SYNC	<=	0;//平時為0, counter到達cycle值時為1
		else
		mVGA_H_SYNC	<=	1;
	end
end

//	V_Sync Generator, Ref. H_Sync
always@(posedge iCLK or negedge iRST_N)
begin
	if(!iRST_N)
	begin
		V_Cont		<=	0;
		mVGA_V_SYNC	<=	0;
	end
	else
	begin
		//	When H_Sync Re-start
		if(H_Cont==0)
		begin
			//	V_Sync Counter
			if( V_Cont < V_SYNC_TOTAL )
			V_Cont	<=	V_Cont+1;
			else
			V_Cont	<=	0;
			//	V_Sync Generator
			if(	V_Cont < V_SYNC_CYC )
			mVGA_V_SYNC	<=	0; //平時為0,到達cycle值時為1
			else
			mVGA_V_SYNC	<=	1;
		end
	end
end

endmodule