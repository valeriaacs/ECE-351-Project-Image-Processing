`timescale 1ns / 1ps

module vga_controller_tb;

reg pixel_clk = 0;
reg reset = 1;

wire hsync;
wire vsync;
wire [9:0] pixel_x;
wire [9:0] pixel_y;
wire video_on;

integer x, y;
integer errors = 0;

// 25 MHz clock = 40 ns period
always #20 pixel_clk = ~pixel_clk;

// Instantiate VGA controller
vga_controller uut (
.pixel_clk(pixel_clk),
.reset(reset),
.hsync(hsync),
.vsync(vsync),
.pixel_x(pixel_x),
.pixel_y(pixel_y),
.video_on(video_on)
);

initial begin
// Apply reset for 5 clock cycles
repeat (5) @(negedge pixel_clk);
reset = 0;

// Check all pixels in one VGA frame
for (y = 0; y < 525; y = y + 1) begin
for (x = 0; x < 800; x = x + 1) begin

// Verify pixel coordinates
if (pixel_x !== x ||
pixel_y !== y) begin

if (errors < 10)
$display(
"Coordinate error at (%0d,%0d)",
x, y
);

errors = errors + 1;
end

// Verify horizontal sync
if (hsync !==
!((x >= 656) && (x < 752))) begin

if (errors < 10)
$display(
"HSYNC error at (%0d,%0d)",
x, y
);

errors = errors + 1;
end

// Verify vertical sync
if (vsync !==
!((y >= 490) && (y < 492))) begin

if (errors < 10)
$display(
"VSYNC error at (%0d,%0d)",
x, y
);

errors = errors + 1;
end

// Verify active video region
if (video_on !==
((x < 640) && (y < 480))) begin

if (errors < 10)
$display(
"Video error at (%0d,%0d)",
x, y
);

errors = errors + 1;
end

// Advance one pixel clock
@(negedge pixel_clk);
end
end

// Verify frame counter wraparound
if (pixel_x !== 0 || pixel_y !== 0) begin
$display("Frame wraparound error");
errors = errors + 1;
end

// Display simulation results
if (errors == 0)
$display("PASS: VGA timing verified!");
else
$display("FAIL: %0d errors", errors);

$finish;
end

endmodule
