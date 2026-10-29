# ECE 351 — Configurable 3×3 Kernel Architecture

## Purpose and scope

The configurable structuring element supports a **3×3 square mask** (nine pixels) and a **3×3 cross mask** (center plus four orthogonal neighbors). It prepares an 8-bit grayscale pixel window for subsequent morphological dilation and erosion. This Task 1 design **does not** compute a maximum, minimum, edge gradient, VGA output, or line-buffer address.

## Pixel ordering

Each pixel is an unsigned eight-bit grayscale value (0–255). The 72-bit input window is packed in row-major order, with the top-left pixel at the most-significant byte:

| Position | Pixel | `pixels_in` bits | `kernel_mask` bit |
|---|---|---|---|
| Top-left | P11 | `[71:64]` | `[8]` |
| Top-center | P12 | `[63:56]` | `[7]` |
| Top-right | P13 | `[55:48]` | `[6]` |
| Middle-left | P21 | `[47:40]` | `[5]` |
| Center | P22 | `[39:32]` | `[4]` |
| Middle-right | P23 | `[31:24]` | `[3]` |
| Bottom-left | P31 | `[23:16]` | `[2]` |
| Bottom-center | P32 | `[15:8]` | `[1]` |
| Bottom-right | P33 | `[7:0]` | `[0]` |

```
  P11 P12 P13        mask[8] mask[7] mask[6]
  P21 P22 P23   <=>  mask[5] mask[4] mask[3]
  P31 P32 P33        mask[2] mask[1] mask[0]
```

## Masks and control

| `kernel_select` | Mode | Binary mask | Hex mask | Selected pixels |
|---|---|---|---|---|
| `1'b0` | Square | `9'b111_111_111` | `9'h1FF` | All nine |
| `1'b1` | Cross | `9'b010_111_010` | `9'h0BA` | P12, P21, P22, P23, P32 |

A mask bit of one selects the corresponding pixel; zero excludes it.

## Pixel-selection behavior

The pixel selector takes each eight-bit input pixel and applies these rules:

- **Dilation input:** preserve selected pixels; substitute `8'h00` for excluded pixels.
- **Erosion input:** preserve selected pixels; substitute `8'hFF` for excluded pixels.

The substituted constants are neutral for maximum/minimum reductions on **unsigned eight-bit** data, because the supported masks always include the center pixel:

```
Dilation = max(dilation_pixels[0], ..., dilation_pixels[8])
Erosion  = min(erosion_pixels[0], ..., erosion_pixels[8])
Gradient = Dilation - Erosion
```

The latter calculations belong to downstream cores and are **not implemented here**.

For example, with pixels `[10,20,30;40,50,60;70,80,90]`, cross mode creates dilation inputs `[0,20,0;40,50,60;0,80,0]` and erosion inputs `[255,20,255;40,50,60;255,80,255]`.

## RTL component responsibilities

1. **`configurable_kernel_3x3.v`**: combinational mapping from `kernel_select` to `kernel_mask`.
2. **`pixel_selector_3x3.v`**: combinational nine-way selection of the pixel bytes into 72-bit dilation/erosion operand buses, using `kernel_mask`.
3. **`kernel_pipeline_3x3.v`**: combinational integration wrapper instantiating both modules and exposing their interface.

```
Physical switch / synchronized selection bit   3×3 pixel window generator
                    |                                    |
              kernel_select                         pixels_in[71:0]
                    |                                    |
         configurable_kernel_3x3                        |
                    |                                    |
              kernel_mask[8:0]                          |
                    +------------+-----------------------+
                                 |
                         pixel_selector_3x3
                                 |
                   +-------------+-------------+
                   |                           |
           dilation_pixels[71:0]      erosion_pixels[71:0]
                   |                           |
             maximum core                 minimum core
                   +-------------+-------------+
                                 |
                        gradient / output stage
```

**Note:** The name `kernel_pipeline_3x3` does not imply registered stages. The RTL is purely combinational; no clock, reset, or latency registers exist inside the three Task 1 modules.

## Verification evidence (observed in Vivado 2026.1 screenshots)

| Testbench | Tests passed | Purpose | Simulated end time |
|---|---:|---|---:|
| `tb_configurable_kernel_3x3.v` | 2/2 | Square/cross mask generation | 20 ns |
| `tb_pixel_selector_3x3.v` | 5/5 | Pixel preservation, corner exclusion, zero, 255 and uniform windows | 50 ns |
| `tb_kernel_pipeline_3x3.v` | 6/6 | Connected selector, both modes, switching back, uniform and extreme windows | 60 ns |

The refreshed Vivado linter reported **zero violations**. The 13 passing checks establish the sampled **behavioral correctness of the specified mask and operand-selection path**, not exhaustive proof, measured propagation delay, or functional verification of max/min and gradient hardware. The displayed simulation times are testbench durations.

## Integration requirements and limitations

- Downstream modules must agree on the byte and mask-bit ordering in the mapping table.
- Input values are unsigned 8-bit grayscale pixels.
- The 72-bit outputs are *nine 8-bit operands*, not already reduced morphological results.
- The external control switch should be synchronized/debounced as appropriate at the system level. If the pixel path is pipelined, align the selected kernel mode with the corresponding pixel window.
- Pixel-valid signaling, boundary padding, clock-domain treatment, and registration are handled outside these modules and must be agreed upon with teammates.
- No complete BRAM/VGA display or physical Basys 3 test is claimed by these unit/integration simulations.

## Environment

- Vivado 2026.1, behavioral simulation in XSim
- Target board: Digilent Basys 3
- FPGA part configured: `xc7a35tcpg236-1` (Artix-7 XC7A35T)
