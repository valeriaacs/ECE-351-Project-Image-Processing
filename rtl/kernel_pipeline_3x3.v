
`timescale 1ns / 1ps

// ECE 351 - Morphological Edge Detection
// Configurable 3x3 Kernel Integration Wrapper
//
// Combines:
//   configurable_kernel_3x3.v
//   pixel_selector_3x3.v
//
// kernel_select = 0: Square kernel
// kernel_select = 1: Cross kernel
//
// pixels_in contains nine 8-bit grayscale pixels
// in row-major order: P11 through P33.
//
// This module is purely combinational.

module kernel_pipeline_3x3(
    input  wire        kernel_select,
    input  wire [71:0] pixels_in,

    output wire [8:0]  kernel_mask,
    output wire [71:0] dilation_pixels,
    output wire [71:0] erosion_pixels
);

    // Stage 1: Generate the configurable kernel mask.
    configurable_kernel_3x3 kernel_generator (
        .kernel_select(kernel_select),
        .kernel_mask(kernel_mask)
    );

    // Stage 2: Apply the mask to the 3x3 pixel window.
    pixel_selector_3x3 pixel_selector (
        .pixels_in(pixels_in),
        .kernel_mask(kernel_mask),
        .dilation_pixels(dilation_pixels),
        .erosion_pixels(erosion_pixels)
    );

endmodule
