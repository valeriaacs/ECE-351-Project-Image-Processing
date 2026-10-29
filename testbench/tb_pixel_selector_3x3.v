
`timescale 1ns / 1ps

// ECE 351 - Morphological Edge Detection
// Testbench for the 3x3 pixel selector
//
// Verifies square and cross kernel selection,
// including zero, maximum, and uniform pixels.

module tb_pixel_selector_3x3;

    reg  [71:0] pixels_in;
    reg  [8:0]  kernel_mask;

    wire [71:0] dilation_pixels;
    wire [71:0] erosion_pixels;

    integer tests_run = 0;
    integer tests_failed = 0;

    // Device Under Test (DUT)
    pixel_selector_3x3 dut (
        .pixels_in(pixels_in),
        .kernel_mask(kernel_mask),
        .dilation_pixels(dilation_pixels),
        .erosion_pixels(erosion_pixels)
    );

    // Check both 72-bit output buses
    task check_outputs;
        input [71:0] expected_dilation;
        input [71:0] expected_erosion;
        input [255:0] test_name;
        begin
            tests_run = tests_run + 1;

            if ((dilation_pixels === expected_dilation) &&
                (erosion_pixels === expected_erosion))
                $display("PASS: %0s", test_name);
            else begin
                $display("FAIL: %0s", test_name);
                $display("  Dilation expected: %h", expected_dilation);
                $display("  Dilation actual:   %h", dilation_pixels);
                $display("  Erosion expected:  %h", expected_erosion);
                $display("  Erosion actual:    %h", erosion_pixels);
                tests_failed = tests_failed + 1;
            end
        end
    endtask

    initial begin

        // Test 1: Square mask includes all pixels.
        pixels_in = {8'd10, 8'd20, 8'd30,
                     8'd40, 8'd50, 8'd60,
                     8'd70, 8'd80, 8'd90};
        kernel_mask = 9'b111_111_111;
        #10;

        check_outputs(pixels_in, pixels_in,
                      "Square mask: all pixels");

        // Test 2: Cross mask excludes four corners.
        kernel_mask = 9'b010_111_010;
        #10;

        check_outputs(
            {8'd0, 8'd20, 8'd0,
             8'd40, 8'd50, 8'd60,
             8'd0, 8'd80, 8'd0},

            {8'd255, 8'd20, 8'd255,
             8'd40, 8'd50, 8'd60,
             8'd255, 8'd80, 8'd255},

            "Cross mask: corner exclusion"
        );

        // Test 3: All input pixels are zero.
        pixels_in = 72'd0;
        kernel_mask = 9'b010_111_010;
        #10;

        check_outputs(
            72'd0,
            {8'd255, 8'd0, 8'd255,
             8'd0, 8'd0, 8'd0,
             8'd255, 8'd0, 8'd255},
            "Cross mask: zero pixels"
        );

        // Test 4: All input pixels are 255.
        pixels_in = {9{8'hFF}};
        kernel_mask = 9'b010_111_010;
        #10;

        check_outputs(
            {8'd0, 8'd255, 8'd0,
             8'd255, 8'd255, 8'd255,
             8'd0, 8'd255, 8'd0},
            {9{8'hFF}},
            "Cross mask: maximum pixels"
        );

        // Test 5: Uniform matrix of 100.
        pixels_in = {9{8'd100}};
        kernel_mask = 9'b010_111_010;
        #10;

        check_outputs(
            {8'd0, 8'd100, 8'd0,
             8'd100, 8'd100, 8'd100,
             8'd0, 8'd100, 8'd0},
            {8'd255, 8'd100, 8'd255,
             8'd100, 8'd100, 8'd100,
             8'd255, 8'd100, 8'd255},
            "Cross mask: uniform pixels"
        );

        $display("----------------------------");
        $display("Tests run: %0d", tests_run);
        $display("Tests failed: %0d", tests_failed);

        if (tests_failed == 0)
            $display("ALL PIXEL SELECTOR TESTS PASSED");
        else
            $display("PIXEL SELECTOR TESTS FAILED");

        $finish;
    end

endmodule
