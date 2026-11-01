`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: Portland State University 
// ECE 351
// 
// Create Date: 10/31/2026 12:40:49 PM
// Author Name: Valeria Yanez G.  
// Module Name: bram_reader_fsm
// Project Name: Edge Detector 
// Target Devices: Xilinx Artix-7 FPGA 
// Description: FSM and address generator that will systematically iterate through addresses 0 to 76, 799(320 x 240 - 1)
// to pull 8-bit pixel values from the BRAM IP core and make them available for display. 
// 
//////////////////////////////////////////////////////////////////////////////////

module tb_bram_reader;

    reg         clk;
    reg         reset;
    reg         start;
    wire [16:0] addr;
    wire        bram_en;
    wire [7:0]  pixel_out;
    wire        valid_out;
    wire        done;

    // Dummy BRAM signal for test simulation
    wire [7:0]  douta;
    
    // Top BRAM Wrapper Instance
    bram_image_wrapper u_bram (
        .clk   (clk),
        .ena   (bram_en),
        .wea   (1'b0),
        .addra (addr),
        .dina  (8'h00),
        .douta (douta)
    );

    // FSM Reader Instance
    bram_reader_fsm u_reader (
        .clk       (clk),
        .reset     (reset),
        .start     (start),
        .pixel_in  (douta),
        .addr      (addr),
        .bram_en   (bram_en),
        .pixel_out (pixel_out),
        .valid_out (valid_out),
        .done      (done)
    );

    // 100 MHz Clock Generation (10ns period)
    always #5 clk = ~clk;

    initial begin
        clk   = 0;
        reset = 1;
        start = 0;

        #20;
        reset = 0;
        #20;
        
        // Trigger FSM to start reading frame
        start = 1;
        #10;
        start = 0;

        // Wait until done signal triggers
        wait(done);
        #100;
        $finish;
    end

endmodule