module LFSR (
    input        i_clk,
    input        i_rst_n,
    input        i_start,
    output [3:0] o_random_out
);

logic [15:0] random_number;
logic [15:0] random_seed;
integer i;

assign o_random_out = random_number[3:0];

// initial begin
//     random_number = 16'b0;
//     random_seed = 16'b0;
// end

always_ff @(posedge i_clk or negedge i_rst_n) begin
    // reset
    if (!i_rst_n) begin
        random_number <= 16'b0;
        random_seed <= 16'b0;
    end
    else begin
        if (i_start) begin
            if (random_number == 16'b0) begin
                random_number <= random_seed;
            end
            else begin
                random_number <= {random_number[14:0], random_number[10] ^ random_number[12] ^ random_number[13] ^ random_number[15]};
            end
        end
        if (random_seed == 16'b0) begin
            random_seed <= 16'hACE1;
        end
        else begin
            random_seed <= {random_seed[14:0], random_seed[10] ^ random_seed[12] ^ random_seed[13] ^ random_seed[15]};
        end
    end
end

endmodule