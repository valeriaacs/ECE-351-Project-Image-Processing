`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: Portland State University 
// ECE 351
// 
// Author Name: Valeria Yanez G.  
// Module Name: bram_reader_fsm
// Project Name: Pipelined Manhattan Gradient Edge Detector
// Target Devices: Xilinx Artix-7 FPGA (Basys 3)
// Description: FSMD address generator and (x, y) coordinate tracker for a 
//              320x240 image stored in BRAM. Aligns valid_out, (x, y), and 
//              is_border flags with the 1-cycle BRAM read latency.
//////////////////////////////////////////////////////////////////////////////////

module bram_reader_fsm #(
    parameter IMG_WIDTH  = 320,
    parameter IMG_HEIGHT = 240,
    parameter MAX_ADDR   = (IMG_WIDTH * IMG_HEIGHT) - 1 // 76,799
)(
    input  wire        clk,             // 100 MHz system clock
    input  wire        reset,           // Active-high synchronous reset
    input  wire        start,           // Start frame read
    input  wire        continuous_mode, // 0: single-frame (sim), 1: continuous loop (VGA)
    input  wire [7:0]  pixel_in,        // 8-bit pixel data from BRAM (douta)
    
    output reg  [16:0] addr,            // 17-bit BRAM address (0 to 76,799)
    output reg         bram_en,         // BRAM enable signal (ena)
    output wire [7:0]  pixel_out,       // 8-bit pixel output for downstream pipeline
    output reg  [8:0]  x_coord,         // Column coordinate (0 to 319) aligned with pixel_out
    output reg  [7:0]  y_coord,         // Row coordinate (0 to 239) aligned with pixel_out
    output wire        is_border,       // High when (x_coord, y_coord) lies on 1-px outer border
    output reg         valid_out,       // High when pixel_out and (x, y) are valid
    output reg         done             // Pulses/holds high at end of frame
);

    // FSMD State Encoding
    localparam [1:0] IDLE  = 2'b00,
                     READ  = 2'b01,
                     FLUSH = 2'b10, // Captures final pixel (addr 76,799) after 1-cycle BRAM latency
                     DONE  = 2'b11;

    reg [1:0] state;
    reg       latency_ready; // Tracks 1-cycle BRAM read latency

    // Pass-through BRAM data (already registered inside BRAM IP output)
    assign pixel_out = pixel_in;

    // Coordinate-aware border detection (suppresses 3x3 wrap-around artifacts)
    assign is_border = (x_coord == 9'd0) || (x_coord == IMG_WIDTH - 1) ||
                       (y_coord == 8'd0) || (y_coord == IMG_HEIGHT - 1);

    always @(posedge clk) begin
        if (reset) begin
            state         <= IDLE;
            addr          <= 17'd0;
            bram_en       <= 1'b0;
            valid_out     <= 1'b0;
            done          <= 1'b0;
            latency_ready <= 1'b0;
            x_coord       <= 9'd0;
            y_coord       <= 8'd0;
        end else begin
            case (state)
                IDLE: begin
                    done          <= 1'b0;
                    valid_out     <= 1'b0;
                    addr          <= 17'd0;
                    x_coord       <= 9'd0;
                    y_coord       <= 8'd0;
                    latency_ready <= 1'b0;

                    if (start) begin
                        bram_en <= 1'b1;
                        state   <= READ;
                    end else begin
                        bram_en <= 1'b0;
                    end
                end

                READ: begin
                    done <= 1'b0;

                    // Advance BRAM address (0 -> 76,799)
                    if (addr < MAX_ADDR) begin
                        addr    <= addr + 17'd1;
                        bram_en <= 1'b1;
                    end else begin
                        bram_en <= 1'b0;
                        state   <= FLUSH;
                    end

                    // Account for 1-cycle BRAM read latency before asserting valid_out
                    if (!latency_ready) begin
                        latency_ready <= 1'b1;
                        valid_out     <= 1'b0;
                        x_coord       <= 9'd0;
                        y_coord       <= 8'd0;
                    end else begin
                        valid_out <= 1'b1;
                        // Increment (x, y) coordinates corresponding to the valid pixel
                        if (x_coord == IMG_WIDTH - 1) begin
                            x_coord <= 9'd0;
                            y_coord <= y_coord + 8'd1;
                        end else begin
                            x_coord <= x_coord + 9'd1;
                        end
                    end
                end

                FLUSH: begin
                    // Final pixel (76,799) arrives on douta during this cycle
                    bram_en   <= 1'b0;
                    valid_out <= 1'b1;
                    done      <= 1'b1;

                    // Advance (x, y) to final pixel (319, 239)
                    if (x_coord == IMG_WIDTH - 1) begin
                        x_coord <= 9'd0;
                        y_coord <= y_coord + 8'd1;
                    end else begin
                        x_coord <= x_coord + 9'd1;
                    end

                    if (continuous_mode && start) begin
                        addr          <= 17'd0;
                        bram_en       <= 1'b1;
                        latency_ready <= 1'b0;
                        state         <= READ;
                    end else begin
                        state <= DONE;
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