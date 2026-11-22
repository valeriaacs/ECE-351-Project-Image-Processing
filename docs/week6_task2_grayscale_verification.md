# ECE 351 — Week 6, Task 2: Grayscale Matrix Verification

## Purpose
Verify the line-buffer and 3×3 sliding-window path using predefined 5×5 grayscale images, as preparation for the simplified **Option C edge-thresholding pipeline**. The Option C arithmetic stage uses the neighboring pixels to compute:

`G = |p01 - p21| + |p10 - p12|`

This task tests window formation and validity; it does **not** test the edge-threshold arithmetic stage.

## Files and setup
- Testbench: `testbench/tb_line_buffer_cases.v`
- Existing line buffer: `Jose's ECE_351_Image_Edge_Detction/rtl/line_buffer.v`
- Existing sliding window: `valeria_pipeline/sliding_window_3x3.v`
- Experimental boundary filter: `rtl/window_valid_guard.v`
- Simulator: Vivado 2026.1 XSim, behavioral simulation
- Test image dimensions: 5×5; pixels are unsigned 8-bit grayscale (0–255)
- Clock: 10 ns period

The testbench generates a reference image array and compares all nine output pixel values for each valid window against positions calculated from the reference array. The testbench separately checks raw window counts, accepted/rejected windows, and guard validity.

## Tests executed

| ID | Stimulus | Result |
|---|---|---|
| 0 | Sequential grayscale values 1–25 | PASS |
| 1 | All pixels equal 0 | PASS |
| 2 | All pixels equal 255 | PASS |
| 3 | Mixed grayscale values (including 0 and 255) | PASS |
| 4 | Mixed grayscale values with pauses in `pixel_valid` | PASS |

Each test produced:
- **13 raw windows** identified by the sliding-window module
- **9 accepted spatially valid windows**
- **4 row-crossing windows rejected by the experimental guard**
- **0 reported errors**

Across five tests: **45 accepted**, **20 rejected**, **0 reported errors**.

The first and last accepted windows are covered by the per-window pixel comparisons (raw window indices 0 and 12). The software-style reference consists of expected pixels read from an independently indexed testbench image array.

## Observed simulator outcome

After continuing the behavioral simulation with the Tcl command `run all`, the output reached:

```text
Raw windows: 13
Accepted: 9
Rejected: 4
Errors: 0
TEST 4 PASSED
==========================
ALL WEEK 6 TASK 2 TESTS PASSED
==========================
```

Simulation finished at **2060 ns**.

## Finding and limitations
The original `sliding_window_3x3.v` marks row-crossing windows valid; `window_valid_guard.v` rejects them in these 5×5 tests. This guard is **experimental and used in the testbench only**. This result does not establish correctness of the production pipeline's `is_border_out` signal or its downstream handling.

The testbench checks expected window order and guard validity on cycles when the sliding window reports `window_valid`. It does not yet exhaustively assert cycle-by-cycle valid-signal behavior, latency under every stall pattern, full 320×240 image operation, or repeated frame boundaries. These remain integration follow-ups.

## Reproduction
1. Add the three design modules (`line_buffer.v`, `sliding_window_3x3.v`, `window_valid_guard.v`) to a Vivado project.
2. Add `tb_line_buffer_cases.v` under Simulation Sources and set `tb_line_buffer_cases` as simulation top.
3. Run **Behavioral Simulation**.
4. In the Tcl Console, run `run all` if the default 1000 ns simulation stops before the testbench completes.
5. Verify that tests 0–4 pass and the final overall PASS message appears.

## Conclusion
**Week 6 Task 2 is complete for the defined functional 5×5 simulation suite.** All five tests passed and the results are recorded here. Detailed timing coverage and full production border handling are deferred, not claimed as verified.
