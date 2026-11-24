`timescale 1ns / 1ps

// ECE 351 - Week 8, Task 1
// Full Pipeline Integration Testbench
//
// Option C: Manhattan Gradient Edge Detection
//
// Verifies:
// 1. BRAM image reading
// 2. Sliding window generation
// 3. Gradient calculation
// 4. Threshold comparison
// 5. Border suppression
// 6. Output valid synchronization
// 7. Frame completion and pixel counts

module tb_full_pipeline;

    // Image configuration
    localparam IMG_WIDTH  = 320;
    localparam IMG_HEIGHT = 240;
    localparam NUM_PIXELS = IMG_WIDTH * IMG_HEIGHT;

    // Clock and control signals
    reg clk;
    reg reset;
    reg start;
    reg continuous_mode;

    // Edge detection controls
    reg [7:0] threshold;
    reg invert_en;
    reg bypass_en;

    // Sliding window outputs
    wire [7:0] p00, p01, p02;
    wire [7:0] p10, p11, p12;
    wire [7:0] p20, p21, p22;

    wire window_valid;
    wire is_border_out;
    wire frame_done;

    // Edge ALU outputs
    wire [8:0] gradient_out;
    wire [7:0] pixel_out;
    wire valid_out;

    // Verification counters
    integer cycle_count;
    integer input_count;
    integer window_count;
    integer output_count;
    integer pass_count;
    integer error_count;

    // Independent diagnostic counters
    integer pixel_errors;
    integer x_coord_errors;
    integer y_coord_errors;
    integer window_errors;
    integer border_errors;
    integer gradient_errors;
    integer alu_pixel_errors;
    integer valid_errors;
    integer count_errors;

    // Compare alternative BRAM stream alignment.
    integer shifted_pixel_matches;
    integer shifted_pixel_checks;

    // Actual pixel stream received from the BRAM reader.
    reg [7:0] received_image [0:NUM_PIXELS-1];
    reg received_border [0:NUM_PIXELS-1];

    // Independent downstream verification counters.
    integer received_window_checks;
    integer received_window_errors;
    integer received_border_checks;
    integer received_border_errors;

    // Track the address associated with each BRAM response.
    integer read_address;
    integer bram_read_count;
    integer first_valid_address;
    integer previous_valid_address;
    integer last_valid_address;
    integer address_sequence_errors;
    integer shifted_address_errors;


    integer border_count;
    integer edge_count;
    integer first_valid_cycle;
    integer first_input_cycle;
    integer frame_done_seen;

    // Independent reference calculations
    integer vertical_diff;
    integer horizontal_diff;
    integer expected_gradient;

    reg [7:0] expected_pixel;
    reg expected_valid;

    // Independent image reference memory
    reg [7:0] reference_image [0:NUM_PIXELS-1];
    reg [4095:0] mem_file;

    // Reference coordinates
    integer expected_x;
    integer expected_y;
    integer center_index;
    integer window_index;

    integer k;

    // =========================================
    // 1. Instantiate Valeria's pipeline datapath
    // =========================================

    pipeline_datapath #(
        .IMG_WIDTH(IMG_WIDTH),
        .IMG_HEIGHT(IMG_HEIGHT)
    ) dut_pipeline (
        .clk(clk),
        .reset(reset),
        .start(start),
        .continuous_mode(continuous_mode),

        .p00(p00), .p01(p01), .p02(p02),
        .p10(p10), .p11(p11), .p12(p12),
        .p20(p20), .p21(p21), .p22(p22),

        .window_valid(window_valid),
        .is_border_out(is_border_out),
        .frame_done(frame_done)
    );

    // =========================================
    // 2. Instantiate the edge threshold ALU
    // =========================================

    edge_threshold_alu dut_alu (
        .clk(clk),
        .reset(reset),

        .valid_in(window_valid),
        .is_border(is_border_out),

        .p01(p01),
        .p10(p10),
        .p11(p11),
        .p12(p12),
        .p21(p21),

        .threshold(threshold),
        .invert_en(invert_en),
        .bypass_en(bypass_en),

        .gradient_out(gradient_out),
        .pixel_out(pixel_out),
        .valid_out(valid_out)
    );

    // =========================================
    // 3. Generate a 100 MHz clock
    // =========================================

    initial clk = 0;

    always #5 clk = ~clk;

    // =========================================
    // 4. Pipeline verification monitor
    // =========================================

    always @(posedge clk) begin

        if (!reset) begin

            cycle_count = cycle_count + 1;

            // Verify pixels entering the line buffer.
            if (dut_pipeline.fsm_valid_out) begin

                if (input_count == 0)
                    first_input_cycle = cycle_count;

                if (input_count < NUM_PIXELS) begin

                    expected_x = input_count % IMG_WIDTH;
                    expected_y = input_count / IMG_WIDTH;

                    // Check actual pixel data.
                    if (dut_pipeline.fsm_pixel_out !==
                        reference_image[input_count]) begin

                        pixel_errors = pixel_errors + 1;

                        if (pixel_errors <= 5)
                            $display(
                                "PIXEL FAIL: index=%0d actual=%0d expected=%0d",
                                input_count,
                                dut_pipeline.fsm_pixel_out,
                                reference_image[input_count]
                            );
                    end

                    // Check horizontal coordinates.
                    if (dut_pipeline.fsm_x_coord !==
                        expected_x) begin

                        x_coord_errors = x_coord_errors + 1;

                        if (x_coord_errors <= 5)
                            $display(
                                "X FAIL: index=%0d actual=%0d expected=%0d",
                                input_count,
                                dut_pipeline.fsm_x_coord,
                                expected_x
                            );
                    end

                    // Check vertical coordinates.
                    if (dut_pipeline.fsm_y_coord !==
                        expected_y) begin

                        y_coord_errors = y_coord_errors + 1;

                        if (y_coord_errors <= 5)
                            $display(
                                "Y FAIL: index=%0d actual=%0d expected=%0d",
                                input_count,
                                dut_pipeline.fsm_y_coord,
                                expected_y
                            );
                    end

                    // Test whether the stream is shifted
                    // forward by one memory location.
                    if (input_count < NUM_PIXELS-1) begin

                        shifted_pixel_checks =
                            shifted_pixel_checks + 1;

                        if (dut_pipeline.fsm_pixel_out ===
                            reference_image[input_count+1])
                            shifted_pixel_matches =
                                shifted_pixel_matches + 1;
                    end

                end else begin
                    count_errors = count_errors + 1;
                end

                if (input_count < NUM_PIXELS) begin
                    received_image[input_count] =
                        dut_pipeline.fsm_pixel_out;

                    received_border[input_count] =
                        dut_pipeline.fsm_is_border;
                end

                // Record first and final valid BRAM addresses.
                if (input_count == 0)
                    first_valid_address = read_address;

                previous_valid_address = last_valid_address;
                last_valid_address = read_address;

                // Check the intended address sequence.
                if (read_address != input_count)
                    address_sequence_errors =
                        address_sequence_errors + 1;

                // Check the suspected shifted address sequence.
                if (input_count < NUM_PIXELS-1) begin
                    if (read_address != input_count+1)
                        shifted_address_errors =
                            shifted_address_errors + 1;
                end else begin
                    if (read_address != NUM_PIXELS-1)
                        shifted_address_errors =
                            shifted_address_errors + 1;
                end

                input_count = input_count + 1;
            end

            // Capture the expected ALU input-valid signal.
            if (dut_pipeline.bram_en) begin
                read_address = dut_pipeline.bram_addr;
                bram_read_count = bram_read_count + 1;
            end

            expected_valid = window_valid;

            if (window_valid) begin

                // Independently calculate the gradient.
                vertical_diff =
                    int'(p01) - int'(p21);

                if (vertical_diff < 0)
                    vertical_diff = -vertical_diff;

                horizontal_diff =
                    int'(p10) - int'(p12);

                if (horizontal_diff < 0)
                    horizontal_diff = -horizontal_diff;

                expected_gradient =
                    vertical_diff + horizontal_diff;

                // Calculate the expected output pixel.
                if (bypass_en)
                    expected_pixel = p11;
                else if (expected_gradient > threshold)
                    expected_pixel = 8'hFF;
                else
                    expected_pixel = 8'h00;

                if (invert_en)
                    expected_pixel = ~expected_pixel;

                if (is_border_out && !bypass_en)
                    expected_pixel = 8'h00;

                if (is_border_out)
                    border_count = border_count + 1;

                // Determine the intended center pixel
                // from the raster-order window sequence.
                center_index =
                    IMG_WIDTH + 1 + window_count;

                if (center_index < NUM_PIXELS) begin

                    expected_x =
                        center_index % IMG_WIDTH;

                    expected_y =
                        center_index / IMG_WIDTH;

                    // Verify the aligned border flag.
                    if (is_border_out !==
                        ((expected_x == 0) ||
                         (expected_x == IMG_WIDTH-1) ||
                         (expected_y == 0) ||
                         (expected_y == IMG_HEIGHT-1))) begin

                        border_errors = border_errors + 1;

                        if (border_errors <= 5)
                            $display(
                                "BORDER FAIL: center=%0d x=%0d y=%0d actual=%0b",
                                center_index,
                                expected_x,
                                expected_y,
                                is_border_out
                            );
                    end

                    // Verify all nine window pixels for
                    // positions inside the image borders.
                    if ((expected_x > 0) &&
                        (expected_x < IMG_WIDTH-1) &&
                        (expected_y > 0) &&
                        (expected_y < IMG_HEIGHT-1)) begin

                        if ({
                            p00, p01, p02,
                            p10, p11, p12,
                            p20, p21, p22
                        } !== {
                            reference_image[center_index-IMG_WIDTH-1],
                            reference_image[center_index-IMG_WIDTH],
                            reference_image[center_index-IMG_WIDTH+1],
                            reference_image[center_index-1],
                            reference_image[center_index],
                            reference_image[center_index+1],
                            reference_image[center_index+IMG_WIDTH-1],
                            reference_image[center_index+IMG_WIDTH],
                            reference_image[center_index+IMG_WIDTH+1]
                        }) begin

                            window_errors = window_errors + 1;

                            if (window_errors <= 5)
                                $display(
                                    "WINDOW FAIL: center=%0d actual=%0d expected=%0d",
                                    center_index,
                                    p11,
                                    reference_image[center_index]
                                );
                        end
                    end
                end

                // Verify window generation independently
                // of the original image and BRAM reader errors.
                //
                // Restrict this check to interior coordinates.

                if ((expected_x > 0) &&
                    (expected_x < IMG_WIDTH-1) &&
                    (expected_y > 0) &&
                    (expected_y < IMG_HEIGHT-1) &&
                    (center_index+IMG_WIDTH+1 < input_count)) begin

                    received_window_checks =
                        received_window_checks + 1;

                    if ({
                        p00, p01, p02,
                        p10, p11, p12,
                        p20, p21, p22
                    } !== {
                        received_image[center_index-IMG_WIDTH-1],
                        received_image[center_index-IMG_WIDTH],
                        received_image[center_index-IMG_WIDTH+1],
                        received_image[center_index-1],
                        received_image[center_index],
                        received_image[center_index+1],
                        received_image[center_index+IMG_WIDTH-1],
                        received_image[center_index+IMG_WIDTH],
                        received_image[center_index+IMG_WIDTH+1]
                    }) begin

                        received_window_errors =
                            received_window_errors + 1;

                        if (received_window_errors <= 5)
                            $display(
                                "RECEIVED WINDOW FAIL: center=%0d",
                                center_index
                            );
                    end
                end

                // Verify delayed border flags against the
                // actual flags supplied by the upstream FSM.

                if (center_index < input_count &&
                    center_index < NUM_PIXELS) begin

                    received_border_checks =
                        received_border_checks + 1;

                    if (is_border_out !==
                        received_border[center_index]) begin

                        received_border_errors =
                            received_border_errors + 1;

                        if (received_border_errors <= 5)
                            $display(
                                "RECEIVED BORDER FAIL: center=%0d",
                                center_index
                            );
                    end
                end

                window_count = window_count + 1;
            end

            // Allow registered ALU outputs to update.
            #1;

            // Verify valid signal synchronization.
            if (valid_out !== expected_valid) begin
                valid_errors = valid_errors + 1;

                if (valid_errors <= 5)
                    $display(
                        "VALID FAIL: cycle=%0d",
                        cycle_count
                    );
            end

            // Verify registered ALU results.
            if (expected_valid) begin

                if (output_count == 0) begin
                    first_valid_cycle = cycle_count;

                    $display(
                        "First valid output at cycle %0d",
                        cycle_count
                    );
                end

                output_count = output_count + 1;

                if (pixel_out == 8'hFF)
                    edge_count = edge_count + 1;

                if (
                    (gradient_out ===
                     expected_gradient[8:0]) &&
                    (pixel_out === expected_pixel)
                ) begin

                    pass_count = pass_count + 1;

                end else begin

                    if (gradient_out !==
                        expected_gradient[8:0]) begin

                        gradient_errors = gradient_errors + 1;

                        if (gradient_errors <= 5)
                            $display(
                                "GRADIENT FAIL: actual=%0d expected=%0d",
                                gradient_out,
                                expected_gradient
                            );
                    end

                    if (pixel_out !== expected_pixel) begin

                        alu_pixel_errors = alu_pixel_errors + 1;

                        if (alu_pixel_errors <= 5)
                            $display(
                                "ALU PIXEL FAIL: actual=%0d expected=%0d",
                                pixel_out,
                                expected_pixel
                            );
                    end
                end
            end

            if (frame_done)
                frame_done_seen = 1;
        end
    end

    // =========================================
    // 5. Simulation stimulus
    // =========================================

    initial begin

        reset = 1;
        start = 0;
        continuous_mode = 0;

        threshold = 8'd50;
        invert_en = 0;
        bypass_en = 0;

        cycle_count = 0;
        input_count = 0;
        window_count = 0;
        output_count = 0;
        pass_count = 0;
        error_count = 0;

        pixel_errors = 0;
        x_coord_errors = 0;
        y_coord_errors = 0;
        window_errors = 0;
        border_errors = 0;
        gradient_errors = 0;
        alu_pixel_errors = 0;
        valid_errors = 0;
        count_errors = 0;

        shifted_pixel_matches = 0;
        shifted_pixel_checks = 0;

        received_window_checks = 0;
        received_window_errors = 0;
        received_border_checks = 0;
        received_border_errors = 0;

        read_address = -1;
        bram_read_count = 0;
        first_valid_address = -1;
        previous_valid_address = -1;
        last_valid_address = -1;
        address_sequence_errors = 0;
        shifted_address_errors = 0;
        border_count = 0;
        edge_count = 0;
        first_valid_cycle = -1;
        first_input_cycle = -1;
        frame_done_seen = 0;

        expected_valid = 0;
        expected_pixel = 0;
        expected_gradient = 0;

        if (!$value$plusargs("MEM_FILE=%s", mem_file))
            mem_file = "image_data.mem";

        $readmemh(mem_file, reference_image);

        // Verify reference memory initialization.
        for (k = 0; k < NUM_PIXELS; k = k + 1)
            if (^reference_image[k] === 1'bx)
                $fatal(1, "Invalid reference memory index=%0d", k);

        $display("======================================");
        $display("ECE 351 - Week 8 Task 1");
        $display("Full Pipeline Integration Test");
        $display("======================================");
        $display("Image size: %0d x %0d",
                 IMG_WIDTH, IMG_HEIGHT);
        $display("Expected input pixels: %0d",
                 NUM_PIXELS);
        $display("Threshold: %0d", threshold);

        // Release reset away from the active clock edge.
        repeat (5) @(negedge clk);
        reset = 0;

        // Start processing one image frame.
        repeat (2) @(negedge clk);
        start = 1;

        @(negedge clk);
        start = 0;

        // Wait for frame completion.
        wait (frame_done === 1'b1);

        // Allow remaining pipeline outputs to finish.
        repeat (20) @(negedge clk);

        // Check frame-level pixel counts.
        if (input_count != NUM_PIXELS)
            count_errors = count_errors + 1;

        if (output_count != window_count)
            count_errors = count_errors + 1;

        // Existing window generator does not produce
        // valid windows for the initial 2 rows + 2 pixels.
        if (window_count != NUM_PIXELS-2*IMG_WIDTH-2)
            count_errors = count_errors + 1;

        if (frame_done_seen == 0)
            count_errors = count_errors + 1;

        // =====================================
        // 6. Print the verification summary
        // =====================================

        $display("");
        $display("======================================");
        $display("FULL PIPELINE VERIFICATION SUMMARY");
        $display("======================================");

        $display("BRAM input pixels:    %0d", input_count);
        $display("Valid windows:        %0d", window_count);
        $display("Processed outputs:    %0d", output_count);
        $display("Correct ALU outputs:  %0d", pass_count);
        $display("Border windows:       %0d", border_count);
        $display("Detected edge pixels: %0d", edge_count);
        error_count =
            pixel_errors +
            x_coord_errors +
            y_coord_errors +
            window_errors +
            border_errors +
            gradient_errors +
            alu_pixel_errors +
            valid_errors +
            count_errors;

        $display("");
        $display("INDEPENDENT ERROR BREAKDOWN");
        $display("--------------------------------------");
        $display("BRAM pixel errors:    %0d", pixel_errors);
        $display("X coordinate errors:  %0d", x_coord_errors);
        $display("Y coordinate errors:  %0d", y_coord_errors);
        $display("Window errors:        %0d", window_errors);
        $display("Border flag errors:   %0d", border_errors);
        $display("Gradient errors:      %0d", gradient_errors);
        $display("ALU pixel errors:     %0d", alu_pixel_errors);
        $display("Valid timing errors:  %0d", valid_errors);
        $display("Frame count errors:   %0d", count_errors);
        $display("Total errors:         %0d", error_count);

        $display("");
        $display("BRAM SHIFT DIAGNOSTICS");
        $display("--------------------------------------");
        $display("Shifted pixel matches: %0d", shifted_pixel_matches);
        $display("Shifted pixel checks:  %0d", shifted_pixel_checks);
        $display("");
        $display("");
        $display("BRAM ADDRESS ISOLATION");
        $display("--------------------------------------");

        $display("BRAM read requests:    %0d", bram_read_count);
        $display("First valid address:   %0d", first_valid_address);
        $display("Previous valid addr:   %0d", previous_valid_address);
        $display("Last valid address:    %0d", last_valid_address);
        $display("Address sequence errors: %0d", address_sequence_errors);
        $display("Shifted address errors:  %0d", shifted_address_errors);

        $display("");
        $display("DOWNSTREAM ISOLATION RESULTS");
        $display("--------------------------------------");

        $display("Received window checks: %0d", received_window_checks);
        $display("Received window errors: %0d", received_window_errors);
        $display("Received border checks: %0d", received_border_checks);
        $display("Received border errors: %0d", received_border_errors);

        $display("");
        $display("First input cycle:    %0d", first_input_cycle);
        $display("First output cycle:   %0d", first_valid_cycle);
        $display("Frame completed:      %0d", frame_done_seen);

        if (first_valid_cycle >= 0 &&
            first_input_cycle >= 0)
            $display("Startup latency:      %0d cycles",
                first_valid_cycle-first_input_cycle);

        if (output_count != NUM_PIXELS)
            $display(
                "NOTE: Full 76800-pixel output coverage not achieved."
            );

        if (error_count == 0 && output_count > 0)
            $display("RESULT: PASS - Checked stream");
        else
            $display("RESULT: FAIL");

        $display("======================================");

        $finish;
    end

    // =========================================
    // 7. Simulation timeout protection
    // =========================================

    initial begin
        #2000000;
        $fatal(1, "FAIL: Simulation timeout");
    end

endmodule
