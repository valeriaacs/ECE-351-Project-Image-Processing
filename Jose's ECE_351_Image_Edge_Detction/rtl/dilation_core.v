
`timescale 1ns / 1ps

module dilation_core (
    input  wire       pixel_clk,
    input  wire       reset,
    input  wire       input_valid,

    input  wire [7:0] P11, P12, P13,
    input  wire [7:0] P21, P22, P23,
    input  wire [7:0] P31, P32, P33,

    output reg  [7:0] P_max,
    output reg        output_valid
);

    // Stage 1 registers: maxima of each row
    reg [7:0] max_row1;
    reg [7:0] max_row2;
    reg [7:0] max_row3;
    reg valid_stage1;

    // Parallel combinational comparisons
    wire [7:0] max1 =
        (P11 >= P12 && P11 >= P13) ? P11 :
        (P12 >= P13) ? P12 : P13;

    wire [7:0] max2 =
        (P21 >= P22 && P21 >= P23) ? P21 :
        (P22 >= P23) ? P22 : P23;

    wire [7:0] max3 =
        (P31 >= P32 && P31 >= P33) ? P31 :
        (P32 >= P33) ? P32 : P33;

    // Pipeline Stage 1
    always @(posedge pixel_clk) begin
        if (reset) begin
            max_row1     <= 8'd0;
            max_row2     <= 8'd0;
            max_row3     <= 8'd0;
            valid_stage1 <= 1'b0;
        end else begin
            max_row1     <= max1;
            max_row2     <= max2;
            max_row3     <= max3;
            valid_stage1 <= input_valid;
        end
    end

    // Pipeline Stage 2
    always @(posedge pixel_clk) begin
        if (reset) begin
            P_max        <= 8'd0;
            output_valid <= 1'b0;
        end else begin
            P_max <=
                (max_row1 >= max_row2 &&
                 max_row1 >= max_row3) ? max_row1 :
                (max_row2 >= max_row3) ? max_row2 :
                                         max_row3;

            output_valid <= valid_stage1;
        end
    end

endmodule
