/*
 * ECE 351 - Week 7, Task 2
 * Option C: Independent C reference for the Manhattan-gradient edge ALU.
 *
 * This program preserves the original morph_reference.c by using a new file.
 * It reproduces the 16 data/control cases in testbench/tb_edge_alu.v.
 * The Verilog testbench also checks two synchronous reset events; those are
 * clocked-hardware checks rather than pixel calculations in this C model.
 *
 * Compiling:
 *   gcc -std=c11 -Wall -Wextra -pedantic edge_reference.c -o edge_reference
 * Running:
 *   ./edge_reference
 */

#include <stdio.h>

#define N_TESTS 16

typedef struct {
    const char *name;
    int px[3][3];      /* p00..p22, row-major, grayscale 0..255 */
    int threshold;     /* SW[7:0], 0..255 */
    int invert_en;     /* SW[14]: invert final selected pixel */
    int bypass_en;     /* SW[15]: show center grayscale instead of edge */
    int is_border;     /* force black in edge mode at image borders */
    int valid_in;      /* zero results when window is invalid */
    int expected_g;    /* expected result from the Verilog test vectors */
    int expected_pixel;
    int expected_valid;
} test_case_t;

typedef struct {
    int gradient;      /* 9 bits: 0..510 */
    int pixel;         /* 8 bits: 0..255 */
    int valid;
} edge_result_t;

/* Return the absolute difference of two 8-bit grayscale values. */
static int difference(int a, int b)
{
    return (a >= b) ? (a - b) : (b - a);
}

/* Independently calculate what the Verilog edge_threshold_alu should output. */
static edge_result_t calculate_edge(const test_case_t *t)
{
    edge_result_t result = {0, 0, 0};

    if (!t->valid_in)
        return result;

    /* Only these 5 positions are used by the Option C algorithm. */
    int top    = t->px[0][1];  /* p01 */
    int left   = t->px[1][0];  /* p10 */
    int center = t->px[1][1];  /* p11 */
    int right  = t->px[1][2];  /* p12 */
    int bottom = t->px[2][1];  /* p21 */

    int vertical_diff   = difference(top, bottom);
    int horizontal_diff = difference(left, right);
    result.gradient = vertical_diff + horizontal_diff;

    /* Strict comparison: equal to the threshold is NOT an edge. */
    result.pixel = (result.gradient > t->threshold) ? 255 : 0;

    /* Select original center pixel in grayscale passthrough mode. */
    if (t->bypass_en)
        result.pixel = center;

    /* Invert all 8 bits, equivalent to Verilog's ~selected_pixel. */
    if (t->invert_en)
        result.pixel = 255 - result.pixel;

    /* Border suppression applies to edge mode, not grayscale bypass. */
    if (t->is_border && !t->bypass_en)
        result.pixel = 0;

    result.valid = 1;
    return result;
}

int main(void)
{
    /*
     * Each input is {{p00,p01,p02},{p10,p11,p12},{p20,p21,p22}}.
     * Corners are set to zero except in the uniform test: Option C ignores
     * corners; it uses the 4 orthogonal neighbors and the center pixel.
     * The expected columns match the 16 check_case calls in tb_edge_alu.v.
     */
    const test_case_t tests[N_TESTS] = {
        {"Uniform pixels",                  {{100,100,100},{100,100,100},{100,100,100}}, 0,   0,0,0,1, 0,   0,   1},
        {"Horizontal edge",                 {{  0,250,  0},{ 70,100, 70},{  0, 10,  0}}, 100, 0,0,0,1, 240, 255, 1},
        {"Vertical edge",                   {{  0, 70,  0},{200,100, 10},{  0, 70,  0}}, 100, 0,0,0,1, 190, 255, 1},
        {"Maximum gradient 510",            {{  0,255,  0},{255,100,  0},{  0,  0,  0}}, 255, 0,0,0,1, 510, 255, 1},
        {"Gradient equals threshold",       {{  0,100,  0},{ 80, 90, 40},{  0, 50,  0}}, 90,  0,0,0,1, 90,  0,   1},
        {"Gradient exceeds threshold by 1", {{  0,100,  0},{ 80, 90, 40},{  0, 50,  0}}, 89,  0,0,0,1, 90,  255, 1},
        {"Zero gradient zero threshold",    {{  0, 50,  0},{ 50, 50, 50},{  0, 50,  0}}, 0,   0,0,0,1, 0,   0,   1},
        {"Gradient 1 threshold 0",          {{  0, 51,  0},{ 50, 50, 50},{  0, 50,  0}}, 0,   0,0,0,1, 1,   255, 1},
        {"Invert detected edge",            {{  0,250,  0},{ 70,100, 70},{  0, 10,  0}}, 100, 1,0,0,1, 240, 0,   1},
        {"Invert no-edge output",           {{  0, 50,  0},{ 50, 50, 50},{  0, 50,  0}}, 100, 1,0,0,1, 0,   255, 1},
        {"Grayscale bypass",                {{  0,250,  0},{ 70,165, 70},{  0, 10,  0}}, 100, 0,1,0,1, 240, 165, 1},
        {"Inverted grayscale bypass",       {{  0,250,  0},{ 70,165, 70},{  0, 10,  0}}, 100, 1,1,0,1, 240, 90,  1},
        {"Border suppression",              {{  0,250,  0},{ 70,100, 70},{  0, 10,  0}}, 100, 0,0,1,1, 240, 0,   1},
        {"Border with inversion",           {{  0,250,  0},{ 70,100, 70},{  0, 10,  0}}, 100, 1,0,1,1, 240, 0,   1},
        {"Border with grayscale bypass",    {{  0,250,  0},{ 70,165, 70},{  0, 10,  0}}, 100, 0,1,1,1, 240, 165, 1},
        {"Invalid input cycle",             {{  0,250,  0},{ 70,100, 70},{  0, 10,  0}}, 100, 0,0,0,0, 0,   0,   0}
    };

    int failures = 0;
    printf("ECE 351 Option C - C reference results\n");
    printf("No  %-40s %9s %9s %5s  Result\n", "Test", "Gradient", "Pixel", "Valid");

    for (int i = 0; i < N_TESTS; ++i) {
        edge_result_t result = calculate_edge(&tests[i]);
        int passed = (result.gradient == tests[i].expected_g &&
                      result.pixel == tests[i].expected_pixel &&
                      result.valid == tests[i].expected_valid);
        if (!passed)
            ++failures;

        printf("%2d  %-40s %9d %9d %5d  %s\n",
               i + 1, tests[i].name, result.gradient, result.pixel,
               result.valid, passed ? "PASS" : "FAIL");
    }

    printf("\nData/control cases: %d\nFailures: %d\n", N_TESTS, failures);
    printf("Note: The two synchronous reset checks remain in tb_edge_alu.v.\n");
    return (failures == 0) ? 0 : 1;
}
