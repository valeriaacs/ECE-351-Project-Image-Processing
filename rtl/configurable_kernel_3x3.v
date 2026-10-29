// Configurable 3x3 Structuring Element
// ECE 351 - Morphological Edge Detection
//
// kernel_select = 0: Square kernel (all 9 pixels)
// kernel_select = 1: Cross kernel (center + 4 neighbors)

module configurable_kernel_3x3(
    input wire kernel_select,
    output wire [8:0] kernel_mask
    );

    // Select the structuring element based on the switch.
    assign kernel_mask = (kernel_select == 1'b0)
                       ? 9'b111_111_111
                       : 9'b010_111_010;

endmodule