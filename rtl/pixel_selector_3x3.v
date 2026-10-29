
`timescale 1ns / 1ps

// ECE 351 - Morphological Edge Detection
// Configurable 3x3 Pixel Selector
//
// Pixel ordering (row-major):
//
//   P11  P12  P13
//   P21  P22  P23
//   P31  P32  P33
//
// pixels_in[71:64] = P11
// pixels_in[63:56] = P12
// pixels_in[55:48] = P13
// pixels_in[47:40] = P21
// pixels_in[39:32] = P22
// pixels_in[31:24] = P23
// pixels_in[23:16] = P31
// pixels_in[15:8]  = P32
// pixels_in[7:0]   = P33
//
// kernel_mask[8] = P11
// kernel_mask[0] = P33
//
// Selected pixels retain their original values.
//
// Excluded pixels become:
//   8'h00 for dilation (maximum)
//   8'hFF for erosion (minimum)

module pixel_selector_3x3(
    input  wire [71:0] pixels_in,
    input  wire [8:0]  kernel_mask,
    output wire [71:0] dilation_pixels,
    output wire [71:0] erosion_pixels
);

    genvar i;

    generate
        for (i = 0; i < 9; i = i + 1) begin : select_pixel

            assign dilation_pixels[i*8 +: 8] =
                kernel_mask[i] ?
                pixels_in[i*8 +: 8] : 8'h00;

            assign erosion_pixels[i*8 +: 8] =
                kernel_mask[i] ?
                pixels_in[i*8 +: 8] : 8'hFF;

        end
    endgenerate

endmodule
