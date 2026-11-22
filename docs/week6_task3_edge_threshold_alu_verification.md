# ECE 351 — Week 6, Task 3 Verification Report
## Option C: Manhattan Gradient Edge Threshold ALU

**Student responsibility:** Arithmetic and verification  
**Design file:** `rtl/edge_threshold_alu.v`  
**Testbench:** `testbench/tb_edge_alu.v`  
**Tool:** AMD Vivado 2026.1 — XSim behavioral simulation  
**Status:** Standalone functional verification PASSED; full-pipeline integration pending

---

## 1. Objective

Implement and verify the proposed Option C edge-processing arithmetic module, replacing the earlier planned `kernel_select.v` work. The module receives selected pixels from the 3×3 sliding-window pipeline, calculates a Manhattan gradient, compares it against a user-adjustable threshold, and produces a binary edge pixel. The initial implementation also includes configurable inversion, grayscale bypass, border suppression, and registered output validity.

## 2. Algorithm

The edge magnitude approximation uses the four orthogonal neighbors of center pixel `p11`:

```text
G = |p01 - p21| + |p10 - p12|
```

Each absolute difference is 0–255. Their sum is 0–510, requiring **9 bits**.

The thresholded edge output is:

```text
edge = (G > T) ? 8'hFF : 8'h00
```

The comparison is **strictly greater than**: when `G == T`, the result is 0. The threshold input is 8 bits (0–255), while the gradient supports values as high as 510. This means sufficiently large gradients remain above threshold even when `T = 255`.

## 3. Current module interface

| Port | Direction / width | Purpose |
|---|---|---|
| `clk` | input, 1 bit | Clock |
| `reset` | input, 1 bit | Active-high synchronous reset |
| `valid_in` | input, 1 bit | Input pixel-window validity |
| `is_border` | input, 1 bit | Border indicator, assumed aligned with window |
| `p01` | input, 8 bits | Top neighbor |
| `p10` | input, 8 bits | Left neighbor |
| `p11` | input, 8 bits | Center pixel (bypass value) |
| `p12` | input, 8 bits | Right neighbor |
| `p21` | input, 8 bits | Bottom neighbor |
| `threshold` | input, 8 bits | Threshold intended for `SW[7:0]` |
| `invert_en` | input, 1 bit | Inversion intended for `SW[14]` |
| `bypass_en` | input, 1 bit | Grayscale bypass intended for `SW[15]` |
| `gradient_out` | output reg, 9 bits | Registered gradient |
| `pixel_out` | output reg, 8 bits | Registered selected output pixel |
| `valid_out` | output reg, 1 bit | Registered validity |

**Output selection order in this proposed implementation:**
1. Compute binary edge pixel from gradient and threshold.
2. Select `p11` when bypass is enabled, otherwise select edge pixel.
3. Apply inversion if enabled.
4. When `is_border` is asserted **and bypass is disabled**, override the output with black (`8'h00`), even if inversion is enabled.
5. Register the result on the next rising clock edge.

On reset, `gradient_out`, `pixel_out`, and `valid_out` become zero. On invalid input, the design deasserts `valid_out` and clears the data outputs. This is the behavior of the current standalone RTL, not a confirmed requirement of the full production pipeline.

## 4. Verification approach and results

`tb_edge_alu.v` independently computes expected differences, gradient, output selection, and validity, then checks the module's registered outputs after a rising edge.

The standalone XSim run reported:

```text
WEEK 6 TASK 3 - EDGE ALU RESULTS
Tests run: 18
Tests failed: 0
PASS: ALL EDGE ALU TESTS PASSED
```

**Observed simulation finish time:** 176 ns.

### Cases exercised

| Category | Tested behavior |
|---|---|
| Uniform grayscale | Gradient 0, no detected edge |
| Horizontal transition | Nonzero vertical difference |
| Vertical transition | Nonzero horizontal difference |
| Maximum-difference case | Gradient 510 |
| Strict threshold | `G = T` returns 0 |
| Threshold boundary | `G = T + 1` returns 255 |
| Minimum threshold | `G = 0, T = 0` and `G = 1, T = 0` |
| Inversion | Detected-edge and no-edge output inversion |
| Grayscale bypass | Center pixel appears at output |
| Inverted bypass | Bitwise complement of center pixel |
| Border handling | Border output forced black in edge mode, including with inversion |
| Border with bypass | Center pixel remains available in bypass mode |
| Validity | Invalid cycle produces `valid_out = 0` and zeroed outputs |
| Reset | Initial reset and reset after activity |

These cases, together with reset checks, make up **18 passing checks**.

## 5. Relation to Week 6 Tasks 1 and 2

The earlier tests established a working 5×5 line-buffer/sliding-window verification baseline using sequential and predefined grayscale matrices. The separate experimental `window_valid_guard.v` filtered four row-crossing raw windows in those tests.

The ALU testbench exercises `edge_threshold_alu.v` **independently**, using directly supplied pixel values. It does not yet prove correct end-to-end behavior when the ALU is connected to `pipeline_datapath.v`.

## 6. Integration decisions still requiring team agreement

1. **Module ownership and naming:** The current file is `edge_threshold_alu.v` and the testbench is `tb_edge_alu.v`.
2. **Validity source:** Determine whether `valid_in` should be the raw `window_valid` or a qualified border/window-valid signal.
3. **Border timing:** Confirm that `pipeline_datapath.v`'s `is_border_out` is cycle-aligned with the relevant center pixel and that the one-cycle ALU output register is accounted for.
4. **Switch mapping:** Confirm `SW[7:0]` to `threshold`, `SW[14]` to `invert_en`, and `SW[15]` to `bypass_en`.
5. **Inversion and bypass semantics:** Confirm whether inversion applies to both edge and grayscale bypass modes, and whether borders stay black when inversion is enabled.
6. **Final timing and full-frame verification:** Validate the assembled pipeline, repeated frames, and the 320×240 image path during integration.

The tests reported here **do not** establish final hardware timing closure, FPGA resource usage, VGA operation, or correctness of the integrated `is_border_out` logic.

## 7. Reproduction in Vivado

1. Add `rtl/edge_threshold_alu.v` as a Design Source.
2. Add `testbench/tb_edge_alu.v` as a Simulation Source.
3. Set `tb_edge_alu` as the simulation top.
4. Run **Behavioral Simulation** in XSim.
5. Confirm the final summary reports 18 tests, zero failures, and overall PASS.

## 8. Conclusion

**Week 6 Task 3's initial working implementation and standalone functional verification are complete.** The Option C Manhattan gradient, strict thresholding, optional inversion and bypass, border control, and registered valid behavior passed the 18-case testbench. The module is ready for interface review with teammates and subsequent full-pipeline integration; those integration checks remain open.
