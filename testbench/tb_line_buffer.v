
`timescale 1ns / 1ps

// ECE 351 - Week 6, Task 1
// Line Buffer and 3x3 Sliding Window Testbench

module tb_line_buffer;

    // Use a small image for easier testing.
    parameter IMAGE_WIDTH = 5;

    // Clock, reset, and pixel inputs.
    reg clk = 0;
    reg reset = 1;
    reg pixel_valid = 0;
    reg [7:0] pixel_in = 0;

    // Outputs from the line buffer.
    wire [7:0] row0, row1, row2;
    wire line_valid;

    // Outputs from the sliding window.
    wire [7:0] p00, p01, p02;
    wire [7:0] p10, p11, p12;
    wire [7:0] p20, p21, p22;
    wire window_valid;

wire safe_window_valid;

    // Counters for automatic verification results.
    integer accepted_count = 0;
    integer rejected_count = 0;
    integer error_count = 0;


    // Generate a clock with a 10 ns period.
    always #5 clk = ~clk;

    // Instantiate the line buffer.
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

    // Connect the sliding window to the line buffer.
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

    // Week 6: Window validity guard
    // Rejects windows crossing image-row boundaries.

    window_valid_guard #(
        .IMAGE_WIDTH(IMAGE_WIDTH),
        .ADDR_WIDTH(3)
    ) uut_valid_guard (
        .clk(clk),
        .reset(reset),
        .column_valid(line_valid),
        .raw_window_valid(window_valid),
        .safe_window_valid(safe_window_valid)
    );



    integer i;

    // Send 25 grayscale pixels into the pipeline.
    initial begin
        repeat (3) @(negedge clk);
        reset = 0;

        for (i = 1; i <= 25; i = i + 1) begin
            @(negedge clk);
            pixel_valid = 1;
            pixel_in = i;
        end

        @(negedge clk);
        pixel_valid = 0;

        // Allow the pipeline to finish.
        repeat (10) @(negedge clk);


        $display("==============================");
        $display("WEEK 6 TASK 1 RESULTS");
        $display("Accepted windows: %0d", accepted_count);
        $display("Rejected windows: %0d", rejected_count);
        $display("Errors: %0d", error_count);


        // Final automatic verification.
        // Report success only if every check passes.
        if (accepted_count == 9 &&
            rejected_count == 4 &&
            error_count == 0) begin

            $display("PASS: All verification checks passed.");

        end
        else begin

            // Stop with an actual simulation failure.
            $fatal(1, "FAIL: Week 6 Task 1 verification failed.");

        end


        $display("==============================");
        $finish;

    end

    // Print each window marked valid by the design.
 
    // Week 6: Verify that the validity guard
    // accepts correct windows and rejects row crossings.

   

    always @(negedge clk) begin
        if (window_valid) begin

            if (safe_window_valid) begin
                accepted_count = accepted_count + 1;

                // Check boundary and all nine pixel positions.
                if (
                    p00 < 1 ||
                    ((p00 - 1) % IMAGE_WIDTH) >= IMAGE_WIDTH - 2 ||
                    p01 !== (p00 + 1) ||
                    p02 !== (p00 + 2) ||
                    p10 !== (p00 + IMAGE_WIDTH) ||
                    p11 !== (p00 + IMAGE_WIDTH + 1) ||
                    p12 !== (p00 + IMAGE_WIDTH + 2) ||
                    p20 !== (p00 + 2*IMAGE_WIDTH) ||
                    p21 !== (p00 + 2*IMAGE_WIDTH + 1) ||
                    p22 !== (p00 + 2*IMAGE_WIDTH + 2)
                ) begin
                    error_count = error_count + 1;
                    $display("FAIL: Incorrect window accepted at %0t", $time);
                end
                else begin
                    $display("PASS: Valid 3x3 window accepted at %0t", $time);
                end
            end
            else begin
                rejected_count = rejected_count + 1;

                // A rejected window should cross a row boundary.
                if (((p00 - 1) % IMAGE_WIDTH) < IMAGE_WIDTH - 2) begin
                    error_count = error_count + 1;
                    $display("FAIL: Valid window rejected at %0t", $time);
                end
                else begin
                    $display("REJECTED: Row boundary at %0t", $time);
                end
            end
        end
    end


endmodule
