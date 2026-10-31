module test_comparator;
    reg  [1:0] cell_a;
    reg  [1:0] cell_b;
    wire       edge_valid;

    // Helper wires to fix the $monitor expression issue
    wire [2:0] val_a = cell_a + 1'b1;
    wire [2:0] val_b = cell_b + 1'b1;

    // Edge Comparator Logic: Inequality (NE) AND Sum-Not-6 (No 2 + 4 = 6)
    wire ne       = (cell_a[1] ^ cell_b[1]) | (cell_a[0] ^ cell_b[0]);
    wire sum_is_6 = (cell_a[1] ^ cell_b[1]) & (cell_a[0] & cell_b[0]);
    wire not_6    = ~sum_is_6;
    assign edge_valid = ne & not_6;

    initial begin
        $monitor("Time=%0t | Cell A=%d (%b) | Cell B=%d (%b) | Valid=%b", 
                 $time, val_a, cell_a, val_b, cell_b, edge_valid);

        // Case 1: Same values (1, 1) -> Invalid (Fails NE)
        cell_a = 2'b00; cell_b = 2'b00; #10;

        // Case 2: Valid distinct values (1, 2) -> Valid
        cell_a = 2'b00; cell_b = 2'b01; #10;

        // Case 3: Sum equals 6 (2, 4) -> Invalid (Fails Sum-Not-6)
        cell_a = 2'b01; cell_b = 2'b11; #10;

        // Case 4: Valid distinct values (3, 4) -> Valid
        cell_a = 2'b10; cell_b = 2'b11; #10;

        $finish;
    end
endmodule