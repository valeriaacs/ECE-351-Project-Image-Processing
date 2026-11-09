
`timescale 1ns / 1ps

module line_buffer #(
    parameter IMAGE_WIDTH = 640,
    parameter ADDR_WIDTH  = 10
)(
    input  wire       pixel_clk,
    input  wire       reset,
    input  wire       pixel_valid,
    input  wire [7:0] pixel_in,

    output reg [7:0] pixel_row_0,
    output reg [7:0] pixel_row_1,
    output reg [7:0] pixel_row_2,
    output reg       output_valid
);

    // Two 640 x 8-bit line memories.
    // Vivado can infer simple dual-port block RAM.
    (* ram_style = "block" *)
    reg [7:0] line_mem_1 [0:IMAGE_WIDTH-1];

    (* ram_style = "block" *)
    reg [7:0] line_mem_2 [0:IMAGE_WIDTH-1];

    reg [ADDR_WIDTH-1:0] col_addr;
    reg [ADDR_WIDTH-1:0] col_addr_d;

    // Saturates at 2 completed rows.
    reg [1:0] lines_seen;

    // Pipeline registers
    reg [7:0] line1_read;
    reg [7:0] line2_read;
    reg [7:0] current_d;
    reg [7:0] current_dd;
    reg [7:0] previous_dd;

    reg valid_d;
    reg valid_dd;
    reg ready_d;
    reg ready_dd;

    // Stage 1: Read previous row and store current row.
    // The memory uses read-first behavior.
    always @(posedge pixel_clk) begin
        if (pixel_valid && !reset) begin
            line1_read <= line_mem_1[col_addr];
            line_mem_1[col_addr] <= pixel_in;
        end
    end

    // Stage 2: Read two rows back, then overwrite
    // that location with the previous-row pixel.
    // The delayed address matches line1_read.
    always @(posedge pixel_clk) begin
        if (valid_d && !reset) begin
            line2_read <= line_mem_2[col_addr_d];
            line_mem_2[col_addr_d] <= line1_read;
        end
    end

    // Control and output alignment pipeline
    always @(posedge pixel_clk) begin
        if (reset) begin
            col_addr     <= 0;
            col_addr_d   <= 0;
            lines_seen   <= 0;

            valid_d      <= 0;
            valid_dd     <= 0;
            ready_d      <= 0;
            ready_dd     <= 0;
            output_valid <= 0;

            current_d    <= 0;
            current_dd   <= 0;
            previous_dd  <= 0;

            pixel_row_0  <= 0;
            pixel_row_1  <= 0;
            pixel_row_2  <= 0;
        end else begin
            // Stage 1 control
            valid_d <= pixel_valid;
            ready_d <= pixel_valid && (lines_seen == 2);

            if (pixel_valid) begin
                current_d  <= pixel_in;
                col_addr_d <= col_addr;

                if (col_addr == IMAGE_WIDTH - 1) begin
                    col_addr <= 0;

                    if (lines_seen < 2)
                        lines_seen <= lines_seen + 1;
                end else begin
                    col_addr <= col_addr + 1;
                end
            end

            // Stage 2 alignment
            valid_dd <= valid_d;
            ready_dd <= ready_d;

            if (valid_d) begin
                current_dd  <= current_d;
                previous_dd <= line1_read;
            end

            // Stage 3: Three pixels from the same column
            output_valid <= ready_dd;

            if (valid_dd) begin
                pixel_row_0 <= current_dd;
                pixel_row_1 <= previous_dd;
                pixel_row_2 <= line2_read;
            end
        end
    end

endmodule
