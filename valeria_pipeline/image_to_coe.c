#include <stdio.h>
#include <stdlib.h>
#include <math.h>

// Include only stb_image for reading JPEG/PNG files
#define STB_IMAGE_IMPLEMENTATION
#include "stb_image.h"

int main(int argc, char *argv[]) {
    const char *input_path = "sample.png";
    const char *output_path = "image_data.coe";

    const int target_width = 320;
    const int target_height = 240;

    int orig_width, orig_height, channels;

    // Load original image and force conversion to 1-channel 8-bit grayscale
    unsigned char *img_orig = stbi_load(input_path, &orig_width, &orig_height, &channels, 1);

    if (img_orig == NULL) {
        printf("Error: Could not load input image '%s'\n", input_path);
        return 1;
    }

    printf("Loaded '%s' (%dx%d, forced 1-channel grayscale)\n", input_path, orig_width, orig_height);

    size_t target_pixel_count = (size_t)target_width * target_height;
    unsigned char *img_resized = (unsigned char *)malloc(target_pixel_count);

    if (img_resized == NULL) {
        printf("Error: Dynamic memory allocation failed.\n");
        stbi_image_free(img_orig);
        return 1;
    }

    // Direct bilinear downscaling implementation (eliminates stb_image_resize header conflicts)
    float x_ratio = (float)(orig_width - 1) / target_width;
    float y_ratio = (float)(orig_height - 1) / target_height;

    for (int y = 0; y < target_height; y++) {
        for (int x = 0; x < target_width; x++) {
            int gx = (int)(x_ratio * x);
            int gy = (int)(y_ratio * y);
            float x_diff = (x_ratio * x) - gx;
            float y_diff = (y_ratio * y) - gy;

            int a_idx = gy * orig_width + gx;
            int b_idx = a_idx + 1;
            int c_idx = (gy + 1) * orig_width + gx;
            int d_idx = c_idx + 1;

            unsigned char a = img_orig[a_idx];
            unsigned char b = (gx + 1 < orig_width) ? img_orig[b_idx] : a;
            unsigned char c = (gy + 1 < orig_height) ? img_orig[c_idx] : a;
            unsigned char d = (gx + 1 < orig_width && gy + 1 < orig_height) ? img_orig[d_idx] : a;

            float pixel_val = a * (1 - x_diff) * (1 - y_diff) +
                              b * (x_diff) * (1 - y_diff) +
                              c * (y_diff) * (1 - x_diff) +
                              d * (x_diff * y_diff);

            img_resized[y * target_width + x] = (unsigned char)pixel_val;
        }
    }

    // Open output COE file
    FILE *coe_file = fopen(output_path, "w");
    if (coe_file == NULL) {
        printf("Error: Could not open output file '%s'\n", output_path);
        free(img_resized);
        stbi_image_free(img_orig);
        return 1;
    }

    // Write Xilinx BRAM COE format
    fprintf(coe_file, "memory_initialization_radix=16;\n");
    fprintf(coe_file, "memory_initialization_vector=\n");

    for (size_t i = 0; i < target_pixel_count; i++) {
        if (i == target_pixel_count - 1) {
            fprintf(coe_file, "%02X;\n", img_resized[i]);
        } else {
            fprintf(coe_file, "%02X,\n", img_resized[i]);
        }
    }

    fclose(coe_file);
    stbi_image_free(img_orig);
    free(img_resized);

    printf("Successfully generated '%s' (%dx%d, %zu bytes).\n", 
           output_path, target_width, target_height, target_pixel_count);

    return 0;
}