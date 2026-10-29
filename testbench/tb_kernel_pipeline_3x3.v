
`timescale 1ns / 1ps

// ECE 351 - Morphological Edge Detection
// Integration Testbench: Configurable 3x3 Kernel Pipeline
//
// Verifies:
// 1. Square mode
// 2. Cross mode
// 3. Switch transition from cross back to square
// 4. Uniform grayscale pixels
// 5. Zero-valued pixels
// 6. Maximum-valued pixels

module tb_kernel_pipeline_3x3;

    reg         kernel_select;
    reg  [71:0] pixels_in;

    wire [8:0]  kernel_mask;
    wire [71:0] dilation_pixels;
    wire [71:0] erosion_pixels;

    integer tests_run = 0;
    integer tests_failed = 0;

    // Instantiate the complete integration wrapper.
    kernel_pipeline_3x3 dut (
        .kernel_select(kernel_select),
        .pixels_in(pixels_in),
        .kernel_mask(kernel_mask),
        .dilation_pixels(dilation_pixels),
        .erosion_pixels(erosion_pixels)
    );

    // Check the kernel mask and both pixel output buses.
    task check_outputs;
        input [8:0]  expected_mask;
        input [71:0] expected_dilation;
        input [71:0] expected_erosion;
        input [255:0] test_name;

        begin
            tests_run = tests_run + 1;

            if ((kernel_mask === expected_mask) &&
                (dilation_pixels === expected_dilation) &&
                (erosion_pixels === expected_erosion)) begin

                $display("PASS: %0s", test_name);

            end else begin

                $display("FAIL: %0s", test_name);
                $display("  Expected mask: %b", expected_mask);
                $display("  Actual mask:   %b", kernel_mask);
                $display("  Expected dilation: %h", expected_dilation);
                $display("  Actual dilation:   %h", dilation_pixels);
                $display("  Expected erosion:  %h", expected_erosion);
                $display("  Actual erosion:    %h", erosion_pixels);

                tests_failed = tests_failed + 1;
            end
        end
    endtask

    initial begin

        // Test 1: Square kernel, all pixels included.
        pixels_in = {8'd10, 8'd20, 8'd30,
                     8'd40, 8'd50, 8'd60,
                     8'd70, 8'd80, 8'd90};

        kernel_select = 1'b0;
        #10;

        check_outputs(
            9'b111_111_111,
            pixels_in,
            pixels_in,
            "Square kernel integration"
        );

        // Test 2: Switch to cross kernel.
        kernel_select = 1'b1;
        #10;

        check_outputs(
            9'b010_111_010,

            {8'd0, 8'd20, 8'd0,
             8'd40, 8'd50, 8'd60,
             8'd0, 8'd80, 8'd0},

            {8'd255, 8'd20, 8'd255,
             8'd40, 8'd50, 8'd60,
             8'd255, 8'd80, 8'd255},

            "Cross kernel integration"
        );

        // Test 3: Switch back to square.
        kernel_select = 1'b0;
        #10;

        check_outputs(
            9'b111_111_111,
            pixels_in,
            pixels_in,
            "Switch back to square"
        );

        // Test 4: Uniform grayscale window.
        pixels_in = {9{8'd100}};
        kernel_select = 1'b1;
        #10;

        check_outputs(
            9'b010_111_010,

            {8'd0, 8'd100, 8'd0,
             8'd100, 8'd100, 8'd100,
             8'd0, 8'd100, 8'd0},

            {8'd255, 8'd100, 8'd255,
             8'd100, 8'd100, 8'd100,
             8'd255, 8'd100, 8'd255},

            "Uniform grayscale window"
        );

        // Test 5: All pixels equal zero.
        pixels_in = 72'd0;
        kernel_select = 1'b1;
        #10;

        check_outputs(
            9'b010_111_010,
            72'd0,

            {8'd255, 8'd0, 8'd255,
             8'd0, 8'd0, 8'd0,
             8'd255, 8'd0, 8'd255},

            "Zero-valued pixels"
        );

        // Test 6: All pixels equal 255.
        pixels_in = {9{8'hFF}};
        kernel_select = 1'b1;
        #10;

        check_outputs(
            9'b010_111_010,

            {8'd0, 8'd255, 8'd0,
             8'd255, 8'd255, 8'd255,
             8'd0, 8'd255, 8'd0},

            {9{8'hFF}},

            "Maximum-valued pixels"
        );

        $display("--------------------------------");
        $display("Integration tests run: %0d", tests_run);
        $display("Integration tests failed: %0d", tests_failed);

        if (tests_failed == 0)
            $display("ALL KERNEL INTEGRATION TESTS PASSED");
        else
            $display("KERNEL INTEGRATION TESTS FAILED");

        $finish;
    end

endmodule
