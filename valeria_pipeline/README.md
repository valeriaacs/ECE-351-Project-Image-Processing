# Valeria's Pipeline Subsystem (`valeria_pipeline/`)

**Owner:** Valeria Yanez  
**Course:** ECE 351 – Digital Logic & FPGA Design  
**Target Hardware:** Digilent Basys 3 (Xilinx Artix-7 XC7A35T)  

## Overview
This directory contains the host-side image pre-processing toolchain, on-chip Block RAM (BRAM) memory interface, Finite State Machine with Data Path (FSMD) memory controller, and 3x3 sliding window buffer for our pipelined Manhattan gradient edge-detection system.

## Directory Contents (8 Core Files)

| File | Type | Description |
| :--- | :--- | :--- |
| **`image_to_coe.c`** | C Source | Host-side utility that converts an input image into a $320 x 240 8-bit grayscale `.coe` file. |
| **`stb_image.h`** | C Header | Single-header image decoding library used by `image_to_coe.c` to load PNG/JPG files. |
| **`sample.png`** | Image Asset | Sample 320 x 240 grayscale test image used to generate initial BRAM contents. |
| **`image_data.coe`** | Xilinx Memory File | 76,800-entry hex memory initialization file (320 x 240 pixels) for the FPGA Block RAM IP. |
| **`bram_image_wrapper.v`** | Verilog RTL | Top-level wrapper around the Xilinx Block Memory Generator IP (`bram_image`). |
| **`bram_reader_fsm.v`** | Verilog RTL | FSMD controller that sequentially reads pixel addresses (`0` to `76,799`) from BRAM with latency-aligned `valid_out`. |
| **`sliding_window_3x3.v`** | Verilog RTL | Shift-register line-buffer generator streaming three adjacent rows to output a 3x3 neighborhood (`p00`–`p22`) every clock cycle. |
| **`tb_bram_reader.v`** | Verilog Testbench | Behavioral simulation testbench verifying BRAM address sequencing and frame completion signals. |

## Signal Flow
```text
[sample.png] ──(image_to_coe.c)──> [image_data.coe] ──> [bram_image_wrapper.v]
                                                                │
                                                        (bram_reader_fsm.v)
                                                                ▼
                                                     [sliding_window_3x3.v] ──> p00..p22 (to Edge ALU)