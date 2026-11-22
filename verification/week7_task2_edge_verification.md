
# ECE 351 - Week 7 Task 2
## Option C Edge Detection: C Reference Verification

### Objective
Develop and verify a C reference model for the Option C Manhattan gradient edge-detection algorithm. Compare expected software results with the Verilog ALU simulation.

### Algorithm
G = |p01 - p21| + |p10 - p12|

The gradient uses 9 bits, supporting values from 0 to 510.

Edge output:
- 255 when G > threshold
- 0 otherwise

Additional features include pixel inversion, grayscale bypass, border suppression, and valid-signal handling.

### Files
- edge_reference.c: Independent C reference model
- edge_expected_results.txt: Recorded C test results
- ../rtl/edge_threshold_alu.v: Verilog implementation
- ../testbench/tb_edge_alu.v: Vivado testbench

### Verification Results
C reference model:
- 16 data/control test cases
- 16 passed
- 0 failed

Vivado behavioral simulation:
- 18 tests
- 18 passed
- 0 failed
- Includes two additional synchronous-reset tests

### Test Coverage
- Uniform grayscale pixels
- Horizontal and vertical edges
- Maximum gradient of 510
- Threshold equality and threshold + 1
- Zero-gradient conditions
- Pixel inversion
- Grayscale bypass
- Border suppression
- Invalid input cycles

### Conclusion
The C reference model produced the expected results for all 16 test cases. The Verilog implementation independently passed its corresponding data/control checks and two additional reset tests.

These results support the functional correctness of the Option C edge-detection ALU for the tested inputs.

Full-system integration and pipeline synchronization require separate verification.
