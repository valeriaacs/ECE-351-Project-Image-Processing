`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: Portland State University
// ECE 351
// 
// Author Name: Valeria Yanez G.
// Module Name: pipeline_datapath
// Project Name: Pipelined Manhattan Gradient Edge Detector
// Description: Integrates BRAM image storage, FSMD coordinate reader, Jose's 
//              dual-port BRAM line buffer (320-wide), and 3x3 sliding window 
//              with latency-matched border clamping flag.
//////////////////////////////////////////////////////////////////////////////////

module pipeline_datapath #(
    parameter IMG_WIDTH  = 320,
    parameter IMG_HEIGHT = 240
)(
    input  wire       clk,             // 100 MHz system clock
    input  wire       reset,           // Active-high synchronous reset
    input  wire       start,           // Start frame processing
    input  wire       continuous_mode, // 0: single-frame (sim), 1: continuous VGA loop

    // 3x3 Window Outputs to Edge Gradient ALU
    output wire [7:0] p00, p01, p02,
    output wire [7:0] p10, p11, p12,
    output wire [7:0] p20, p21, p22,
    output wire       window_valid,    // High when 3x3 window is valid
    output wire       is_border_out,   // Latency-aligned border flag for center pixel p11
    output wire       frame_done       // Frame readout completion flag
);

    // Internal interconnects
    wire [16:0] bram_addr;
    wire        bram_en;
    wire [7:0]  bram_dout;

    wire [7:0]  fsm_pixel_out;
    wire [8:0]  fsm_x_coord;
    wire [7:0]  fsm_y_coord;
    wire        fsm_is_border;
    wire        fsm_valid_out;

    wire [7:0]  lb_row0;
    wire [7:0]  lb_row1;
    wire [7:0]  lb_row2;
    wire        lb_valid_out;

    // 1. On-Chip Block RAM Image Wrapper (320x240 8-bit grayscale)
    bram_image_wrapper u_bram_wrapper (
        .clk   (clk),
        .ena   (bram_en),
        .wea   (1'b0),       // Read-only image ROM mode
        .addra (bram_addr),
        .dina  (8'h00),
        .douta (bram_dout)
    );

    // 2. FSMD Address Generator & (x, y) Coordinate Tracker
    bram_reader_fsm #(
        .IMG_WIDTH  (IMG_WIDTH),
        .IMG_HEIGHT (IMG_HEIGHT),
        .MAX_ADDR   ((IMG_WIDTH * IMG_HEIGHT) - 1)
    ) u_bram_fsm (
        .clk             (clk),
        .reset           (reset),
        .start           (start),
        .continuous_mode (continuous_mode),
        .pixel_in        (bram_dout),
        .addr            (bram_addr),
        .bram_en         (bram_en),
        .pixel_out       (fsm_pixel_out),
        .x_coord         (fsm_x_coord),
        .y_coord         (fsm_y_coord),
        .is_border       (fsm_is_border),
        .valid_out       (fsm_valid_out),
        .done            (frame_done)
    );

    // 3. Jose's Dual-Port BRAM Line Buffer (parameterized for 320-pixel width)
    line_buffer #(
        .IMAGE_WIDTH (IMG_WIDTH),
        .ADDR_WIDTH  (9)           // 2^9 = 512 >= 320
    ) u_line_buffer (
        .pixel_clk   (clk),
        .reset       (reset),
        .pixel_valid (fsm_valid_out),
        .pixel_in    (fsm_pixel_out),
        .pixel_row_0 (lb_row0),    // Row N   (Current)
        .pixel_row_1 (lb_row1),    // Row N-1 (Previous)
        .pixel_row_2 (lb_row2),    // Row N-2 (Two rows back)
        .output_valid(lb_valid_out)
    );

    // 4. Valeria's 3x3 Horizontal Tap Window Generator
    sliding_window_3x3 u_sliding_window (
        .clk         (clk),
        .rst         (reset),
        .valid_in    (lb_valid_out),
        .pixel_row_0 (lb_row0),
        .pixel_row_1 (lb_row1),
        .pixel_row_2 (lb_row2),
        .p00(p00), .p01(p01), .p02(p02),
        .p10(p10), .p11(p11), .p12(p12),
        .p20(p20), .p21(p21), .p22(p22),
        .valid_out   (window_valid)
    );

    // 5. Border Flag Latency Alignment Shift Register
    // Center pixel p11 is delayed relative to fsm_pixel_out by:
    //   + 1 row (320 valid pixels) vertically inside line_buffer
    //   + 3 cycles inside line_buffer's internal alignment stages
    //   + 2 valid shifts horizontally inside sliding_window_3x3 (col_0 -> col_1 = p11)
    // Total delay from fsm_is_border(x, y) to center pixel p11 = 320 + 3 + 2 = 325 valid cycles.
    localparam BORDER_DELAY = IMG_WIDTH + 5; // 325 cycles
    reg [BORDER_DELAY-1:0] border_delay_sr;

    always @(posedge clk) begin
        if (reset) begin
            border_delay_sr <= {BORDER_DELAY{1'b1}};
        end else if (fsm_valid_out) begin
            border_delay_sr <= {border_delay_sr[BORDER_DELAY-2:0], fsm_is_border};
        end
    end

    assign is_border_out = border_delay_sr[BORDER_DELAY-1];

endmodule