
`timescale 1ns / 1ps

// ECE 351 - Week 6, Task 3
// Option C Edge Threshold ALU Testbench
//
// Tests the Manhattan gradient:
// G = |p01 - p21| + |p10 - p12|
//
// Verifies gradient, threshold, inversion,
// bypass, borders, reset, and valid timing.

module tb_edge_alu;

    // Clock and control inputs
    reg clk = 0;
    reg reset = 1;
    reg valid_in = 0;
    reg is_border = 0;

    // The five pixels needed by the ALU
    reg [7:0] p01 = 0;
    reg [7:0] p10 = 0;
    reg [7:0] p11 = 0;
    reg [7:0] p12 = 0;
    reg [7:0] p21 = 0;

    // Switch-controlled inputs
    reg [7:0] threshold = 0;
    reg invert_en = 0;
    reg bypass_en = 0;

    // Hardware outputs
    wire [8:0] gradient_out;
    wire [7:0] pixel_out;
    wire valid_out;

    // Test result counters
    integer tests_run = 0;
    integer tests_failed = 0;

    // Clock period: 10 ns
    always #5 clk = ~clk;

    // Instantiate the module being tested
    edge_threshold_alu uut (
        .clk(clk),
        .reset(reset),
        .valid_in(valid_in),
        .is_border(is_border),

        .p01(p01),
        .p10(p10),
        .p11(p11),
        .p12(p12),
        .p21(p21),

        .threshold(threshold),
        .invert_en(invert_en),
        .bypass_en(bypass_en),

        .gradient_out(gradient_out),
        .pixel_out(pixel_out),
        .valid_out(valid_out)
    );

    // ----------------------------------------
    // Automatic test procedure
    // ----------------------------------------
    //
    // Each test sends input pixels and controls,
    // calculates the expected result independently,
    // and compares it with the Verilog ALU output.

    task check_case;
        input [8*40-1:0] test_name;

        input [7:0] top_px;
        input [7:0] left_px;
        input [7:0] center_px;
        input [7:0] right_px;
        input [7:0] bottom_px;

        input [7:0] test_threshold;
        input test_invert;
        input test_bypass;
        input test_border;
        input test_valid;

        integer vertical_difference;
        integer horizontal_difference;

        reg [8:0] expected_gradient;
        reg [7:0] expected_pixel;

        begin

            // Apply inputs before the rising edge.
            @(negedge clk);

            reset = 0;
            valid_in = test_valid;
            is_border = test_border;

            p01 = top_px;
            p10 = left_px;
            p11 = center_px;
            p12 = right_px;
            p21 = bottom_px;

            threshold = test_threshold;
            invert_en = test_invert;
            bypass_en = test_bypass;

            // Calculate expected vertical difference.
            if (top_px >= bottom_px)
                vertical_difference = top_px - bottom_px;
            else
                vertical_difference = bottom_px - top_px;

            // Calculate expected horizontal difference.
            if (left_px >= right_px)
                horizontal_difference = left_px - right_px;
            else
                horizontal_difference = right_px - left_px;

            // Software-style reference gradient.
            expected_gradient =
                vertical_difference + horizontal_difference;

            // Strict threshold comparison.
            if (expected_gradient > test_threshold)
                expected_pixel = 8'hFF;
            else
                expected_pixel = 8'h00;

            // Apply bypass, then inversion.
            if (test_bypass)
                expected_pixel = center_px;

            if (test_invert)
                expected_pixel = ~expected_pixel;

            // Suppress borders in edge mode.
            if (test_border && !test_bypass)
                expected_pixel = 8'h00;

            // Invalid cycles output zero.
            if (!test_valid) begin
                expected_gradient = 9'd0;
                expected_pixel = 8'h00;
            end

            // Wait for registered hardware outputs.
            @(posedge clk);
            #1;

            tests_run = tests_run + 1;

            // Compare all three hardware outputs.
            if (gradient_out !== expected_gradient ||
                pixel_out !== expected_pixel ||
                valid_out !== test_valid) begin

                tests_failed = tests_failed + 1;

                $display("FAIL: %0s", test_name);
                $display("Expected gradient=%0d pixel=%0d valid=%0b",
                         expected_gradient, expected_pixel,
                         test_valid);
                $display("Actual   gradient=%0d pixel=%0d valid=%0b",
                         gradient_out, pixel_out, valid_out);

            end
            else begin
                $display("PASS: %0s (G=%0d, pixel=%0d)",
                         test_name, gradient_out, pixel_out);
            end
        end
    endtask

    // ----------------------------------------
    // Execute verification cases
    // ----------------------------------------

    initial begin

        // Check synchronous reset.
        @(posedge clk);
        #1;
        tests_run = tests_run + 1;

        if (gradient_out !== 9'd0 ||
            pixel_out !== 8'd0 ||
            valid_out !== 1'b0) begin
            tests_failed = tests_failed + 1;
            $display("FAIL: Initial reset");
        end
        else
            $display("PASS: Initial reset");

        // Pixels: top, left, center, right, bottom
        // Controls: threshold, invert, bypass,
        //           border, valid

        check_case("Uniform pixels",
                   100,100,100,100,100,
                   0, 0,0,0,1);

        check_case("Horizontal edge",
                   250,70,100,70,10,
                   100, 0,0,0,1);

        check_case("Vertical edge",
                   70,200,100,10,70,
                   100, 0,0,0,1);

        check_case("Maximum gradient 510",
                   255,255,100,0,0,
                   255, 0,0,0,1);

        check_case("Gradient equals threshold",
                   100,80,90,40,50,
                   90, 0,0,0,1);

        check_case("Gradient exceeds threshold by 1",
                   100,80,90,40,50,
                   89, 0,0,0,1);

        check_case("Zero gradient zero threshold",
                   50,50,50,50,50,
                   0, 0,0,0,1);

        check_case("Gradient 1 threshold 0",
                   51,50,50,50,50,
                   0, 0,0,0,1);

        check_case("Invert detected edge",
                   250,70,100,70,10,
                   100, 1,0,0,1);

        check_case("Invert no-edge output",
                   50,50,50,50,50,
                   100, 1,0,0,1);

        check_case("Grayscale bypass",
                   250,70,165,70,10,
                   100, 0,1,0,1);

        check_case("Inverted grayscale bypass",
                   250,70,165,70,10,
                   100, 1,1,0,1);

        check_case("Border suppression",
                   250,70,100,70,10,
                   100, 0,0,1,1);

        check_case("Border with inversion",
                   250,70,100,70,10,
                   100, 1,0,1,1);

        check_case("Border with grayscale bypass",
                   250,70,165,70,10,
                   100, 0,1,1,1);

        check_case("Invalid input cycle",
                   250,70,100,70,10,
                   100, 0,0,0,0);

        // Verify synchronous reset again after activity.
        @(negedge clk);
        reset = 1;
        valid_in = 1;

        @(posedge clk);
        #1;

        tests_run = tests_run + 1;

        if (gradient_out !== 9'd0 ||
            pixel_out !== 8'd0 ||
            valid_out !== 1'b0) begin
            tests_failed = tests_failed + 1;
            $display("FAIL: Reset after activity");
        end
        else
            $display("PASS: Reset after activity");

        // ----------------------------------------
        // Final verification summary
        // ----------------------------------------

        $display("==============================");
        $display("WEEK 6 TASK 3 - EDGE ALU RESULTS");
        $display("Tests run: %0d", tests_run);
        $display("Tests failed: %0d", tests_failed);

        if (tests_failed == 0)
            $display("PASS: ALL EDGE ALU TESTS PASSED");
        else
            $fatal(1, "FAIL: EDGE ALU VERIFICATION FAILED");

        $display("==============================");
        $finish;

    end

endmodule
