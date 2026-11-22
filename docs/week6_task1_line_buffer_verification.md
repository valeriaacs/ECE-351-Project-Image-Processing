# ECE 351 — Week 6, Task 1: Line Buffer and Sliding Window Verification

## Scope
Verify the integration of `line_buffer.v` and `sliding_window_3x3.v` using a small, known grayscale image. Test pixel ordering, 3×3 window formation, and image-row boundary behavior in Vivado 2026.1.

## Files
- `testbench/tb_line_buffer.v` — Self-checking behavioral testbench; drives pixels and reports PASS/FAIL.
- `rtl/window_valid_guard.v` — Proposed *experimental* boundary-validity guard, tested separately; **not integrated into the production pipeline**.
- Existing team modules (unchanged):
  - `Jose's ECE_351_Image_Edge_Detction/rtl/line_buffer.v`
  - `valeria_pipeline/sliding_window_3x3.v`

## Test configuration
- Image: 5 × 5 pixels, row-major values 1 through 25.
- Pixel format: 8-bit unsigned grayscale.
- Clock period: 10 ns.
- Line-buffer parameters: `IMAGE_WIDTH=5`, `ADDR_WIDTH=3`.
- Validity-guard parameters: `IMAGE_WIDTH=5`, `ADDR_WIDTH=3`.
- Continuous valid pixel input, followed by pipeline flush time.
- Testbench samples outputs on the falling clock edge.

Example valid 3×3 window:

```text
 1  2  3
 6  7  8
11 12 13
```

## Results
| Check | Observed |
|---|---:|
| Raw windows signaled valid by sliding window | 13 |
| Proper 3×3 windows accepted by test guard | 9 |
| Row-crossing windows rejected by test guard | 4 |
| Errors detected by testbench | 0 |
| Result | PASS for the tested 5×5 scenario |

Invalid raw windows were detected at 230 ns, 240 ns, 280 ns, and 290 ns. Correctly aligned windows were accepted at all nine spatial positions.

Final Vivado simulation output:

```text
WEEK 6 TASK 1 RESULTS
Accepted windows: 9
Rejected windows: 4
Errors: 0
PASS: All verification checks passed.
```

The testbench reports a fatal simulation error if its expected counts or pixel checks fail.

## Important finding
The original sliding-window `valid_out` remains active across image-row boundaries after its initial column-fill period. In the 5×5 test, this allowed four row-crossing windows to be flagged valid. The separate `window_valid_guard.v` suppresses those four cases without changing either teammate's module.

This **does not** establish that the full team's hardware pipeline is corrected: `window_valid_guard.v` is currently only instantiated in `tb_line_buffer.v`. The production `pipeline_datapath.v` has an `is_border_out` output intended for border handling; its latency alignment and downstream use have **not** been verified by this test.

## Reproduce in Vivado
1. Add `line_buffer.v`, `sliding_window_3x3.v`, and `window_valid_guard.v` as Design Sources.
2. Add `tb_line_buffer.v` as a Simulation Source.
3. Set `tb_line_buffer` as the simulation top.
4. Run Behavioral Simulation and inspect the Tcl Console summary.

## Limits / follow-up
- Only one 5×5 sequential grayscale pattern was used for Task 1.
- Pixel-value patterns with zeros, 255s, uniform values, and interrupted `pixel_valid` require separate verification.
- Full 320×240 operation, continuous frame transitions, and production `is_border_out` behavior remain unverified.
- Do not replace teammates' source modules or integrate this proposed guard into production until the team agrees on border-handling ownership.

**Conclusion:** Week 6 Task 1's initial module-level integration and pixel-alignment verification is complete for the 5×5 diagnostic case. Production border handling is a documented follow-up.
