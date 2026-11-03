`timescale 1ns / 1ps

// ECE 351 - Week 5, Task 3
// Self-checking testbench for the configurable 3x3 kernel pipeline.
//
// Mode 0: 3x3 square (all 9 pixels)
// Mode 1: 3x3 cross  (top, left, center, right, bottom)
//
// Pixel order in pixels_in[71:0]:
//     P11  P12  P13
//     P21  P22  P23
//     P31  P32  P33
//
// Important: the DUT creates masked pixel buses; it does not yet
// compute the final dilation, erosion, or edge outputs. This
// testbench reduces those buses to check expected results.

module tb_kernel;

    reg         kernel_select;
    reg  [71:0] pixels_in;
    wire [8:0]  kernel_mask;
    wire [71:0] dilation_pixels;
    wire [71:0] erosion_pixels;

    integer tests_run;
    integer tests_failed;

    // DUT = Design Under Test
    kernel_pipeline_3x3 dut (
        .kernel_select   (kernel_select),
        .pixels_in       (pixels_in),
        .kernel_mask     (kernel_mask),
        .dilation_pixels (dilation_pixels),
        .erosion_pixels  (erosion_pixels)
    );

    // Apply a 3x3 matrix and verify the mask, masked output buses,
    // and the expected max/min/edge values obtained from those buses.
    task run_case;
        input [255:0] case_name;
        input         case_mode;
        input [71:0]  case_pixels;
        input [8:0]   expected_mask;
        input [7:0]   expected_max;
        input [7:0]   expected_min;
        input [7:0]   expected_edge;

        reg [71:0] expected_dilation_pixels;
        reg [71:0] expected_erosion_pixels;
        reg [7:0]  actual_max;
        reg [7:0]  actual_min;
        reg [7:0]  actual_edge;
        reg        passed;
        integer    i;

        begin
            kernel_select = case_mode;
            pixels_in     = case_pixels;
            #10;  // Allow combinational outputs to settle.

            tests_run = tests_run + 1;
            passed = 1'b1;

            // Build the expected operand buses independently of DUT outputs.
            // Excluded pixels become 0 for max and 255 for min.
            expected_dilation_pixels = 72'd0;
            expected_erosion_pixels  = {9{8'hFF}};

            for (i = 0; i < 9; i = i + 1) begin
                if (expected_mask[i]) begin
                    expected_dilation_pixels[i*8 +: 8] = case_pixels[i*8 +: 8];
                    expected_erosion_pixels[i*8 +: 8]  = case_pixels[i*8 +: 8];
                end
            end

            if (kernel_mask !== expected_mask) begin
                $display("  ERROR: kernel mask got %b, expected %b",
                         kernel_mask, expected_mask);
                passed = 1'b0;
            end

            if (dilation_pixels !== expected_dilation_pixels) begin
                $display("  ERROR: dilation operand bus does not match expected");
                passed = 1'b0;
            end

            if (erosion_pixels !== expected_erosion_pixels) begin
                $display("  ERROR: erosion operand bus does not match expected");
                passed = 1'b0;
            end

            // Testbench-only max/min/edge calculations.
            // This does NOT mean these arithmetic units exist in the DUT.
            actual_max = 8'd0;
            actual_min = 8'hFF;
            for (i = 0; i < 9; i = i + 1) begin
                if (dilation_pixels[i*8 +: 8] > actual_max)
                    actual_max = dilation_pixels[i*8 +: 8];
                if (erosion_pixels[i*8 +: 8] < actual_min)
                    actual_min = erosion_pixels[i*8 +: 8];
            end
            actual_edge = actual_max - actual_min;

            if ((actual_max  !== expected_max)  ||
                (actual_min  !== expected_min)  ||
                (actual_edge !== expected_edge)) begin
                $display("  ERROR: max/min/edge got %0d/%0d/%0d, expected %0d/%0d/%0d",
                         actual_max, actual_min, actual_edge,
                         expected_max, expected_min, expected_edge);
                passed = 1'b0;
            end

            if (passed) begin
                $display("PASS: %0s (max=%0d, min=%0d, edge=%0d)",
                         case_name, actual_max, actual_min, actual_edge);
            end else begin
                $display("FAIL: %0s", case_name);
                tests_failed = tests_failed + 1;
            end
        end
    endtask

    initial begin
        tests_run    = 0;
        tests_failed = 0;
        kernel_select = 1'b0;
        pixels_in = 72'd0;

        $display("=== ECE 351 - Configurable Kernel Tests ===");

        // 1-2: Mixed pixels. The corner extremes are excluded by CROSS.
        //  0   80  255
        // 40  100   60
        //200  120   10
        run_case("Mixed - square", 1'b0,
                 {8'd0, 8'd80, 8'd255, 8'd40, 8'd100, 8'd60, 8'd200, 8'd120, 8'd10},
                 9'b111_111_111, 8'd255, 8'd0, 8'd255);
        run_case("Mixed - cross", 1'b1,
                 {8'd0, 8'd80, 8'd255, 8'd40, 8'd100, 8'd60, 8'd200, 8'd120, 8'd10},
                 9'b010_111_010, 8'd120, 8'd40, 8'd80);

        // 3-4: Uniform pixels. There must be no morphological edge.
        run_case("Uniform 37 - square", 1'b0,
                 {9{8'd37}}, 9'b111_111_111, 8'd37, 8'd37, 8'd0);
        run_case("Uniform 37 - cross", 1'b1,
                 {9{8'd37}}, 9'b010_111_010, 8'd37, 8'd37, 8'd0);

        // 5-6: Minimum possible 8-bit pixel values.
        run_case("All zero - square", 1'b0,
                 {9{8'd0}}, 9'b111_111_111, 8'd0, 8'd0, 8'd0);
        run_case("All zero - cross", 1'b1,
                 {9{8'd0}}, 9'b010_111_010, 8'd0, 8'd0, 8'd0);

        // 7-8: Maximum possible 8-bit pixel values.
        run_case("All 255 - square", 1'b0,
                 {9{8'd255}}, 9'b111_111_111, 8'd255, 8'd255, 8'd0);
        run_case("All 255 - cross", 1'b1,
                 {9{8'd255}}, 9'b010_111_010, 8'd255, 8'd255, 8'd0);

        // 9-10: Extremes only at corners; CROSS must ignore corners.
        //255   20  240
        // 30  100   40
        //220   50    0
        run_case("Corner extremes - square", 1'b0,
                 {8'd255, 8'd20, 8'd240, 8'd30, 8'd100, 8'd40, 8'd220, 8'd50, 8'd0},
                 9'b111_111_111, 8'd255, 8'd0, 8'd255);
        run_case("Corner extremes - cross", 1'b1,
                 {8'd255, 8'd20, 8'd240, 8'd30, 8'd100, 8'd40, 8'd220, 8'd50, 8'd0},
                 9'b010_111_010, 8'd100, 8'd20, 8'd80);

        // 11-12: Extremes lie inside CROSS; both modes must include them.
        // 10  255   20
        // 30    0   40
        // 50   60   70
        run_case("Cross extremes - square", 1'b0,
                 {8'd10, 8'd255, 8'd20, 8'd30, 8'd0, 8'd40, 8'd50, 8'd60, 8'd70},
                 9'b111_111_111, 8'd255, 8'd0, 8'd255);
        run_case("Cross extremes - cross", 1'b1,
                 {8'd10, 8'd255, 8'd20, 8'd30, 8'd0, 8'd40, 8'd50, 8'd60, 8'd70},
                 9'b010_111_010, 8'd255, 8'd0, 8'd255);

        $display("-------------------------------------------");
        $display("Tests run: %0d", tests_run);
        $display("Tests failed: %0d", tests_failed);
        if (tests_failed == 0)
            $display("ALL KERNEL TESTS PASSED");
        else
            $display("SOME KERNEL TESTS FAILED");
        $finish;
    end

endmodule
