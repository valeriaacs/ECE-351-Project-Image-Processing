# ECE 351 — Week 5, Task 2: C Morphological Reference Model

## Overview

This directory contains the software reference model developed for Week 5, Task 2 of the ECE 351 Real-Time Pipelined Morphological Edge Detector project.

The purpose of the reference model is to calculate expected morphological processing results using C, independently of the FPGA hardware implementation.

These results provide a software reference for verifying the dilation, erosion, and edge detection operations implemented later in Verilog and simulated using AMD Vivado.

**Responsible role:** Student C — Kernel Design, Verification & Performance Analysis

## 1. Objectives

The objectives of Week 5, Task 2 were to:

- Develop a C-based software reference model (`morph_reference.c`).
- Implement morphological dilation using the maximum selected pixel value.
- Implement morphological erosion using the minimum selected pixel value.
- Calculate the morphological edge as dilation minus erosion.
- Support both the 3×3 square kernel and the cross kernel.
- Test the software model using multiple predefined 3×3 grayscale pixel matrices.
- Generate expected results for use in future Verilog verification.

## 2. Kernel Configurations

Two configurable 3×3 structuring elements are supported.

### Square Kernel (Mode 0)

```text
1 1 1
1 1 1
1 1 1
```

The square kernel selects all nine pixels within the 3×3 neighborhood.

### Cross Kernel (Mode 1)

```text
0 1 0
1 1 1
0 1 0
```

The cross kernel selects five pixels: the center, top, bottom, left, and right.

The four corner pixels are excluded.

These configurations correspond to the selectable kernel architecture developed in Week 5, Task 1.

## 3. Morphological Operations

The C reference model performs three operations.

### Dilation

Dilation selects the maximum pixel value within the active kernel.

**Dilation = MAX(selected pixels)**

### Erosion

Erosion selects the minimum pixel value within the active kernel.

**Erosion = MIN(selected pixels)**

### Morphological Edge Detection

The morphological edge value is calculated by subtracting erosion from dilation.

**Edge = Dilation − Erosion**

All test pixels use 8-bit grayscale values ranging from 0 to 255.

## 4. Software Implementation

The reference model is implemented in `morph_reference.c` using standard C.

Its primary calculation function is:

```c
void morph_calculate(
    const int pixels[SIZE][SIZE],
    int kernel_mode,
    int *dilation,
    int *erosion,
    int *edge
);
```

The function accepts a 3×3 pixel matrix and a kernel selection mode.

It iterates through all nine pixel positions, determines whether each pixel is included in the selected kernel, and calculates the minimum and maximum selected values.

The results are stored through output pointers supplied by the calling function.

The main program automatically executes both kernel configurations for each predefined test matrix.

## 5. Test Cases

Five test matrices were implemented.

| Test | Description |
|---|---|
| 1 | Increasing grayscale values |
| 2 | Uniform grayscale values |
| 3 | Extreme values located in the corners |
| 4 | Maximum grayscale value at the center |
| 5 | All pixels at maximum grayscale intensity |

These tests evaluate correct pixel selection, minimum and maximum calculations, and the behavior of uniform and extreme grayscale values.

## 6. Expected Results

The C reference model produced the following results.

| Test | Kernel | Dilation | Erosion | Edge |
|---|---|---:|---:|---:|
| Increasing values | Square | 90 | 10 | 80 |
| Increasing values | Cross | 80 | 20 | 60 |
| Uniform values | Square | 100 | 100 | 0 |
| Uniform values | Cross | 100 | 100 | 0 |
| Corner extremes | Square | 255 | 0 | 255 |
| Corner extremes | Cross | 50 | 50 | 0 |
| Center maximum | Square | 255 | 0 | 255 |
| Center maximum | Cross | 255 | 0 | 255 |
| All maximum values | Square | 255 | 255 | 0 |
| All maximum values | Cross | 255 | 255 | 0 |

All ten calculated output combinations matched the manually determined expected values.

### Important Verification Result

The corner-extremes test demonstrates the difference between the two kernel configurations.

The square kernel includes the corner values of 0 and 255 and therefore produces an edge value of 255.

The cross kernel ignores the corners. All five selected pixels have a value of 50, resulting in an edge value of 0.

This confirms the intended behavior of the software kernel-selection logic for this test.

## 7. Build Instructions

The program was developed and compiled using GCC in Ubuntu under Windows Subsystem for Linux (WSL).

From the repository root directory, compile using:

```bash
gcc -std=c11 -Wall -Wextra -pedantic verification/morph_reference.c -o verification/morph_reference
```

Execute the program using:

```bash
./verification/morph_reference
```

The program prints the dilation, erosion, and morphological edge results for both kernel configurations across all five test matrices.

To regenerate the expected-results file:

```bash
./verification/morph_reference > verification/expected_results.txt
```

## 8. Verification Status

The program compiled successfully with GCC using the specified warning and standards flags.

All five sample matrices were processed using both kernel configurations, producing ten output combinations.

The observed software outputs matched the expected values.

These results verify the C reference model for the included test cases. They do not yet establish the correctness of the corresponding FPGA implementation.

## 9. Files

- `morph_reference.c` — C software reference implementation.
- `expected_results.txt` — Recorded software reference outputs for all test cases.
- `README.md` — Description, implementation details, testing instructions, and results.
- `kernel_integration_test_results.png` — Existing kernel integration simulation evidence.
- `kernel_selection_waveform.png` — Existing kernel selection waveform evidence.
- `pixel_selector_test_results.png` — Existing pixel selection simulation evidence.

## 10. Future Verification Work

The software reference model will support future stages of the project.

In subsequent tasks, expected values will be compared against Vivado simulation outputs to verify the configurable kernel and morphological processing hardware.

The reference results can also help identify incorrect pixel selection, comparator behavior, or edge subtraction when integrating the complete FPGA processing pipeline.

## Conclusion

Week 5, Task 2 established a functional C-based morphological processing reference model supporting square and cross structuring elements.

The program successfully calculates dilation, erosion, and morphological edge detection for five predefined 3×3 grayscale matrices.

The resulting ten reference-output combinations provide an initial verification baseline for the project's Verilog implementation.
