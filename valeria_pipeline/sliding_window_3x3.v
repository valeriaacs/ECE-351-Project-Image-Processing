`timescale 1ns / 1ps

// ============================================================================
// Module Name:  sliding_window_3x3
// Project:      Hardware-Accelerated BRAM Image Processing Pipeline
// Target:       Basys 3 FPGA (Xilinx Artix-7 XC7A35T)
// Description:  Generates a 3x3 pixel neighborhood matrix from a streaming
//               8-bit grayscale pixel input. Uses two internal shift register
//               line buffers to store two previous image rows.
// Reference:    Digital Design and Computer Architecture (Harris & Harris)
// ============================================================================

module sliding_window_3x3 #(
    parameter IMG_WIDTH  = 320,  // Image width in pixels
    parameter DATA_WIDTH = 8     // Pixel depth (8-bit grayscale)
)(
    // System Signals
    input  wire                  clk,       // System clock
    input  wire                  reset,     // Active-high synchronous/asynchronous reset
    input  wire                  in_valid,  // Valid signal indicating incoming pixel data
    input  wire [DATA_WIDTH-1:0] pixel_in,  // Streaming input pixel data
    
    // 3x3 Output Window Pixels
    // Matrix orientation: p<row><column>
    // [ p00  p01  p02 ]  <- Top row    (Oldest data)
    // [ p10  p11  p12 ]  <- Middle row
    // [ p20  p21  p22 ]  <- Bottom row (Newest data / Current input)
    output reg  [DATA_WIDTH-1:0] p00, output reg  [DATA_WIDTH-1:0] p01, output reg  [DATA_WIDTH-1:0] p02,
    output reg  [DATA_WIDTH-1:0] p10, output reg  [DATA_WIDTH-1:0] p11, output reg  [DATA_WIDTH-1:0] p12,
    output reg  [DATA_WIDTH-1:0] p20, output reg  [DATA_WIDTH-1:0] p21, output reg  [DATA_WIDTH-1:0] p22,
    
    // Output Status
    output reg                   out_valid  // High when 3x3 window contains valid image data
);

    // ========================================================================
    // Internal Memory Structures
    // ========================================================================
    // Shift-register arrays to buffer 2 full horizontal lines of the image
    reg [DATA_WIDTH-1:0] line_buf1 [0:IMG_WIDTH-1]; // Line buffer for Row 1
    reg [DATA_WIDTH-1:0] line_buf2 [0:IMG_WIDTH-1]; // Line buffer for Row 0

    // Loop iterator for register reset and line buffer shift operations
    integer i;

    // Tracker for initial pipeline filling latency
    // Valid output occurs after receiving (2 * IMG_WIDTH + 2) pixels
    reg [16:0] pixel_count;
    localparam TOTAL_START_DELAY = (2 * IMG_WIDTH) + 2;

    // ========================================================================
    // Main Sequential Logic
    // ========================================================================
    always @(posedge clk or posedge reset) begin
        if (reset) begin
            // ----------------------------------------------------------------
            // Reset state: Clear output window registers
            // ----------------------------------------------------------------
            p00 <= {DATA_WIDTH{1'b0}}; p01 <= {DATA_WIDTH{1'b0}}; p02 <= {DATA_WIDTH{1'b0}};
            p10 <= {DATA_WIDTH{1'b0}}; p11 <= {DATA_WIDTH{1'b0}}; p12 <= {DATA_WIDTH{1'b0}};
            p20 <= {DATA_WIDTH{1'b0}}; p21 <= {DATA_WIDTH{1'b0}}; p22 <= {DATA_WIDTH{1'b0}};

            // Reset internal line buffers
            for (i = 0; i < IMG_WIDTH; i = i + 1) begin
                line_buf1[i] <= {DATA_WIDTH{1'b0}};
                line_buf2[i] <= {DATA_WIDTH{1'b0}};
            end

            // Reset counters and status flags
            pixel_count <= 17'd0;
            out_valid   <= 1'b0;

        end else if (in_valid) begin
            // ----------------------------------------------------------------
            // 1. Shift Column Registers (Horizontal movement leftward)
            // ----------------------------------------------------------------
            // Row 0 (Top row: feed from Line Buffer 2 output)
            p00 <= p01;
            p01 <= p02;
            p02 <= line_buf2[IMG_WIDTH-1];

            // Row 1 (Middle row: feed from Line Buffer 1 output)
            p10 <= p11;
            p11 <= p12;
            p12 <= line_buf1[IMG_WIDTH-1];

            // Row 2 (Bottom row: feed from current incoming pixel stream)
            p20 <= p21;
            p21 <= p22;
            p22 <= pixel_in;

            // ----------------------------------------------------------------
            // 2. Shift Line Buffers (Vertical movement downward across rows)
            // ----------------------------------------------------------------
            // Line Buffer 1: Ingest new pixel into tap 0, shift existing right
            line_buf1[0] <= pixel_in;
            for (i = 1; i < IMG_WIDTH; i = i + 1) begin
                line_buf1[i] <= line_buf1[i-