
`timescale 1ns / 1ps

// ECE 351 - Week 7, Task 3
// Option C - Edge ALU Timing Verification
//
// Tests:
// 1. One registered output stage
// 2. Consecutive valid input cycles
// 3. Invalid cycles and valid recovery
// 4. Synchronous reset
// 5. Gradient and output pixel alignment
// 6. Threshold boundary behavior

module tb_edge_timing;

    // Clock: 10 ns period (100 MHz)
    reg clk = 0;
    always #5 clk = ~clk;

    // Control signals
    reg reset = 1;
    reg valid_in = 0;
    reg is_border = 0;

    // Five pixels used by Option C
    reg [7:0] p01 = 0;
    reg [7:0] p10 = 0;
    reg [7:0] p11 = 0;
    reg [7:0] p12 = 0;
    reg [7:0] p21 = 0;

    // Switch controls
    reg [7:0] threshold = 0;
    reg invert_en = 0;
    reg bypass_en = 0;

    // Hardware outputs
    wire [8:0] gradient_out;
    wire [7:0] pixel_out;
    wire valid_out;

    // Test counters
    integer tests_run = 0;
    integer tests_failed = 0;

    // Remember outputs from the previous clock cycle.
    reg [8:0] previous_gradient;
    reg [7:0] previous_pixel;
    reg previous_valid;

    // Instantiate our existing ALU.
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

    // -----------------------------------------
    // Test one clock cycle.
    // -----------------------------------------
    task check_cycle;
        input [8*48-1:0] test_name;

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

        input [8:0] expected_gradient;
        input [7:0] expected_pixel;

        reg changed_early;

        begin
            // Apply new inputs on the falling edge.
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

            // Registered outputs must NOT change
            // before the next rising clock edge.
            #1;
            changed_early =
                (gradient_out !== previous_gradient) ||
                (pixel_out !== previous_pixel) ||
                (valid_out !== previous_valid);

            // The ALU captures inputs on this edge.
            @(posedge clk);
            #1;

            tests_run = tests_run + 1;

            // Check gradient, pixel, and valid together.
            if (changed_early ||
                gradient_out !== expected_gradient ||
                pixel_out !== expected_pixel ||
                valid_out !== test_valid) begin

                tests_failed = tests_failed + 1;

                $display("FAIL: %0s", test_name);
                $display("Expected: G=%0d P=%0d V=%0b",
                         expected_gradient, expected_pixel,
                         test_valid);
                $display("Actual:   G=%0d P=%0d V=%0b",
                         gradient_out, pixel_out, valid_out);
                if (changed_early)
                    $display("ERROR: Output changed before clock edge");
            end
            else begin
                $display("PASS: %0s (G=%0d P=%0d V=%0b)",
                         test_name, gradient_out,
                         pixel_out, valid_out);
            end

            // Save outputs for the next cycle's check.
            previous_gradient = gradient_out;
            previous_pixel = pixel_out;
            previous_valid = valid_out;
        end
    endtask

    // -----------------------------------------
    // Run all timing tests.
    // -----------------------------------------
    initial begin

        // Test initial synchronous reset.
        @(posedge clk);
        #1;

        tests_run = tests_run + 1;

        if (gradient_out !== 0 ||
            pixel_out !== 0 ||
            valid_out !== 0) begin
            tests_failed = tests_failed + 1;
            $display("FAIL: Initial reset");
        end
        else
            $display("PASS: Initial reset");

        previous_gradient = gradient_out;
        previous_pixel = pixel_out;
        previous_valid = valid_out;

        // Back-to-back valid cycles.
        // Inputs: top, left, center, right, bottom,
        // threshold, invert, bypass, border, valid,
        // expected gradient, expected pixel.

        check_cycle("Uniform", 
            100,100,100,100,100,
            0, 0,0,0,1, 0,0);

        check_cycle("Horizontal edge",
            250,70,100,70,10,
            100, 0,0,0,1, 240,255);

        check_cycle("Vertical edge",
            70,200,100,10,70,
            100, 0,0,0,1, 190,255);

        // Invalid cycle must clear valid_out.
        check_cycle("Invalid cycle",
            250,70,100,70,10,
            100, 0,0,0,0, 0,0);

        // Valid processing resumes.
        check_cycle("Valid recovery",
            51,50,50,50,50,
            0, 0,0,0,1, 1,255);

        // G = T must produce zero.
        check_cycle("Gradient equals threshold",
            100,80,90,40,50,
            90, 0,0,0,1, 90,0);

        // G = T + 1 must detect an edge.
        check_cycle("Gradient exceeds threshold",
            100,80,90,40,50,
            89, 0,0,0,1, 90,255);

        // Maximum gradient requires 9 bits.
        check_cycle("Maximum gradient",
            255,255,100,0,0,
            255, 0,0,0,1, 510,255);

        // Threshold 255 is still a strict comparison.
        check_cycle("Gradient 255 threshold 255",
            255,0,50,0,0,
            255, 0,0,0,1, 255,0);

        // Optional inversion.
        check_cycle("Invert no edge",
            50,50,50,50,50,
            100, 1,0,0,1, 0,255);

        // Bypass followed by inversion.
        check_cycle("Inverted grayscale bypass",
            250,70,165,70,10,
            100, 1,1,0,1, 240,90);

        // Border suppression in edge mode.
        check_cycle("Border suppression",
            250,70,100,70,10,
            100, 0,0,1,1, 240,0);

        // Test reset after valid processing.
        @(negedge clk);
        reset = 1;
        valid_in = 1;

        // Reset is synchronous, so outputs
        // must remain unchanged until posedge.
        #1;
        if (gradient_out !== previous_gradient ||
            pixel_out !== previous_pixel ||
            valid_out !== previous_valid) begin
            tests_failed = tests_failed + 1;
            $display("FAIL: Reset changed output early");
        end

        @(posedge clk);
        #1;

        tests_run = tests_run + 1;

        if (gradient_out !== 0 ||
            pixel_out !== 0 ||
            valid_out !== 0) begin
            tests_failed = tests_failed + 1;
            $display("FAIL: Reset after activity");
        end
        else
            $display("PASS: Reset after activity");

        previous_gradient = gradient_out;
        previous_pixel = pixel_out;
        previous_valid = valid_out;

        // Check recovery after reset.
        check_cycle("Recovery after reset",
            100,80,90,40,50,
            89, 0,0,0,1, 90,255);

        // Final summary.
        $display("==============================");
        $display("WEEK 7 TASK 3 TIMING RESULTS");
        $display("Tests run: %0d", tests_run);
        $display("Tests failed: %0d", tests_failed);

        if (tests_failed == 0)
            $display("PASS: ALL TIMING TESTS PASSED");
        else
            $fatal(1, "TIMING VERIFICATION FAILED");

        $display("==============================");
        $finish;
    end

endmodule
