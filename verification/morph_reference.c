
#include <stdio.h>

#define SIZE 3
#define NUM_TESTS 5

/*
 * Morphological reference model
 *
 * Kernel mode:
 *   0 = Square kernel (all 9 pixels)
 *   1 = Cross kernel (center + 4 neighbors)
 *
 * Dilation = maximum selected pixel
 * Erosion  = minimum selected pixel
 * Edge     = dilation - erosion
 */

/* Function declaration */
void morph_calculate(
    const int pixels[SIZE][SIZE],
    int kernel_mode,
    int *dilation,
    int *erosion,
    int *edge
);

/* Function definition */
void morph_calculate(
    const int pixels[SIZE][SIZE],
    int kernel_mode,
    int *dilation,
    int *erosion,
    int *edge
)
{
    /* Initial minimum and maximum values */
    int max = 0;
    int min = 255;

    /* Examine every position in the 3x3 matrix */
    for (int row = 0; row < SIZE; row++)
    {
        for (int col = 0; col < SIZE; col++)
        {
            /*
             * Square kernel selects all 9 pixels.
             * Cross kernel selects middle row and column.
             */
            int selected = (kernel_mode == 0) ||
                           (row == 1) ||
                           (col == 1);

            /* Only process selected pixels */
            if (selected)
            {
                int pixel = pixels[row][col];

                /* Dilation: find maximum pixel */
                if (pixel > max)
                    max = pixel;

                /* Erosion: find minimum pixel */
                if (pixel < min)
                    min = pixel;
            }
        }
    }

    /* Store results using output pointers */
    *dilation = max;
    *erosion = min;
    *edge = max - min;
}

/* Main program */
int main(void)
{
    /* Five predefined 3x3 grayscale test matrices */
    const int tests[NUM_TESTS][SIZE][SIZE] = {

        /* Test 1: Increasing values */
        {
            {10, 20, 30},
            {40, 50, 60},
            {70, 80, 90}
        },

        /* Test 2: Uniform values */
        {
            {100, 100, 100},
            {100, 100, 100},
            {100, 100, 100}
        },

        /* Test 3: Corner extremes */
        {
            {255, 50, 0},
            {50, 50, 50},
            {0, 50, 255}
        },

        /* Test 4: Center maximum */
        {
            {0, 0, 0},
            {0, 255, 0},
            {0, 0, 0}
        },

        /* Test 5: All maximum values */
        {
            {255, 255, 255},
            {255, 255, 255},
            {255, 255, 255}
        }
    };

    /* Names of each test case */
    const char *names[NUM_TESTS] = {
        "Increasing values",
        "Uniform values",
        "Corner extremes",
        "Center maximum",
        "All maximum values"
    };

    /* Run all five test cases */
    for (int test = 0; test < NUM_TESTS; test++)
    {
        printf("\nTest %d: %s\n",
               test + 1, names[test]);

        /* Test both kernel modes */
        for (int kernel_mode = 0;
             kernel_mode <= 1;
             kernel_mode++)
        {
            int dilation;
            int erosion;
            int edge;

            /* Calculate morphological results */
            morph_calculate(
                tests[test],
                kernel_mode,
                &dilation,
                &erosion,
                &edge
            );

            /* Display results */
            printf(
                "%s: Dilation=%d Erosion=%d Edge=%d\n",
                kernel_mode == 0 ? "Square" : "Cross",
                dilation,
                erosion,
                edge
            );
        }
    }

    return 0;
}
