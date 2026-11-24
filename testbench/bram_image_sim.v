`timescale 1ns / 1ps

// ECE 351 - Week 8, Task 1
// Simulation-only BRAM model.
//
// Emulates the Xilinx bram_image IP core.
// Loads the converted 320x240 grayscale image.
//
// This module is for behavioral simulation only.
// Do not include it alongside the actual Xilinx
// bram_image IP or use it for hardware synthesis.

module bram_image (
    input  wire        clka,
    input  wire        ena,
    input  wire        wea,
    input  wire [16:0] addra,
    input  wire [7:0]  dina,
    output reg  [7:0]  douta
);

    // Total number of pixels in the input image.
    localparam NUM_PIXELS = 76800;

    // Each memory location stores one 8-bit pixel.
    reg [7:0] memory [0:NUM_PIXELS-1];

    // Path to the simulation memory file.
    reg [4095:0] mem_file;

    integer file_handle;

    // Initialize memory before simulation begins.
    initial begin
        douta = 8'd0;

        // Allow the memory path to be specified
        // when launching the simulation.
        if (!$value$plusargs("MEM_FILE=%s", mem_file))
            mem_file = "image_data.mem";

        // Verify that the memory file exists.
        file_handle = $fopen(mem_file, "r");

        if (file_handle == 0) begin
            $fatal(1, "Cannot open memory file: %0s",
                   mem_file);
        end

        $fclose(file_handle);

        // Load hexadecimal grayscale pixel values.
        $readmemh(mem_file, memory);

        $display("BRAM simulation memory initialized.");
        $display("Memory file: %0s", mem_file);
        $display("Total image pixels: %0d", NUM_PIXELS);
    end

    // Synchronous BRAM read operation.
    // Data becomes available after the clock edge.
    always @(posedge clka) begin
        if (ena) begin
            if (addra < NUM_PIXELS) begin

                // Read-first memory behavior.
                douta <= memory[addra];

                // Support writes if enabled.
                if (wea)
                    memory[addra] <= dina;

            end else begin
                douta <= 8'd0;
                $error("BRAM address out of range: %0d",
                       addra);
            end
        end
    end

endmodule
