`timescale 1ns / 1ps

// ECE 351 - Morphological Edge Detection
// Testbench for configurable 3x3 kernel
//
// Tests both square and cross kernel configurations.

module tb_configurable_kernel_3x3;

    // Input controlled by the testbench
    reg kernel_select;

    // Output received from the kernel module
    wire [8:0] kernel_mask;

    // Instantiate the module being tested (DUT)
    configurable_kernel_3x3 dut (
        .kernel_select(kernel_select),
        .kernel_mask(kernel_mask)
    );

    initial begin

        // Test 1: Square kernel
        kernel_select = 1'b0;
        #10;

        if (kernel_mask === 9'b111_111_111)
            $display("PASS: Square kernel");
        else
            $display("FAIL: Square kernel");

        // Test 2: Cross kernel
        kernel_select = 1'b1;
        #10;

        if (kernel_mask === 9'b010_111_010)
            $display("PASS: Cross kernel");
        else
            $display("FAIL: Cross kernel");

        // End simulation
        $finish;

    end

endmodule