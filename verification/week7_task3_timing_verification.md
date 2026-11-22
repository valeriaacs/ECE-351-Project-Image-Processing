# ECE 351 — Week 7 Task 3
## Option C Edge ALU Timing Verification

### Objective
Verify the synchronous reset behavior, valid-signal propagation, pipeline latency, and output synchronization of the Option C Manhattan Gradient Edge Detection ALU.

### Verilog Files
- `rtl/edge_threshold_alu.v` — Edge-detection hardware module
- `testbench/tb_edge_timing.v` — Dedicated timing verification testbench
- `testbench/tb_edge_alu.v` — Original functional verification testbench

### Timing Architecture
The ALU computes the Manhattan gradient:

G = |p01 - p21| + |p10 - p12|

The gradient is represented using 9 bits, supporting values from 0 to 510.

The ALU contains one registered output stage. Inputs applied before a rising clock edge are sampled at that edge, and the corresponding registered outputs update immediately afterward in simulation.

The outputs are:
- `gradient_out` — Calculated 9-bit gradient
- `pixel_out` — Processed 8-bit pixel
- `valid_out` — Indicates valid output data

### Verification Tests
The dedicated timing testbench verifies:

1. Initial synchronous reset
2. Consecutive valid input processing
3. Horizontal and vertical edge calculations
4. Invalid input cycles
5. Recovery after invalid input
6. Threshold equality (G = T)
7. Threshold boundary (G = T + 1)
8. Maximum gradient of 510
9. Maximum 8-bit threshold of 255
10. Pixel inversion
11. Grayscale bypass with inversion
12. Border suppression
13. Reset after active processing
14. Recovery following reset
15. Output alignment with clock edges

### Simulation Results
Simulator: AMD Vivado 2026.1 XSim

- Tests executed: 15
- Tests passed: 15
- Tests failed: 0
- Simulation completion time: 146 ns
- Testbench result: PASS — ALL TIMING TESTS PASSED

### Pipeline Latency
The edge ALU uses a single registered output stage.

The simulation confirmed that outputs do not update prematurely between clock edges. Gradient, pixel, and valid outputs update together following the appropriate rising clock edge.

Consecutive valid inputs were processed without observed output misalignment in the tested sequence.

This verifies the ALU's module-level latency, not the latency of the full image-processing pipeline.

### Conclusion
Week 7 Task 3 successfully verified the edge ALU's registered timing behavior, valid-signal propagation, synchronous reset, and output alignment.

All 15 dedicated timing tests passed in Vivado XSim.

Full-system BRAM, sliding-window, and output timing synchronization remain separate integration responsibilities.
