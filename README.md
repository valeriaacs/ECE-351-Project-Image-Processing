
# ECE 351 — Morphological Edge Detection

## Project Overview

This project implements a real-time morphological edge detector
using Verilog on the Digilent Basys 3 FPGA development board.

The system is designed to process 8-bit grayscale images using
3x3 morphological operations and display the resulting image
through a VGA interface.

Target FPGA: Xilinx Artix-7 XC7A35T
Vivado Part: xc7a35tcpg236-1

## Project Structure

- `rtl/` — Verilog hardware design modules
- `testbench/` — Verilog simulation testbenches
- `docs/` — Architecture and interface documentation
- `verification/` — Simulation screenshots and results

## Week 5 — Configurable Kernel Architecture

The configurable kernel supports two structuring elements:

### Square Kernel

- `kernel_select = 0`
- Mask: `9'b111_111_111`
- All nine pixels are selected.

### Cross Kernel

- `kernel_select = 1`
- Mask: `9'b010_111_010`
- The center pixel and four orthogonal neighbors are selected.

## Implemented Modules

### configurable_kernel_3x3.v

Generates the 9-bit kernel mask based on the switch input.

### pixel_selector_3x3.v

Accepts nine 8-bit grayscale pixels and the selection mask.

Excluded pixels are replaced with:
- `8'h00` for dilation inputs.
- `8'hFF` for erosion inputs.

### kernel_pipeline_3x3.v

Combines the kernel generator and pixel selector into
one combinational integration wrapper.

Despite the module name, no clocked pipeline registers
are included at this stage.

## Verification Results

Behavioral simulations were performed using Vivado 2026.1.

| Testbench | Tests Passed |
|---|---|
| tb_configurable_kernel_3x3.v | 2/2 |
| tb_pixel_selector_3x3.v | 5/5 |
| tb_kernel_pipeline_3x3.v | 6/6 |
| Total | 13/13 |

The final Vivado linter check reported zero violations.

These results verify kernel-mask generation, pixel selection,
and integration behavior. They do not establish physical
FPGA timing or complete morphological edge detection.

## Documentation

- [Kernel Architecture](docs/kernel_architecture.md)
- [Kernel Interface](docs/kernel_interface.md)

## Verification Evidence

- [Kernel Selection Waveform](verification/kernel_selection_waveform.png)
- [Pixel Selector Tests](verification/pixel_selector_test_results.png)
- [Kernel Integration Tests](verification/kernel_integration_test_results.png)

## Future Integration

The configurable kernel will be integrated with the team's
3x3 image window generator, erosion and dilation cores,
BRAM/image reader, and VGA display pipeline.

Full hardware integration and timing verification are
separate project milestones.
