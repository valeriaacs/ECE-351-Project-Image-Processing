
`timescale 1ns / 1ps

module line_buffer_tb;

    reg pixel_clk = 0;
    reg reset = 1;
    reg pixel_valid = 0;
    reg [7:0] pixel_in = 0;

    wire [7:0] pixel_row_0;
    wire [7:0] pixel_row_1;
    wire [7:0] pixel_row_2;
    wire output_valid;

    integer row, col;
    integer accepted = 0;
    integer checks = 0;
    integer errors = 0;

    // Expected-output pipeline
    reg [7:0] exp0 [0:2];
    reg [7:0] exp1 [0:2];
    reg [7:0] exp2 [0:2];
    reg [2:0] exp_valid = 0;

    // 25 MHz clock
    always #20 pixel_clk = ~pixel_clk;

    line_buffer #(
        .IMAGE_WIDTH(8),
        .ADDR_WIDTH(3)
    ) uut (
        .pixel_clk(pixel_clk),
        .reset(reset),
        .pixel_valid(pixel_valid),
        .pixel_in(pixel_in),
        .pixel_row_0(pixel_row_0),
        .pixel_row_1(pixel_row_1),
        .pixel_row_2(pixel_row_2),
        .output_valid(output_valid)
    );

    // Independent reference model and checker
    always @(posedge pixel_clk) begin
        if (reset) begin
            accepted = 0;
            exp_valid = 0;
        end else begin

            // Advance expected values through pipeline
            exp0[2] = exp0[1];
            exp1[2] = exp1[1];
            exp2[2] = exp2[1];

            exp0[1] = exp0[0];
            exp1[1] = exp1[0];
            exp2[1] = exp2[0];

            exp_valid[2] = exp_valid[1];
            exp_valid[1] = exp_valid[0];
            exp_valid[0] = 0;

            if (pixel_valid) begin
                // Pixel value = row * 20 + column
                exp0[0] = (accepted / 8) * 20
                          + (accepted % 8);
                exp1[0] = ((accepted / 8) - 1) * 20
                          + (accepted % 8);
                exp2[0] = ((accepted / 8) - 2) * 20
                          + (accepted % 8);

                if (accepted >= 16)
                    exp_valid[0] = 1;

                accepted = accepted + 1;
            end

            // Wait for nonblocking assignments to settle
            #1;

            if (output_valid !== exp_valid[2]) begin
                errors = errors + 1;
                $display("VALID ERROR at time %0t", $time);
            end

            if (exp_valid[2]) begin
                checks = checks + 1;

                if (pixel_row_0 !== exp0[2] ||
                    pixel_row_1 !== exp1[2] ||
                    pixel_row_2 !== exp2[2]) begin

                    errors = errors + 1;

                    $display(
                        "PIXEL ERROR: got (%0d,%0d,%0d), expected (%0d,%0d,%0d)",
                        pixel_row_0,
                        pixel_row_1,
                        pixel_row_2,
                        exp0[2],
                        exp1[2],
                        exp2[2]
                    );
                end
            end
        end
    end

    initial begin
        // Apply reset
        repeat (5) @(negedge pixel_clk);
        reset = 0;

        // Send 6 rows of 8 pixels
        for (row = 0; row < 6; row = row + 1) begin

            for (col = 0; col < 8; col = col + 1) begin
                @(negedge pixel_clk);
                pixel_valid = 1;
                pixel_in = row * 20 + col;
            end

            // Three blanking cycles between rows
            @(negedge pixel_clk);
            pixel_valid = 0;
            repeat (3) @(negedge pixel_clk);
        end

        pixel_valid = 0;

        // Flush remaining pipeline data
        repeat (5) @(negedge pixel_clk);

        $display("Checks performed: %0d", checks);
        $display("Errors found: %0d", errors);

        if (errors == 0 && checks == 32)
            $display("PASS: Line buffer alignment verified!");
        else
            $display("FAIL: Line buffer verification failed.");

        $finish;
    end

endmodule
