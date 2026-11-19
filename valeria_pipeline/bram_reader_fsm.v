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
// 
// 
// 
//////////////////////////////////////////////////////////////////////////////////

module bram_reader_fsm (
    input  wire        clk,          // System clock (100 MHz Basys 3 clock)
    input  wire        reset,        // Active-high synchronous reset
    input  wire        start,        // Signal to begin reading image from address 0
    input  wire [7:0]  pixel_in,     // 8-bit pixel value output coming from BRAM (douta)
    
    output reg  [16:0] addr,         // 17-bit BRAM address bus (0 to 76,799)
    output reg         bram_en,      // BRAM enable signal (ena)
    output wire [7:0]  pixel_out,    // 8-bit registered pixel output for downstream logic
    output reg         valid_out,    // Pulse high when pixel_out contains a valid pixel
    output reg         done          // Signals full frame read completion
);

    // FSM State Encoding
    localparam IDLE  = 2'b00,
               READ  = 2'b01,
               DONE  = 2'b10;

    reg [1:0] state, next_state;
    reg [1:0] pipeline_delay; // Accounts for 1-clock cycle BRAM read latency

    // Assign registered output pixel data
    assign pixel_out = pixel_in;

    // FSM State Register
    always @(posedge clk) begin
        if (reset) begin
            state <= IDLE;
        end else begin
            state <= next_state;
        end
    end

    // Next State Logic & Address Counter
    always @(posedge clk) begin
        if (reset) begin
            addr           <= 17'd0;
            bram_en        <= 1'b0;
            valid_out      <= 1'b0;
            done           <= 1'b0;
            pipeline_delay <= 2'd0;
        end else begin
            case (state)
                IDLE: begin
                    done      <= 1'b0;
                    valid_out <= 1'b0;
                    addr      <= 17'd0;
                    if (start) begin
                        bram_en        <= 1'b1;
                        pipeline_delay <= 2'd0;
                        state          <= READ;
                    end else begin
                        bram_en        <= 1'b0;
                    end
                end

                READ: begin
                    bram_en <= 1'b1;
                    
                    // Increment memory address up to 76,799 (320x240 - 1)
                    if (addr < 17'd76799) begin
                        addr <= addr + 1'b1;
                    end else begin
                        bram_en <= 1'b0;
                        state   <= DONE;
                    end

                    // Handle BRAM 1-clock-cycle read latency
                    if (pipeline_delay < 2'd1) begin
                        pipeline_delay <= pipeline_delay + 1'b1;
                        valid_out      <= 1'b0;
                    end else begin
                        valid_out      <= 1'b1;
                    end
                end

                DONE: begin
                    bram_en   <= 1'b0;
                    valid_out <= 1'b0;
                    done      <= 1'b1;
                    if (!start) begin
                        state <= IDLE;
                    end
                end

                default: state <= IDLE;
            endcase
        end
    end

endmodule

