
`timescale 1ns / 1ps

module vga_controller (
    input  wire       pixel_clk,
    input  wire       reset,
    output wire       hsync,
    output wire       vsync,
    output wire [9:0] pixel_x,
    output wire [9:0] pixel_y,
    output wire       video_on
);

    // Horizontal VGA timing
    parameter H_VISIBLE = 640;
    parameter H_FRONT   = 16;
    parameter H_SYNC    = 96;
    parameter H_BACK    = 48;
    parameter H_TOTAL   = 800;

    // Vertical VGA timing
    parameter V_VISIBLE = 480;
    parameter V_FRONT   = 10;
    parameter V_SYNC    = 2;
    parameter V_BACK    = 33;
    parameter V_TOTAL   = 525;

    reg [9:0] h_count = 0;
    reg [9:0] v_count = 0;

    // Pixel counters
    always @(posedge pixel_clk) begin
        if (reset) begin
            h_count <= 0;
            v_count <= 0;
        end
        else if (h_count == H_TOTAL - 1) begin
            h_count <= 0;

            if (v_count == V_TOTAL - 1)
                v_count <= 0;
            else
                v_count <= v_count + 1'b1;
        end
        else begin
            h_count <= h_count + 1'b1;
        end
    end

    // Horizontal synchronization (active LOW)
    assign hsync = ~(
        (h_count >= H_VISIBLE + H_FRONT) &&
        (h_count < H_VISIBLE + H_FRONT + H_SYNC)
    );

    // Vertical synchronization (active LOW)
    assign vsync = ~(
        (v_count >= V_VISIBLE + V_FRONT) &&
        (v_count < V_VISIBLE + V_FRONT + V_SYNC)
    );

    // Active display region
    assign video_on =
        (h_count < H_VISIBLE) &&
        (v_count < V_VISIBLE);

    // Current pixel coordinates
    assign pixel_x = h_count;
    assign pixel_y = v_count;

endmodule
