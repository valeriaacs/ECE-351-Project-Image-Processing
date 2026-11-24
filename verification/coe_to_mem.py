# ECE 351 - Week 8, Task 1
# Convert the existing COE image into a Verilog memory file.

from pathlib import Path

WIDTH = 320
HEIGHT = 240
EXPECTED_PIXELS = WIDTH * HEIGHT

source = Path("valeria_pipeline/image_data.coe")
destination = Path("verification/image_data.mem")

# Read the COE initialization file.
content = source.read_text()

# Extract hexadecimal pixel values.
radix, vector = content.split(
    "memory_initialization_vector=", 1
)

if "memory_initialization_radix=16;" not in radix.replace(" ", ""):
    raise ValueError("Expected hexadecimal COE format.")

pixels = vector.replace(";", "").split(",")
pixels = [int(pixel.strip(), 16)
          for pixel in pixels if pixel.strip()]

# Verify the number of pixels.
if len(pixels) != EXPECTED_PIXELS:
    raise ValueError(
        f"Expected {EXPECTED_PIXELS} pixels, "
        f"received {len(pixels)}"
    )

# Verify that every pixel fits in 8 bits.
if any(pixel < 0 or pixel > 255 for pixel in pixels):
    raise ValueError("Pixel outside 8-bit grayscale range.")

# Write one hexadecimal pixel per line.
with destination.open("w") as output:
    for pixel in pixels:
        output.write(f"{pixel:02X}\n")

print("PASS: COE conversion successful")
print(f"Image dimensions: {WIDTH} x {HEIGHT}")
print(f"Total pixels: {len(pixels)}")
print(f"Minimum pixel value: {min(pixels)}")
print(f"Maximum pixel value: {max(pixels)}")
print(f"Output file: {destination}")
