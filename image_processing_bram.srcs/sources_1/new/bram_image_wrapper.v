`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: Portland State University
// ECE 351 
// 
// Create Date: 10/31/2026 12:12:27 PM
// Design Name: Valeria Yanez G.
// Module Name: bram_image_wrapper
// Project Name: Edge Detector
// Target Devices: Xilinx Artix-7 FPGA 
// Description: Verilod wrapper module that acts as a bridge between top-level hardware signals and the auto-generated Xilins Block RAM.
//  
// 
//  
// 
// Revision:
// Revision 0.01 - File Created
// Additional Comments:
// 
//////////////////////////////////////////////////////////////////////////////////

module bram_image_wrapper (
    input  wire        clk,        // 100 MHz Basys 3 system clock
    input  wire        ena,        // Memory enable signal
    input  wire        wea,        // Write enable (set to 0 for read-only image buffer)
    input  wire [16:0] addra,      // 17-bit address bus (2^17 = 131,072 >= 76,800)
    input  wire [7:0]  dina,       // Data input (unused during read, set to 8'h00)
    output wire [7:0]  douta       // 8-bit output pixel data read from BRAM
);

    // Instantiate the BRAM IP core generated in Vivado IP Catalog
    bram_image image_bram_inst (
        .clka  (clk),    // Port A Clock
        .ena   (ena),    // Port A Enable
        .wea   (wea),    // Port A Write Enable (1 bit)
        .addra (addra),  // Port A Address [16:0]
        .dina  (dina),   // Port A Data Input [7:0]
        .douta (douta)   // Port A Data Output [7:0]
    );

endmodule
  
