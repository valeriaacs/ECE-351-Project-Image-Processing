`timescale 1ns / 1ps

module sliding_window_3x3 (
    input  wire       clk,
    input  wire       rst,
    input  wire       valid_in,      // Connects to line_buffer.output_valid
    input  wire [7:0] pixel_row_0,   // Row N   (Current/Bottom row from line_buffer)
    input  wire [7:0] pixel_row_1,   // Row N-1 (Middle row from line_buffer)
    input  wire [7:0] pixel_row_2,   // Row N-2 (Top/Oldest row from line_buffer)

    // 3x3 Pixel Window Outputs (Row-Major: p<row><col>)
    output reg  [7:0] p00, p01, p02, // Top row    (Row N-2)
    output reg  [7:0] p10, p11, p12, // Middle row (Row N-1, p11 = center pixel)
    output reg  [7:0] p20, p21, p22, // Bottom row (Row N)
    output reg        valid_out      // High when 3x3 window has 3 valid columns
);

    // Tracks horizontal column fill (requires 3 valid shifts for a full 3x3 matrix)
    reg [1:0] col_fill_cnt;

    always @(posedge clk) begin
        if (rst) begin
            p00 <= 8'd0; p01 <= 8'd0; p02 <= 8'd0;
            p10 <= 8'd0; p11 <= 8'd0; p12 <= 8'd0;
            p20 <= 8'd0; p21 <= 8'd0; p22 <= 8'd0;
            col_fill_cnt <= 2'd0;
            valid_out    <= 1'b0;
        end else if (valid_in) begin
            // Shift left: col 0 <- col 1 <- col 2 <- new incoming column
            // Top row (Row N-2)
            p00 <= p01;
            p01 <= p02;
            p02 <= pixel_row_2;

            // Middle row (Row N-1)
            p10 <= p11;
            p11 <= p12;
            p12 <= pixel_row_1;

            // Bottom row (Row N)
            p20 <= p21;
            p21 <= p22;
            p22 <= pixel_row_0;

            // Assert valid_out once 3 horizontal pixels have shifted in
            if (col_fill_cnt < 2'd2) begin
                col_fill_cnt <= col_fill_cnt + 2'd1;
                valid_out    <= 1'b0;
            end else begin
                valid_out    <= 1'b1;
            end
        end else begin
            valid_out <= 1'b0;
        end
    end

endmodule