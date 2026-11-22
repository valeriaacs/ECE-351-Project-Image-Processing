
`timescale 1ns / 1ps

// ECE 351 - Week 6, Task 2
// Multiple Grayscale Matrix Verification
//
// Tests:
// 1. Sequential grayscale pixels
// 2. Minimum grayscale values (0)
// 3. Maximum grayscale values (255)
// 4. Mixed grayscale values
// 5. Pixel-valid pauses
//
// Checks all 9 window pixels against expected values.
// Also verifies valid-window ordering and boundaries.

module tb_line_buffer_cases;

    parameter IMAGE_WIDTH = 5;
    parameter IMAGE_HEIGHT = 5;

    reg clk = 0;
    reg reset = 1;
    reg pixel_valid = 0;
    reg [7:0] pixel_in = 0;

    wire [7:0] row0, row1, row2;
    wire line_valid;

    wire [7:0] p00, p01, p02;
    wire [7:0] p10, p11, p12;
    wire [7:0] p20, p21, p22;

    wire window_valid;
    wire safe_window_valid;

    // Software reference image.
    reg [7:0] image_data [0:24];

    integer raw_count = 0;
    integer accepted_count = 0;
    integer rejected_count = 0;
    integer error_count = 0;
    integer active_test = 0;

    integer expected_index;
    reg expected_valid;

    // 10 ns clock period.
    always #5 clk = ~clk;

    // --------------------------------------
    // Line buffer
    // --------------------------------------

    line_buffer #(
        .IMAGE_WIDTH(IMAGE_WIDTH),
        .ADDR_WIDTH(3)
    ) uut_line_buffer (
        .pixel_clk(clk),
        .reset(reset),
        .pixel_valid(pixel_valid),
        .pixel_in(pixel_in),
        .pixel_row_0(row0),
        .pixel_row_1(row1),
        .pixel_row_2(row2),
        .output_valid(line_valid)
    );

    // --------------------------------------
    // Sliding window
    // --------------------------------------

    sliding_window_3x3 uut_window (
        .clk(clk),
        .rst(reset),
        .valid_in(line_valid),
        .pixel_row_0(row0),
        .pixel_row_1(row1),
        .pixel_row_2(row2),
        .p00(p00), .p01(p01), .p02(p02),
        .p10(p10), .p11(p11), .p12(p12),
        .p20(p20), .p21(p21), .p22(p22),
        .valid_out(window_valid)
    );

    // --------------------------------------
    // Window validity guard
    // --------------------------------------

    window_valid_guard #(
        .IMAGE_WIDTH(IMAGE_WIDTH),
        .ADDR_WIDTH(3)
    ) uut_guard (
        .clk(clk),
        .reset(reset),
        .column_valid(line_valid),
        .raw_window_valid(window_valid),
        .safe_window_valid(safe_window_valid)
    );

    // --------------------------------------
    // Generate software reference images
    // --------------------------------------

    task load_image;
        input integer test_id;
        integer n;
        begin
            for (n = 0; n < 25; n = n + 1) begin
                case (test_id)
                    0: image_data[n] = n + 1;
                    1: image_data[n] = 8'd0;
                    2: image_data[n] = 8'd255;
                    3: image_data[n] = (n * 37 + 11) % 256;
                    4: image_data[n] = (n * 53 + 29) % 256;
                    default: image_data[n] = 0;
                endcase
            end

            // Include explicit grayscale extremes
            // in the mixed-value test.
            if (test_id == 3) begin
                image_data[0]  = 8'd0;
                image_data[12] = 8'd255;
                image_data[24] = 8'd0;
            end
        end
    endtask

    // --------------------------------------
    // Hardware versus software comparison
    // --------------------------------------

    always @(posedge clk) begin
        // Wait for registered outputs to update.
        #1;

        if (reset) begin
            if (window_valid === 1'b1 ||
                safe_window_valid === 1'b1) begin
                error_count = error_count + 1;
                $display("FAIL: Valid output during reset");
            end
        end
        else if (window_valid) begin

            // Number of valid horizontal positions
            // per row is IMAGE_WIDTH - 2.
            expected_valid =
                ((raw_count % IMAGE_WIDTH) < IMAGE_WIDTH - 2);

            // Check whether the guard made
            // the correct validity decision.
            if (safe_window_valid !== expected_valid) begin
                error_count = error_count + 1;
                $display("FAIL: Valid timing/boundary, test %0d",
                         active_test);
            end

            if (safe_window_valid)
                accepted_count = accepted_count + 1;
            else
                rejected_count = rejected_count + 1;

            if (raw_count >= 13) begin
                error_count = error_count + 1;
                $display("FAIL: Unexpected extra window");
            end
            else if (expected_valid) begin

                // Compute the top-left image index
                // independently from the pixel outputs.
                expected_index =
                    (raw_count / IMAGE_WIDTH) * IMAGE_WIDTH
                    + (raw_count % IMAGE_WIDTH);

                // Check all nine pixel positions.
                if (
                    p00 !== image_data[expected_index] ||
                    p01 !== image_data[expected_index + 1] ||
                    p02 !== image_data[expected_index + 2] ||

                    p10 !== image_data[expected_index + IMAGE_WIDTH] ||
                    p11 !== image_data[expected_index + IMAGE_WIDTH + 1] ||
                    p12 !== image_data[expected_index + IMAGE_WIDTH + 2] ||

                    p20 !== image_data[expected_index + 2*IMAGE_WIDTH] ||
                    p21 !== image_data[expected_index + 2*IMAGE_WIDTH + 1] ||
                    p22 !== image_data[expected_index + 2*IMAGE_WIDTH + 2]
                ) begin
                    error_count = error_count + 1;
                    $display("FAIL: Pixel mismatch, test %0d, window %0d",
                             active_test, raw_count);
                end
                else begin
                    $display("PASS: Test %0d, window %0d aligned",
                             active_test, raw_count);
                end
            end

            raw_count = raw_count + 1;
        end
    end

    // --------------------------------------
    // Run one complete 5x5 image test
    // --------------------------------------

    task run_test;
        input integer test_id;
        integer n;
        begin
            reset = 1;
            pixel_valid = 0;
            pixel_in = 0;
            active_test = test_id;

            load_image(test_id);

            repeat (4) @(negedge clk);

            raw_count = 0;
            accepted_count = 0;
            rejected_count = 0;
            error_count = 0;

            reset = 0;

            $display("==========================");
            $display("START TEST %0d", test_id);

            // Send all 25 image pixels.
            for (n = 0; n < 25; n = n + 1) begin

                // Test 4 introduces idle cycles.
                if (test_id == 4 &&
                    (n == 3 || n == 10 || n == 18)) begin
                    @(negedge clk);
                    pixel_valid = 0;
                    @(negedge clk);
                    pixel_valid = 0;
                end

                @(negedge clk);
                pixel_valid = 1;
                pixel_in = image_data[n];
            end

            @(negedge clk);
            pixel_valid = 0;
            pixel_in = 0;

            // Flush remaining pipeline outputs.
            repeat (10) @(negedge clk);

            $display("Raw windows: %0d", raw_count);
            $display("Accepted: %0d", accepted_count);
            $display("Rejected: %0d", rejected_count);
            $display("Errors: %0d", error_count);

            if (raw_count == 13 &&
                accepted_count == 9 &&
                rejected_count == 4 &&
                error_count == 0) begin
                $display("TEST %0d PASSED", test_id);
            end
            else begin
                $fatal(1, "TEST %0d FAILED", test_id);
            end

            $display("==========================");
        end
    endtask

    // --------------------------------------
    // Execute all five test scenarios
    // --------------------------------------

    initial begin
        run_test(0);
        run_test(1);
        run_test(2);
        run_test(3);
        run_test(4);

        $display("==========================");
        $display("ALL WEEK 6 TASK 2 TESTS PASSED");
        $display("==========================");

        $finish;
    end

endmodule
