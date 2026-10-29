# ECE 351 — Configurable 3×3 Kernel RTL Interface Contract

## System-facing integration wrapper

**Module:** `kernel_pipeline_3x3`

```verilog
module kernel_pipeline_3x3(
    input  wire        kernel_select,
    input  wire [71:0] pixels_in,
    output wire [8:0]  kernel_mask,
    output wire [71:0] dilation_pixels,
    output wire [71:0] erosion_pixels
);
```

| Port | Direction | Bits | Contract |
|---|---|---|---|
| `kernel_select` | Input | 1 | `0` square; `1` cross. Defined for binary 0 or 1. |
| `pixels_in` | Input | 72 | Nine unsigned 8-bit grayscale pixels in row-major order. |
| `kernel_mask` | Output | 9 | One bit per pixel; 1 indicates inclusion. |
| `dilation_pixels` | Output | 72 | Selected pixel preserved; excluded pixel replaced with 0. |
| `erosion_pixels` | Output | 72 | Selected pixel preserved; excluded pixel replaced with 255. |

There is **no clock, reset, handshake, or `valid` port** in this wrapper. It is combinational. System-level pipeline alignment remains an integration responsibility.

## Submodule contracts

### `configurable_kernel_3x3`

```verilog
module configurable_kernel_3x3(
    input wire kernel_select,
    output wire [8:0] kernel_mask
);
```

Outputs `9'b111_111_111` in square mode and `9'b010_111_010` in cross mode.

### `pixel_selector_3x3`

```verilog
module pixel_selector_3x3(
    input wire [71:0] pixels_in,
    input wire [8:0] kernel_mask,
    output wire [71:0] dilation_pixels,
    output wire [71:0] erosion_pixels
);
```

For each pixel position `i` from 0 through 8 (where `i=0` is P33 and `i=8` is P11), the implementation uses indexed part-select `[i*8 +: 8]` and `kernel_mask[i]` to select or substitute the eight-bit operand. This is bitwise/bytewise operand gating, **not** a max/min reduction.

## Bus-to-pixel mapping

```
P11 = pixels_in[71:64]  / kernel_mask[8]
P12 = pixels_in[63:56]  / kernel_mask[7]
P13 = pixels_in[55:48]  / kernel_mask[6]
P21 = pixels_in[47:40]  / kernel_mask[5]
P22 = pixels_in[39:32]  / kernel_mask[4]
P23 = pixels_in[31:24]  / kernel_mask[3]
P31 = pixels_in[23:16]  / kernel_mask[2]
P32 = pixels_in[15:8]   / kernel_mask[1]
P33 = pixels_in[7:0]    / kernel_mask[0]
```

The two 72-bit outputs use exactly the same byte positions as `pixels_in`.

## Examples

**Input:** `pixels_in = {8'd10,8'd20,8'd30,8'd40,8'd50,8'd60,8'd70,8'd80,8'd90}`.

| Mode | Mask | Dilation operand bytes (P11 to P33) | Erosion operand bytes (P11 to P33) |
|---|---|---|---|
| Square | `1FF` | `10,20,30,40,50,60,70,80,90` | `10,20,30,40,50,60,70,80,90` |
| Cross | `0BA` | `0,20,0,40,50,60,0,80,0` | `255,20,255,40,50,60,255,80,255` |

## Integration checklist for teammates

- [ ] Verify the line-buffer/window generator packs pixels P11→P33 into bits 71→0.
- [ ] Consume `dilation_pixels` and `erosion_pixels` as nine unsigned byte operands.
- [ ] Ensure max/min stages use all nine substituted operands, or a logically equivalent mask-aware reduction.
- [ ] Align `kernel_select` and the pixel window across any register pipeline, so the intended mode is applied to the intended pixel.
- [ ] Define frame/line boundary padding and validity handling in the wider system.
- [ ] Synchronize a physical asynchronous switch into the relevant clock domain before relying on it in a clocked image stream.
- [ ] Agree on any added `valid`, clock or enable ports for a later system wrapper; do not assume they exist in this Task 1 RTL.

## Verification status

- Kernel selector: 2/2 tests passed.
- Pixel selector: 5/5 tests passed.
- Combined wrapper: 6/6 tests passed.
- Latest Vivado linter: zero violations.

These observations cover the specified combinational logic in simulation. They do not yet establish target-board pin assignment, synthesis timing, a VGA image, or hardware performance.
