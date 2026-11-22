
`timescale 1ns / 1ps

// ECE 351 - Week 6, Task 3
// Option C: Manhattan Gradient Edge Threshold ALU
//
// Formula:
// G = |p01 - p21| + |p10 - p12|
//
// Edge output:
// 255 when G > threshold
// 0 otherwise
//
// Features:
// - 9-bit gradient (range 0 to 510)
// - 8-bit adjustable threshold
// - Optional pixel inversion
// - Optional grayscale passthrough
// - Border suppression
// - Registered output and valid signal

module edge_threshold_alu (
    input wire clk,
    input wire reset,

    // Valid 3x3 window from the upstream pipeline
    input wire valid_in,
    input wire is_border,

    // Four neighboring pixels and center pixel
    input wire [7:0] p01,
    input wire [7:0] p10,
    input wire [7:0] p11,
    input wire [7:0] p12,
    input wire [7:0] p21,

    // FPGA switch controls
    input wire [7:0] threshold,
    input wire invert_en,
    input wire bypass_en,

    // Registered results
    output reg [8:0] gradient_out,
    output reg [7:0] pixel_out,
    output reg valid_out
);

    // Step 1: Absolute vertical pixel difference
    wire [7:0] vertical_diff;

    assign vertical_diff =
        (p01 >= p21) ? (p01 - p21) : (p21 - p01);

    // Step 2: Absolute horizontal pixel difference
    wire [7:0] horizontal_diff;

    assign horizontal_diff =
        (p10 >= p12) ? (p10 - p12) : (p12 - p10);

    // Step 3: Add differences using 9 bits
    // Maximum possible gradient = 255 + 255 = 510
    wire [8:0] gradient;

    assign gradient =
        {1'b0, vertical_diff} +
        {1'b0, horizontal_diff};

    // Step 4: Threshold comparison
    // Strictly greater than, NOT greater than or equal
    wire [7:0] edge_pixel;

    assign edge_pixel =
        (gradient > {1'b0, threshold}) ?
        8'hFF : 8'h00;

    // Step 5: Select grayscale or edge output
    wire [7:0] selected_pixel;

    assign selected_pixel =
        bypass_en ? p11 : edge_pixel;

    // Step 6: Optional bitwise inversion
    wire [7:0] inverted_pixel;

    assign inverted_pixel =
        invert_en ? ~selected_pixel : selected_pixel;

    // Step 7: Register outputs
    // One clocked output stage
    always @(posedge clk) begin
        if (reset) begin
            gradient_out <= 9'd0;
            pixel_out    <= 8'd0;
            valid_out    <= 1'b0;
        end
        else begin
            valid_out <= valid_in;

            if (valid_in) begin
                gradient_out <= gradient;

                // Suppress borders in edge-detection mode.
                // Border pixels remain black even if
                // inversion is enabled.
                if (is_border && !bypass_en)
                    pixel_out <= 8'h00;
                else
                    pixel_out <= inverted_pixel;
            end
            else begin
                gradient_out <= 9'd0;
                pixel_out    <= 8'd0;
            end
        end
    end

endmodule
