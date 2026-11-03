# Week 5 – Task 3: Configurable Kernel Verification

## Objective

Develop an initial self-checking Verilog testbench (`tb_kernel.v`) to verify the configurable 3×3 morphological kernel logic.

The testbench verifies both the 9-pixel square kernel and the 5-pixel cross kernel.

## Modules Tested

- `configurable_kernel_3x3.v` – Generates the selected kernel mask.
- `pixel_selector_3x3.v` – Applies the mask to the input pixels.
- `kernel_pipeline_3x3.v` – Integrates the kernel generator and pixel selector.
- `tb_kernel.v` – Applies test patterns and checks expected results.

## Test Cases

The following six input patterns were tested in both kernel modes:

1. Mixed pixel values
2. Uniform pixel matrix (all values equal to 37)
3. Minimum pixel values (all zeros)
4. Maximum pixel values (all 255)
5. Extreme values at the corner positions
6. Extreme values at the cross positions

Each test checks the selected kernel mask, the dilation and erosion pixel buses, and the expected maximum, minimum, and morphological edge values.

Morphological edge values are calculated as:

`Edge = Maximum - Minimum`

## Simulation Results

**Simulation tool:** AMD Vivado 2026.1 (Behavioral Simulation)

| Result | Count |
|---|---:|
| Total tests executed | 12 |
| Tests passed | 12 |
| Tests failed | 0 |

Final simulation output:

```text
Tests run: 12
Tests failed: 0
ALL KERNEL TESTS PASSED
```

## Verification Scope

The simulation confirms that the configurable kernel correctly selects pixels for square and cross configurations.

Excluded pixels are replaced with zero for dilation and 255 for erosion.

The current RTL produces masked pixel buses. The testbench calculates maximum, minimum, and edge results from these buses for verification. Hardware modules that perform these final arithmetic operations are not yet verified by this testbench.

## Conclusion

Week 5 Task 3 successfully established an initial self-checking simulation environment for the configurable 3×3 kernel.

All 12 test cases passed without failures. The testbench provides a foundation for future integration testing and verification of the complete morphological edge detection pipeline.
