`timescale 1ns / 1ps

// ECE 351 - Image Edge Detection
// Self-checking testbench for edge_threshold_alu
// Four-stage Sobel + Manhattan pipeline
// Target: Digilent Basys 3
// Clock frequency: 25 MHz

module tb_edge_alu;

    // ========================================
    // DUT inputs and outputs
    // ========================================

    reg         pixel_clk;
    reg         reset;
    reg         input_valid;
    reg  [71:0] pixels_in;
    reg  [7:0]  threshold;
    reg         invert;

    wire [7:0]  edge_pixel;
    wire        output_valid;

    // ========================================
    // Test counters
    // ========================================

    integer tests_run;
    integer tests_failed;
    integer cycles_checked;

    // ========================================
    // Expected pipeline results
    // ========================================

    reg [3:0] expected_valid;

    reg [7:0] expected_pixel [0:3];

    integer expected_gx [0:3];
    integer expected_gy [0:3];
    integer expected_magnitude [0:3];

    integer i;
    integer gx_ref;
    integer gy_ref;
    integer magnitude_ref;
    integer abs_gx_ref;
    integer abs_gy_ref;

    reg edge_ref;

    // ========================================
    // Design Under Test
    // ========================================

    edge_threshold_alu dut (
        .pixel_clk    (pixel_clk),
        .reset        (reset),
        .input_valid  (input_valid),
        .pixels_in    (pixels_in),
        .threshold    (threshold),
        .invert       (invert),
        .edge_pixel   (edge_pixel),
        .output_valid (output_valid)
    );

    // ========================================
    // 25 MHz clock generation
    // Period = 40 ns
    // ========================================

    initial pixel_clk = 1'b0;

    always #20 pixel_clk = ~pixel_clk;

    // ========================================
    // Independent Sobel reference model
    // and pipeline scoreboard
    // ========================================

    always @(posedge pixel_clk) begin

        if (reset) begin

            expected_valid = 4'b0000;

            for (i = 0; i < 4; i = i + 1) begin
                expected_pixel[i]     = 8'd0;
                expected_gx[i]        = 0;
                expected_gy[i]        = 0;
                expected_magnitude[i] = 0;
            end

        end else begin

            // Advance expected pipeline results.

            for (i = 3; i > 0; i = i - 1) begin

                expected_valid[i] =
                    expected_valid[i-1];

                expected_pixel[i] =
                    expected_pixel[i-1];

                expected_gx[i] =
                    expected_gx[i-1];

                expected_gy[i] =
                    expected_gy[i-1];

                expected_magnitude[i] =
                    expected_magnitude[i-1];

            end

            // Horizontal Sobel gradient.

            gx_ref =
                  pixels_in[55:48]
                + 2 * pixels_in[31:24]
                + pixels_in[7:0]
                - pixels_in[71:64]
                - 2 * pixels_in[47:40]
                - pixels_in[23:16];

            // Vertical Sobel gradient.

            gy_ref =
                  pixels_in[23:16]
                + 2 * pixels_in[15:8]
                + pixels_in[7:0]
                - pixels_in[71:64]
                - 2 * pixels_in[63:56]
                - pixels_in[55:48];

            // Absolute values.

            abs_gx_ref =
                (gx_ref < 0) ? -gx_ref : gx_ref;

            abs_gy_ref =
                (gy_ref < 0) ? -gy_ref : gy_ref;

            // Manhattan magnitude.

            magnitude_ref =
                abs_gx_ref + abs_gy_ref;

            // Threshold comparison.

            edge_ref =
                (magnitude_ref > (8 * threshold));

            // Optional inversion.

            edge_ref = edge_ref ^ invert;

            // Insert new expected result.

            expected_valid[0] = input_valid;

            expected_pixel[0] =
                edge_ref ? 8'hFF : 8'h00;

            expected_gx[0] = gx_ref;
            expected_gy[0] = gy_ref;

            expected_magnitude[0] =
                magnitude_ref;

        end

        // Allow DUT nonblocking assignments
        // to complete before checking results.

        #1;

        cycles_checked = cycles_checked + 1;

        // ====================================
        // Check output_valid every clock
        // ====================================

        if (output_valid !== expected_valid[3]) begin

            $display(
                "FAIL: Valid mismatch at time %0t",
                $time
            );

            tests_failed = tests_failed + 1;

        end

        // ====================================
        // Check Stage 2 signed gradients
        // ====================================

        if (expected_valid[1]) begin

            if (($signed(dut.gx_s2)
                    !== expected_gx[1]) ||
                ($signed(dut.gy_s2)
                    !== expected_gy[1])) begin

                $display(
                    "FAIL: Sobel gradient mismatch"
                );

                $display(
                    "  Gx: got %0d, expected %0d",
                    $signed(dut.gx_s2),
                    expected_gx[1]
                );

                $display(
                    "  Gy: got %0d, expected %0d",
                    $signed(dut.gy_s2),
                    expected_gy[1]
                );

                tests_failed = tests_failed + 1;

            end

        end

        // ====================================
        // Check Stage 3 Manhattan magnitude
        // ====================================

        if (expected_valid[2]) begin

            if (dut.magnitude_s3
                    !== expected_magnitude[2]) begin

                $display(
                    "FAIL: Manhattan magnitude mismatch"
                );

                $display(
                    "  Got %0d, expected %0d",
                    dut.magnitude_s3,
                    expected_magnitude[2]
                );

                tests_failed = tests_failed + 1;

            end

        end

        // ====================================
        // Check Stage 4 final output
        // ====================================

        if (expected_valid[3]) begin

            tests_run = tests_run + 1;

            if ((edge_pixel !== expected_pixel[3]) ||
                (output_valid !== 1'b1)) begin

                $display(
                    "FAIL: Output pixel mismatch"
                );

                $display(
                    "  Got %0d, expected %0d",
                    edge_pixel,
                    expected_pixel[3]
                );

                tests_failed = tests_failed + 1;

            end else begin

                $display(
                    "PASS: Test %0d | Gx=%0d Gy=%0d G=%0d | Edge=%0d",
                    tests_run,
                    expected_gx[3],
                    expected_gy[3],
                    expected_magnitude[3],
                    edge_pixel
                );

            end

        end else begin

            // Invalid output cycles must be black.

            if (edge_pixel !== 8'h00) begin

                $display(
                    "FAIL: Nonzero pixel during invalid cycle"
                );

                tests_failed = tests_failed + 1;

            end

        end

    end

    // ========================================
    // Task: send a pixel window
    // ========================================

    task send_window;

        input [71:0] window_data;
        input [7:0]  threshold_data;
        input        invert_data;
        input        valid_data;

        begin

            // Drive inputs on the falling edge
            // to avoid simulation race conditions.

            @(negedge pixel_clk);

            pixels_in   = window_data;
            threshold   = threshold_data;
            invert      = invert_data;
            input_valid = valid_data;

        end

    endtask

    // ========================================
    // Test stimulus
    // ========================================

    initial begin

        tests_run      = 0;
        tests_failed   = 0;
        cycles_checked = 0;

        reset       = 1'b1;
        input_valid = 1'b0;
        pixels_in   = 72'd0;
        threshold   = 8'd0;
        invert      = 1'b0;

        $display("========================================");
        $display(" ECE 351 - Sobel Manhattan ALU Tests");
        $display("========================================");

        // Apply synchronous reset.

        repeat (3) @(negedge pixel_clk);

        reset = 1'b0;

        // ------------------------------------
        // Test 1: Uniform grayscale
        // Gx=0, Gy=0, G=0
        // Expected output: black
        // ------------------------------------

        send_window(
            {9{8'd100}},
            8'd0, 1'b0, 1'b1
        );

        // ------------------------------------
        // Test 2: Positive horizontal gradient
        // Gx=1020, Gy=0, G=1020
        // Expected output: white
        // ------------------------------------

        send_window(
            {8'd0, 8'd0, 8'd255,
             8'd0, 8'd0, 8'd255,
             8'd0, 8'd0, 8'd255},
            8'd100, 1'b0, 1'b1
        );

        // ------------------------------------
        // Test 3: Negative horizontal gradient
        // Gx=-1020, Gy=0, G=1020
        // Expected output: white
        // ------------------------------------

        send_window(
            {8'd255, 8'd0, 8'd0,
             8'd255, 8'd0, 8'd0,
             8'd255, 8'd0, 8'd0},
            8'd100, 1'b0, 1'b1
        );

        // ------------------------------------
        // Test 4: Positive vertical gradient
        // Gx=0, Gy=1020, G=1020
        // Expected output: white
        // ------------------------------------

        send_window(
            {8'd0,   8'd0,   8'd0,
             8'd0,   8'd0,   8'd0,
             8'd255, 8'd255, 8'd255},
            8'd100, 1'b0, 1'b1
        );

        // ------------------------------------
        // Test 5: Negative vertical gradient
        // Gx=0, Gy=-1020, G=1020
        // Expected output: white
        // ------------------------------------

        send_window(
            {8'd255, 8'd255, 8'd255,
             8'd0,   8'd0,   8'd0,
             8'd0,   8'd0,   8'd0},
            8'd100, 1'b0, 1'b1
        );

        // ------------------------------------
        // Test 6: Diagonal gradient
        // Gx=80, Gy=240, G=320
        // Expected output: white
        // ------------------------------------

        send_window(
            {8'd10, 8'd20, 8'd30,
             8'd40, 8'd50, 8'd60,
             8'd70, 8'd80, 8'd90},
            8'd20, 1'b0, 1'b1
        );

        // ------------------------------------
        // Test 7: Maximum attainable magnitude
        // Gx=765, Gy=765, G=1530
        // Expected output: white
        // ------------------------------------

        send_window(
            {8'd0,   8'd0,   8'd0,
             8'd0,   8'd0,   8'd255,
             8'd0,   8'd255, 8'd255},
            8'd190, 1'b0, 1'b1
        );

        // ------------------------------------
        // Test 8: Threshold exactly equal
        // G=320, threshold=40*8=320
        // Expected output: black
        // ------------------------------------

        send_window(
            {8'd10, 8'd20, 8'd30,
             8'd40, 8'd50, 8'd60,
             8'd70, 8'd80, 8'd90},
            8'd40, 1'b0, 1'b1
        );

        // ------------------------------------
        // Test 9: Magnitude above threshold
        // G=320, threshold=39*8=312
        // Expected output: white
        // ------------------------------------

        send_window(
            {8'd10, 8'd20, 8'd30,
             8'd40, 8'd50, 8'd60,
             8'd70, 8'd80, 8'd90},
            8'd39, 1'b0, 1'b1
        );

        // ------------------------------------
        // Test 10: Magnitude below threshold
        // G=320, threshold=41*8=328
        // Expected output: black
        // ------------------------------------

        send_window(
            {8'd10, 8'd20, 8'd30,
             8'd40, 8'd50, 8'd60,
             8'd70, 8'd80, 8'd90},
            8'd41, 1'b0, 1'b1
        );

        // ------------------------------------
        // Test 11: Invert a detected edge
        // Expected output: black
        // ------------------------------------

        send_window(
            {8'd10, 8'd20, 8'd30,
             8'd40, 8'd50, 8'd60,
             8'd70, 8'd80, 8'd90},
            8'd20, 1'b1, 1'b1
        );

        // ------------------------------------
        // Test 12: Invert a uniform region
        // Expected output: white
        // ------------------------------------

        send_window(
            {9{8'd100}},
            8'd0, 1'b1, 1'b1
        );

        // ------------------------------------
        // Invalid cycle (pipeline bubble)
        // ------------------------------------

        send_window(
            72'd0,
            8'd0, 1'b0, 1'b0
        );

        // ------------------------------------
        // Test 13: All pixels zero
        // Expected output: black
        // ------------------------------------

        send_window(
            {9{8'd0}},
            8'd0, 1'b0, 1'b1
        );

        // ------------------------------------
        // Test 14: All pixels maximum
        // Expected output: black
        // ------------------------------------

        send_window(
            {9{8'd255}},
            8'd0, 1'b0, 1'b1
        );

        // ------------------------------------
        // Test 15: Maximum threshold
        // Expected output: black
        // ------------------------------------

        send_window(
            {8'd0,   8'd0,   8'd0,
             8'd0,   8'd0,   8'd255,
             8'd0,   8'd255, 8'd255},
            8'd255, 1'b0, 1'b1
        );

        // Flush the pipeline.

        send_window(
            72'd0,
            8'd0, 1'b0, 1'b0
        );

        repeat (5) @(negedge pixel_clk);

        // ------------------------------------
        // Reset while a window is in flight.
        // This window must be discarded.
        // ------------------------------------

        send_window(
            {8'd0, 8'd0, 8'd255,
             8'd0, 8'd0, 8'd255,
             8'd0, 8'd0, 8'd255},
            8'd100, 1'b0, 1'b1
        );

        @(negedge pixel_clk);

        reset       = 1'b1;
        input_valid = 1'b0;

        repeat (2) @(negedge pixel_clk);

        reset = 1'b0;

        repeat (5) @(negedge pixel_clk);

        // ------------------------------------
        // Test 16: Recovery after reset
        // Expected output: white
        // ------------------------------------

        send_window(
            {8'd0, 8'd0, 8'd255,
             8'd0, 8'd0, 8'd255,
             8'd0, 8'd0, 8'd255},
            8'd100, 1'b0, 1'b1
        );

        // Flush remaining pipeline results.

        send_window(
            72'd0,
            8'd0, 1'b0, 1'b0
        );

        repeat (5) @(negedge pixel_clk);

        // Verify the number of completed windows.

        if (tests_run != 16) begin

            $display(
                "FAIL: Expected 16 completed windows"
            );

            tests_failed = tests_failed + 1;

        end

        // ====================================
        // Final simulation results
        // ====================================

        $display("========================================");

        $display("Tests run:      %0d", tests_run);
        $display("Tests failed:   %0d", tests_failed);
        $display("Cycles checked: %0d", cycles_checked);

        if (tests_failed == 0)
            $display("ALL SOBEL ALU TESTS PASSED");
        else
            $display("SOME SOBEL ALU TESTS FAILED");

        $display("========================================");

        $finish;

    end

endmodule
