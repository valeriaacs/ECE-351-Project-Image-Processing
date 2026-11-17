
`timescale 1ns / 1ps

module morphology_cores_tb;

    reg pixel_clk = 0;
    reg reset = 1;
    reg input_valid = 0;

    reg [7:0] P11 = 0, P12 = 0, P13 = 0;
    reg [7:0] P21 = 0, P22 = 0, P23 = 0;
    reg [7:0] P31 = 0, P32 = 0, P33 = 0;

    wire [7:0] P_max;
    wire [7:0] P_min;
    wire dilation_valid;
    wire erosion_valid;

    integer errors = 0;
    integer checks = 0;

    reg [7:0] expected_max_stage1;
    reg [7:0] expected_min_stage1;
    reg [7:0] expected_max_stage2;
    reg [7:0] expected_min_stage2;

    reg expected_valid_stage1 = 0;
    reg expected_valid_stage2 = 0;

    // 25 MHz pixel clock
    always #20 pixel_clk = ~pixel_clk;

    // Dilation core
    dilation_core dut_dilation (
        .pixel_clk(pixel_clk),
        .reset(reset),
        .input_valid(input_valid),

        .P11(P11), .P12(P12), .P13(P13),
        .P21(P21), .P22(P22), .P23(P23),
        .P31(P31), .P32(P32), .P33(P33),

        .P_max(P_max),
        .output_valid(dilation_valid)
    );

    // Erosion core
    erosion_core dut_erosion (
        .pixel_clk(pixel_clk),
        .reset(reset),
        .input_valid(input_valid),

        .P11(P11), .P12(P12), .P13(P13),
        .P21(P21), .P22(P22), .P23(P23),
        .P31(P31), .P32(P32), .P33(P33),

        .P_min(P_min),
        .output_valid(erosion_valid)
    );

    // Reference maximum function
    function [7:0] max9;
        input [71:0] pixels;
        integer i;
        reg [7:0] value;
        begin
            max9 = 0;
            for (i = 0; i < 9; i = i + 1) begin
                value = pixels[i*8 +: 8];
                if (value > max9)
                    max9 = value;
            end
        end
    endfunction

    // Reference minimum function
    function [7:0] min9;
        input [71:0] pixels;
        integer i;
        reg [7:0] value;
        begin
            min9 = 255;
            for (i = 0; i < 9; i = i + 1) begin
                value = pixels[i*8 +: 8];
                if (value < min9)
                    min9 = value;
            end
        end
    endfunction

    // Scoreboard
    always @(posedge pixel_clk) begin
        if (reset) begin
            expected_valid_stage1 = 0;
            expected_valid_stage2 = 0;
        end else begin
            expected_max_stage2 = expected_max_stage1;
            expected_min_stage2 = expected_min_stage1;
            expected_valid_stage2 = expected_valid_stage1;

            expected_max_stage1 = max9({
                P11, P12, P13,
                P21, P22, P23,
                P31, P32, P33
            });

            expected_min_stage1 = min9({
                P11, P12, P13,
                P21, P22, P23,
                P31, P32, P33
            });

            expected_valid_stage1 = input_valid;
        end

        #1;

        if (dilation_valid !== erosion_valid) begin
            errors = errors + 1;
            $display("ERROR: Pipeline valid mismatch");
        end

        if (dilation_valid !== expected_valid_stage2 ||
            erosion_valid !== expected_valid_stage2) begin
            errors = errors + 1;
            $display("ERROR: Incorrect pipeline delay");
        end

        if (expected_valid_stage2) begin
            checks = checks + 1;

            if (P_max !== expected_max_stage2) begin
                errors = errors + 1;
                $display(
                    "DILATION ERROR: got %0d expected %0d",
                    P_max, expected_max_stage2
                );
            end

            if (P_min !== expected_min_stage2) begin
                errors = errors + 1;
                $display(
                    "EROSION ERROR: got %0d expected %0d",
                    P_min, expected_min_stage2
                );
            end
        end
    end

    // Drive inputs on falling clock edges
    task send_window;
        input [7:0] a, b, c, d, e, f, g, h, i;
        input valid;
        begin
            @(negedge pixel_clk);

            P11 = a; P12 = b; P13 = c;
            P21 = d; P22 = e; P23 = f;
            P31 = g; P32 = h; P33 = i;

            input_valid = valid;
        end
    endtask

    initial begin
        repeat (4) @(negedge pixel_clk);
        reset = 0;

        // Test 1: mixed grayscale values
        send_window(12,45,30,80,100,25,60,200,90,1);

        // Test 2: all zero
        send_window(0,0,0,0,0,0,0,0,0,1);

        // Test 3: all maximum
        send_window(255,255,255,255,255,255,255,255,255,1);

        // Test 4: ascending values
        send_window(10,20,30,40,50,60,70,80,90,1);

        // Test 5: invalid cycle
        send_window(1,2,3,4,5,6,7,8,9,0);

        // Test 6: minimum at last pixel
        send_window(90,80,70,60,50,40,30,20,1,1);

        // Test 7: maximum at first pixel
        send_window(250,20,30,40,50,60,70,80,90,1);

        // Test 8: duplicate values
        send_window(40,40,40,80,80,80,120,120,120,1);

        // End input stream
        @(negedge pixel_clk);
        input_valid = 0;

        repeat (4) @(negedge pixel_clk);

        $display("Checks performed: %0d", checks);
        $display("Errors found: %0d", errors);

        if (errors == 0 && checks == 7)
            $display(
                "PASS: Dilation and erosion pipelines verified!"
            );
        else
            $display(
                "FAIL: Morphology core verification failed."
            );

        $finish;
    end

endmodule
