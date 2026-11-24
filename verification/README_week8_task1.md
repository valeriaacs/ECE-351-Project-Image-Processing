# Week 8 Task 1 – Full Pipeline Integration and Verification

## Objective

Develop and execute a full-system simulation testbench for the Option C Manhattan Gradient Edge Detection pipeline. Verify BRAM image reading, pixel sequencing, sliding-window generation, gradient calculation, thresholding, border suppression, and pipeline synchronization.

## Completed Work

- Developed `tb_full_pipeline.v` for integrated pipeline verification.
- Developed `coe_to_mem.py` to convert the existing COE image into a Verilog-compatible memory initialization file.
- Generated and verified 76,800 grayscale pixel values representing a 320 × 240 image.
- Developed `bram_image_sim.v` to model synchronous BRAM behavior during behavioral simulation.
- Configured and executed full-frame Vivado XSim simulations.
- Developed independent diagnostic counters to classify verification errors.
- Implemented BRAM address tracking and received-stream reference comparisons.
- Isolated downstream sliding-window behavior from upstream pixel sequencing errors.
- Preserved diagnostic simulation logs.

## Simulation Configuration

| Parameter | Value |
|---|---|
| Simulator | Vivado XSim 2026.1 |
| FPGA target | xc7a35tcpg236-1 |
| Clock frequency | 100 MHz |
| Image dimensions | 320 × 240 |
| Input pixels | 76,800 |
| Pixel depth | 8 bits |
| Threshold | 50 |
| Inversion | Disabled |
| Bypass | Disabled |
| Processing mode | Single frame |
| BRAM model | One-cycle behavioral read |

## Full Pipeline Results

| Measurement | Result |
|---|---:|
| BRAM read requests | 76,800 |
| Valid input pixels | 76,800 |
| Valid windows | 76,158 |
| Processed outputs | 76,158 |
| Correct local ALU outputs | 76,158 |
| Detected edge pixels | 10,268 |
| Startup latency | 646 clock cycles |
| Startup latency at 100 MHz | 6.46 us |
| Frame completed | Yes |

Overall end-to-end verification result: **FAIL — integration defects identified.**

## Independent Error Breakdown

| Error category | Count |
|---|---:|
| BRAM pixel errors | 10,634 |
| X-coordinate errors | 76,800 |
| Y-coordinate errors | 240 |
| Sliding-window errors | 21,789 |
| Border flag errors | 474 |
| Gradient errors | 0 |
| ALU pixel errors | 0 |
| ALU valid timing errors | 0 |
| Expected stream count errors | 0 |
| Total | 109,937 |

The initial simulation reported 99,063 combined errors. The upgraded testbench reports 109,937 independently counted errors because multiple error categories may fail for the same pixel.

## BRAM Reader Isolation

Address tracking confirmed that the first valid memory response corresponds to address 1 instead of address 0. The final memory address is accepted twice under the behavioral BRAM model.

| Measurement | Result |
|---|---:|
| First valid address | 1 |
| Previous valid address | 76,799 |
| Last valid address | 76,799 |
| Address sequence errors | 76,799 |
| Shifted address errors | 0 |
| Shifted pixel matches | 76,799 / 76,799 |

The observed behavior indicates incorrect synchronization between BRAM read responses, the valid signal, and pixel coordinates.

## Downstream Isolation Results

| Verification category | Checks | Errors |
|---|---:|---:|
| Received-stream interior windows | 75,684 | 0 |
| Received-stream border flags | 76,158 | 1 |
| Local ALU comparisons | 76,158 | 0 |

All tested interior sliding windows matched the actual incoming pixel stream. This indicates that the original 21,789 window mismatches resulted from upstream pixel sequencing in this simulation.

The ALU correctly processed every supplied valid window.

One independent border synchronization mismatch occurred at center pixel index 76,478, corresponding to intended coordinates (318, 238).

## Recommended Corrections

1. Correct BRAM reader synchronization so the first valid response corresponds to address 0.
2. Ensure that the final memory address is accepted exactly once.
3. Synchronize X and Y coordinates with the valid pixel response.
4. Investigate border-delay behavior during the final pipeline drain.
5. Establish a defined method for handling the 642 omitted border positions to reconstruct a complete 76,800-pixel image.
6. Repeat end-to-end verification following RTL corrections.
7. Confirm behavior using the actual generated Xilinx BRAM IP and final top-level module.

## Simulation Procedure

From the repository root, generate the memory initialization file using:

`python3 verification/coe_to_mem.py`

Add the required RTL modules, `bram_image_sim.v`, `tb_full_pipeline.v`, and `image_data.mem` to Vivado.

Configure `tb_full_pipeline.v` as SystemVerilog and set `tb_full_pipeline` as the simulation top.

The simulation BRAM model must only be used for behavioral simulation and must not be compiled alongside the actual Xilinx BRAM IP.

Run behavioral simulation for 800 us and examine the verification summary in the Tcl Console.

## Verification Evidence

- `verification/results/week8_pipeline_diagnostics.log`
- `verification/results/week8_pipeline_isolation.log`

## Conclusion

Week 8 Task 1 established a functional full-pipeline verification environment and identified the primary BRAM reader sequencing defect.

The line-buffer and sliding-window path passed all tested received-stream interior comparisons, and the edge threshold ALU passed all 76,158 local output comparisons.

No teammate RTL modules were modified during this investigation.

Individual verification work is substantially complete. Final system acceptance remains pending BRAM reader corrections, border synchronization verification, full-frame coverage, and top-level integration testing. 
