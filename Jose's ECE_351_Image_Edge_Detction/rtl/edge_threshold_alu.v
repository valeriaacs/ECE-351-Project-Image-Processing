`timescale 1ns / 1ps

// ECE 351 - Image Edge Detection
// Four-stage pipelined Sobel + Manhattan ALU
// Target: Digilent Basys 3
// Pixel clock: 25 MHz

module edge_threshold_alu (
    input  wire        pixel_clk,
    input  wire        reset,
    input  wire        input_valid,
    input  wire [71:0] pixels_in,
    input  wire [7:0]  threshold,
    input  wire        invert,

    output reg  [7:0]  edge_pixel,
    output reg         output_valid
);

    // ========================================
    // Unpack the 3x3 grayscale pixel window
    // ========================================
    //
    // P11 P12 P13
    // P21 P22 P23
    // P31 P32 P33
    //

    wire [7:0] P11 = pixels_in[71:64];
    wire [7:0] P12 = pixels_in[63:56];
    wire [7:0] P13 = pixels_in[55:48];

    wire [7:0] P21 = pixels_in[47:40];
    wire [7:0] P22 = pixels_in[39:32];
    wire [7:0] P23 = pixels_in[31:24];

    wire [7:0] P31 = pixels_in[23:16];
    wire [7:0] P32 = pixels_in[15:8];
    wire [7:0] P33 = pixels_in[7:0];

    // ========================================
    // Stage 1 registers: weighted sums
    // ========================================

    reg [9:0] right_sum_s1;
    reg [9:0] left_sum_s1;
    reg [9:0] bottom_sum_s1;
    reg [9:0] top_sum_s1;

    reg       valid_s1;
    reg [7:0] threshold_s1;
    reg       invert_s1;

    // ========================================
    // Stage 2 registers: signed gradients
    // ========================================

    reg signed [10:0] gx_s2;
    reg signed [10:0] gy_s2;

    reg       valid_s2;
    reg [7:0] threshold_s2;
    reg       invert_s2;

    // ========================================
    // Stage 3 registers: Manhattan magnitude
    // ========================================

    reg [10:0] magnitude_s3;

    reg       valid_s3;
    reg [7:0] threshold_s3;
    reg       invert_s3;

    // Absolute values of signed gradients
    wire [10:0] abs_gx;
    wire [10:0] abs_gy;

    assign abs_gx = gx_s2[10] ? -gx_s2 : gx_s2;
    assign abs_gy = gy_s2[10] ? -gy_s2 : gy_s2;

    // ========================================
    // Stage 4 combinational threshold logic
    // ========================================

    wire [10:0] scaled_threshold;
    wire        edge_detected;
    wire        final_edge;

    // Multiply the 8-bit threshold by 8
    // using concatenation instead of a multiplier.
    assign scaled_threshold = {threshold_s3, 3'b000};

    // Strict comparison keeps zero-gradient
    // pixels black when threshold is zero.
    assign edge_detected =
        (magnitude_s3 > scaled_threshold);

    // Optional black/white inversion
    assign final_edge = edge_detected ^ invert_s3;

    // ========================================
    // Four-stage sequential pipeline
    // ========================================

    always @(posedge pixel_clk) begin

        if (reset) begin

            // Stage 1 reset
            right_sum_s1  <= 10'd0;
            left_sum_s1   <= 10'd0;
            bottom_sum_s1 <= 10'd0;
            top_sum_s1    <= 10'd0;

            valid_s1     <= 1'b0;
            threshold_s1 <= 8'd0;
            invert_s1    <= 1'b0;

            // Stage 2 reset
            gx_s2 <= 11'sd0;
            gy_s2 <= 11'sd0;

            valid_s2     <= 1'b0;
            threshold_s2 <= 8'd0;
            invert_s2    <= 1'b0;

            // Stage 3 reset
            magnitude_s3 <= 11'd0;

            valid_s3     <= 1'b0;
            threshold_s3 <= 8'd0;
            invert_s3    <= 1'b0;

            // Stage 4 reset
            edge_pixel   <= 8'd0;
            output_valid <= 1'b0;

        end else begin

            // =================================
            // STAGE 1: Sobel weighted sums
            // =================================

            right_sum_s1 <=
                {2'b00, P13} +
                {1'b0, P23, 1'b0} +
                {2'b00, P33};

            left_sum_s1 <=
                {2'b00, P11} +
                {1'b0, P21, 1'b0} +
                {2'b00, P31};

            bottom_sum_s1 <=
                {2'b00, P31} +
                {1'b0, P32, 1'b0} +
                {2'b00, P33};

            top_sum_s1 <=
                {2'b00, P11} +
                {1'b0, P12, 1'b0} +
                {2'b00, P13};

            valid_s1     <= input_valid;
            threshold_s1 <= threshold;
            invert_s1    <= invert;

            // =================================
            // STAGE 2: Signed Sobel gradients
            // =================================

            gx_s2 <=
                $signed({1'b0, right_sum_s1}) -
                $signed({1'b0, left_sum_s1});

            gy_s2 <=
                $signed({1'b0, bottom_sum_s1}) -
                $signed({1'b0, top_sum_s1});

            valid_s2     <= valid_s1;
            threshold_s2 <= threshold_s1;
            invert_s2    <= invert_s1;

            // =================================
            // STAGE 3: Manhattan magnitude
            // =================================

            magnitude_s3 <= abs_gx + abs_gy;

            valid_s3     <= valid_s2;
            threshold_s3 <= threshold_s2;
            invert_s3    <= invert_s2;

            // =================================
            // STAGE 4: Threshold and inversion
            // =================================

            output_valid <= valid_s3;

            if (valid_s3)
                edge_pixel <= final_edge
                            ? 8'hFF : 8'h00;
            else
                edge_pixel <= 8'h00;

        end
    end

endmodule
