
`timescale 1ns / 1ps

// ECE 351 - Week 6 Verification
// Prevent row-crossing 3x3 windows from being marked valid.
//
// This is a proposed validity guard.
// It does not modify the original sliding window module.

module window_valid_guard #(
    parameter IMAGE_WIDTH = 5,
    parameter ADDR_WIDTH = 3
)(
    input wire clk,
    input wire reset,

    // One valid column of three pixels from the line buffer.
    input wire column_valid,

    // Original output from sliding_window_3x3.
    input wire raw_window_valid,

    // Valid only if the window does not cross a row boundary.
    output wire safe_window_valid
);

    // Track the column currently entering the sliding window.
    reg [ADDR_WIDTH-1:0] column_index;

    // Indicates whether three columns from the same row
    // have been received.
    reg column_allowed;

    always @(posedge clk) begin
        if (reset) begin
            column_index   <= 0;
            column_allowed <= 0;
        end
        else begin

            // Columns 0 and 1 cannot complete a new
            // spatially valid 3x3 window.
            column_allowed <= column_valid &&
                              (column_index >= 2);

            // Advance only when a new column is received.
            if (column_valid) begin
                if (column_index == IMAGE_WIDTH - 1)
                    column_index <= 0;
                else
                    column_index <= column_index + 1'b1;
            end
        end
    end

    // Both conditions must be true.
    assign safe_window_valid =
        raw_window_valid && column_allowed;

endmodule
