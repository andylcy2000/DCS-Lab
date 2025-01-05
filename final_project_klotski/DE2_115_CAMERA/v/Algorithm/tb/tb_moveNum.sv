`timescale 1ns/1ps

module tb_moveNum();

    reg [3:0][3:0][3:0] klotski;
    reg [1:0][1:0] target;
    reg [3:0][3:0] mask;
    reg [3:0] number;
    reg clk;
    reg rst_n;
    reg start;

    wire [3:0][3:0][3:0] o_klotski;
    wire finished;
    parameter MAX_CYCLES = 1000;

    MoveNum uut (
        .i_clk(clk),
        .i_rst_n(rst_n),
        .i_start(start),
        .i_klotski(klotski),
        .i_mask(mask),
        .i_target(target),
        .i_number(number),
        .o_klotski(o_klotski),
        .o_mask(),
        .o_finished(finished)
    );

    // Clock generation
    always #5 clk = ~clk;

    // task verify_output;
    //     input [255:0] x3, y3, z3;
    //     localparam x = 256'h5DC8E95ACC20971BA02DE2460B05D9909A9608021DFB798DBA7394AF98D6A57F;
    //     localparam y = 256'h554AA4BB1B239F79C9AFE0C8FE2AE223A98026ADCF5F3B8667BFA55B000B8881;
    //     localparam z = 256'h69C2DD41EF59BEC7AA8140EF60A6639AAE0C828E81FAEC12BE7068C9640A1AC;
    //     begin
    //         if (x3 == x && y3 == y && z3 == z) begin
    //             $display("Test passed: x3 = %h, y3 = %h, z3 = %h", x3, y3, z3);
    //         end else begin
    //             $display("Test failed: x3 = %h, y3 = %h, z3 = %h", x3, y3, z3);
    //         end
    //     end
    // endtask

    initial begin
        $dumpfile("moveNum.vcd");
        $dumpvars();
    end

    initial begin
        #(MAX_CYCLES * 10);
        $display("Test failed: Timeout");
        $finish;
    end

    // Initialize the simulation
    initial begin
        // Initialize signals
        clk = 0;
        rst_n = 1;
        start = 0;

        // Apply rst_n
        #10 rst_n = 0;
        #10 rst_n = 1;

        // Test case 1
        klotski = {{4'd10,  4'd1, 4'd14, 4'd12},
                    {4'd6,  4'd2,  4'd9, 4'd15},
                    {4'd3,  4'd7,  4'd5,  4'd4},
                   {4'd0, 4'd11,  4'd8,  4'd13}};

        target = {2'd0, 2'd0};
        
        mask = {{1'b0, 1'b0, 1'b0, 1'b0},
                {1'b0, 1'b0, 1'b0, 1'b0},
                {1'b0, 1'b0, 1'b0, 1'b0},
                {1'b0, 1'b0, 1'b0, 1'b0}};
        
        number = 13;

        start = 1;
        #10 start = 0;

        // Wait for the computation to complete
        wait(finished);

        // End simulation
        // verify_output(x3, y3, z3);
        #100;
        $finish;
    end
    

endmodule