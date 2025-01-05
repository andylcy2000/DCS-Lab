module Rsa256Wrapper (
    input         avm_rst,
    input         avm_clk,
    output  [4:0] avm_address,
    output        avm_read,
    input  [31:0] avm_readdata,
    output        avm_write,
    output [31:0] avm_writedata,
    input         avm_waitrequest
);

localparam RX_BASE     = 0*4;
localparam TX_BASE     = 1*4;
localparam STATUS_BASE = 2*4;
localparam TX_OK_BIT   = 6;
localparam RX_OK_BIT   = 7;

// Feel free to design your own FSM!
localparam S_IDLE = 4;
localparam S_GET_KEY = 0;
localparam S_GET_DATA = 1;
localparam S_WAIT_CALCULATE = 2;
localparam S_SEND_DATA = 3;

logic [255:0] n_r, n_w, d_r, d_w, enc_r, enc_w, dec_r, dec_w;
logic [2:0] state_r, state_w;
logic [6:0] bytes_counter_r, bytes_counter_w;
logic [4:0] avm_address_r, avm_address_w;
logic avm_read_r, avm_read_w, avm_write_r, avm_write_w;

logic rsa_start_r, rsa_start_w;
logic rsa_finished;
logic [255:0] rsa_dec;

logic rrdy_r, rrdy_w, trdy_r, trdy_w;

assign avm_address = avm_address_r;
assign avm_read = avm_read_r;
assign avm_write = avm_write_r;
assign avm_writedata = dec_r[(30-bytes_counter_r)*8+:8];

Rsa256Core rsa256_core(
    .i_clk(avm_clk),
    .i_rst(avm_rst),
    .i_start(rsa_start_r),
    .i_a(enc_r),
    .i_d(d_r),
    .i_n(n_r),
    .o_a_pow_d(rsa_dec),
    .o_finished(rsa_finished)
);

task StartRead;
    input [4:0] addr;
    begin
        avm_read_w = 1;
        avm_write_w = 0;
        avm_address_w = addr;
    end
endtask
task StartWrite;
    input [4:0] addr;
    begin
        avm_read_w = 0;
        avm_write_w = 1;
        avm_address_w = addr;
    end
endtask

always_comb begin
    // TODO
    n_w = n_r;
    d_w = d_r;
    enc_w = enc_r;
    dec_w = dec_r;
    bytes_counter_w = bytes_counter_r;
    rrdy_w = rrdy_r;
    trdy_w = trdy_r;
    rsa_start_w = 0;
    avm_address_w = avm_address_r;
    state_w = state_r;
    avm_read_w = avm_read_r;
    avm_write_w = avm_write_r;
    case (state_r)
        S_IDLE: begin
            state_w = S_GET_KEY;
            StartRead(STATUS_BASE);
        end
        S_GET_KEY: begin
            if (!avm_waitrequest) begin
                if (bytes_counter_r < 32) begin
                    if (~rrdy_r) begin
                        rrdy_w = avm_readdata[RX_OK_BIT];
                        if (rrdy_w) begin
                            StartRead(RX_BASE);
                        end
                    end else begin
                        n_w[(31-bytes_counter_r)*8 +: 8] = avm_readdata[7:0];
                        bytes_counter_w = bytes_counter_r + 1;
                        StartRead(STATUS_BASE);
                        rrdy_w = 0;
                    end
                end else if (bytes_counter_r < 64) begin
                    if (~rrdy_r) begin
                        rrdy_w = avm_readdata[RX_OK_BIT];
                        if (rrdy_w) begin
                            StartRead(RX_BASE);
                        end
                    end else begin
                        d_w[(31-(bytes_counter_r-32))*8 +: 8] = avm_readdata[7:0];
                        bytes_counter_w = bytes_counter_r + 1;
                        StartRead(STATUS_BASE);
                        rrdy_w = 0;
                    end
                end else begin
                    state_w = S_GET_DATA;
                    rrdy_w = 0;
                    bytes_counter_w = 0;
                end
            end
        end
        S_GET_DATA:begin
            if (!avm_waitrequest) begin
                if (bytes_counter_r < 32) begin
                    if (~rrdy_r) begin
                        rrdy_w = avm_readdata[RX_OK_BIT];
                        if (rrdy_w) begin
                            StartRead(RX_BASE);
                        end
                    end else begin
                        enc_w[(31-bytes_counter_r)*8 +: 8] = avm_readdata[7:0];
                        bytes_counter_w = bytes_counter_r + 1;
                        StartRead(STATUS_BASE);
                        rrdy_w = 0;
                    end
                end else begin
                    state_w = S_WAIT_CALCULATE;
                    rrdy_w = 0;
                    bytes_counter_w = 0;
                    rsa_start_w = 1;
                end
            end
            // //get rrdy
            // if(avm_waitrequest) begin
            //     avm_read_w = 1;
            // end
            // if(!avm_waitrequest) begin
            //     /*
            //     if (bytes_counter_r == 0) begin
            //         //avm_address_w = STATUS_BASE;
            //         if(!rrdy_r) begin
            //             StartRead(STATUS_BASE);
            //         end
            //         else begin //rrdy == 1
                        
            //         end
                    
                    
            //     end
            //     */
            //     if (bytes_counter_r < 32) begin // not yet finish reading
            //         StartRead(STATUS_BASE);
            //         if(!rrdy_r) begin
            //             rrdy_w = avm_readdata[RX_OK_BIT];
            //             if(rrdy_w) begin
            //                 StartRead(RX_BASE); // next step: receive decoded data
            //             end
            //         end
            //         else begin //rrdy == 1 and read
            //             enc_w[bytes_counter_r*8 +:8] = avm_readdata[7:0];
            //             bytes_counter_w = bytes_counter_r + 1;
            //             rrdy_w = 0; //switch back to check status
            //             StartRead(STATUS_BASE);
            //         end
            //         state_w = S_GET_DATA;
            //     end
            //     else begin //finish reading
            //         state_w = S_WAIT_CALCULATE;
            //         bytes_counter_w = 0;
            //         rsa_start_w = 1;
            //     end
            // end
        end

        S_WAIT_CALCULATE: begin
            if (rsa_finished) begin
                state_w = S_SEND_DATA;
                dec_w = rsa_dec;
            end
        end
        S_SEND_DATA: begin
            if(~avm_waitrequest) begin
                if (bytes_counter_r < 31) begin
                    if (~trdy_r) begin
                        trdy_w = avm_readdata[TX_OK_BIT];
                        if (trdy_w) begin
                            StartWrite(TX_BASE);
                        end
                    end else begin
                        bytes_counter_w = bytes_counter_r + 1;
                        StartRead(STATUS_BASE);
                        trdy_w = 0;
                    end
                end else begin
                    state_w = S_GET_DATA;
                    bytes_counter_w = 0;
                    trdy_w = 0;
                    StartRead(STATUS_BASE);
                end
            end
        end
    endcase
end

always_ff @(posedge avm_clk or posedge avm_rst) begin
    if (avm_rst) begin
        n_r <= 0;
        d_r <= 0;
        enc_r <= 0;
        dec_r <= 0;
        avm_address_r <= STATUS_BASE;
        avm_read_r <= 0;
        avm_write_r <= 0;
        state_r <= S_IDLE;
        bytes_counter_r <= 0;
        rsa_start_r <= 0;
        rrdy_r <= 0;
        trdy_r <= 0;
    end else begin
        n_r <= n_w;
        d_r <= d_w;
        enc_r <= enc_w;
        dec_r <= dec_w;
        avm_address_r <= avm_address_w;
        avm_read_r <= avm_read_w;
        avm_write_r <= avm_write_w;
        state_r <= state_w;
        bytes_counter_r <= bytes_counter_w;
        rsa_start_r <= rsa_start_w;
        rrdy_r <= rrdy_w;
        trdy_r <= trdy_w;
    end
end

endmodule
