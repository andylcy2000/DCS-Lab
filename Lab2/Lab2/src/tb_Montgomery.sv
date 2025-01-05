`timescale 1ns/1ps

module tb_Montgomery();

    // Inputs to the Montgomery module
    reg [255:0] N;
    reg [511:0] a;
    reg [255:0] a_prime;
    reg [255:0] b;
    reg clk;
    reg reset;
    reg start;

    // Output from the Montgomery module
    wire [255:0] result;
    wire ready;
    parameter MAX_CYCLES = 1000;

    // Instantiate the Montgomery module (assuming it has these ports)
    Montgomery uut (
        .i_N(N),
        .i_a(a_prime),
        .i_b(b),
        .i_clk(clk),
        .i_rst(reset),
        .i_start(start),
        .o_montgomery(result),
        .o_finished(ready)
    );

    // Clock generation
    always #5 clk = ~clk;

    // Task to check if the output is correct
    task verify_output;
        input [255:0] a, b, N;
        logic [511:0] tmp [0:256];
        logic [255:0] expected_result;
        begin
            tmp[0] = (a * b) % N;
            for (int i = 1; i < 257; i = i + 1) begin
                tmp[i] = (tmp[i - 1] * ((N >> 1) + 1)) % N;
            end
            expected_result = tmp[256];
        end
        begin
            if (result == expected_result) begin
                $display("Test passed: a = %h, b = %h, N = %h, result = %h", a, b, N, result);
            end else begin
                $display("Test failed: a = %h, b = %h, N = %h, result = %h, expected = %h", a, b, N, result, expected_result);
            end
        end
    endtask

    initial begin
        $dumpfile("waveform.vcd");
        $dumpvars(0, tb_Montgomery);
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
        reset = 1;
        start = 0;

        // Apply reset
        #10 reset = 0;
        #10 reset = 1;

        // Test case 1
        a = 256'h123456789ABCDEF123456789ABCDEF123456789ABCDEF123456789ABCDEF1234;
        b = 256'hFEDCBA9876543210FEDCBA9876543210FEDCBA9876543210FEDCBA9876543210;
        N = 256'h1000000000000000000000000000000000000000000000000000000000000001;
        a_prime = (a << 256) % N;
        #5 start = 1;
        #10 start = 0;

        // Wait for the computation to complete
        wait(ready);

        // Verify result using expected value for (a * b) mod N
        verify_output(a_prime, b, N);

        // Test case 2
        a = 256'h1;
        b = 256'h2;
        N = 256'h3;
        // a_prime = (a << 256) % N;
        a_prime = (a << 256) % N;
        #5 start = 1;
        #10 start = 0;

        // Wait for the computation to complete
        wait(ready);

        // Verify result using expected value for (a * b) mod N
        verify_output(a_prime, b, N);

        // Add more test cases here...

        // End simulation
        #100;
        $finish;
    end
    

endmodule
