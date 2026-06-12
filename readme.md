# HDMI Framebuffer on Zynq

A custom HDMI framebuffer implementation on a Zynq FPGA using a BRAM-backed RGB888 framebuffer and a custom HDMI timing generator. Images are loaded from the processing system into BRAM and displayed through an HDMI output pipeline. This projects consisted of two variants of a similar design (block RAM based HDMI display for ZYNQ) -- the more sophisticated variant (design 1) uses a BRAM generator IP block and axi BRAM to allow the user to load any image (up to 300 x 300 px due to BRAM constraints on the PL) using the CPU and Vitis, while the simpler design (design 2) uses a user-created block ram module designed specifically for this project but lacks the ability to write to the block ram and must be hardcoded into the HDL files.

## Features

- Custom HDMI timing generator
- Supports:
  - 800x600
  - 1280x720
  - 1920x1080 timing
- BRAM framebuffer
- RGB888 color
- PS-to-PL image transfer (design 1)
- HDMI output via rgb2dvi IP

## Design goals

- learning HDMI and video timing basics
- a simple pipeline implementation
- PL/PS integration
- AXI BRAM usage
- develop a codebase for a general purpose HDMI display pipeline

## Design Variants

### Design 1 - AXI BRAM Framebuffer

- PS writes image data into BRAM
- Runtime image loading
- Supports arbitrary 300x300 images
- Uses AXI BRAM Controller

### Design 2 - Custom BRAM Framebuffer

- Pure RTL implementation
- Framebuffer contents hardcoded in HDL
- No PS interaction
- Used for pipeline validation and timing development

## General Pipeline

PS (Vitis)
    ↓
AXI BRAM Controller
    ↓
Block RAM
    ↓
Framebuffer Reader
    ↓
Pipeline Delay
    ↓
RGB2DVI
    ↓
HDMI Monitor

## Architecture

the final architecture of the design utilizes the following architecture:

### Pixel clock

the clock wizard generates a clock signal at 40 Mhz / 74 Mhz / 148 Mhz (depends on the resolution selected). This is the pixel clock used for all the HDMI pipeline stages.

### HDMI Timings

- the HDMI timing generator produces the necessary timing signals to feed into the "rgb2dvi" encoder IP block based on the clock. This includes the horizontal and vertical sync signals and a display enable signal which indicates if the current clock period corresponds to the portion of the screen that is visible externally. x and y outputs are also generated when the display enable is high to indicate the row and column of the screen (or 0 when in the porches/sync periods).
- Using the x/y coordinates and display enable, the address in memory to read is generated combinationally and sent to port B (the read port) of the block memory generator. If the display enable is not asserted or the x/y coordinates are out of bounds (>= 300 for x/y), then the address sent out will just be set to 0 and the block ram enable will be disabled (0)

### BRAM Address read

- as soon as the address for the block memory is generated, it can be used to index the block ram to obtain the pixel that must be displayed. However, since the block ram is a sychronous element, the address must be latched in on the subsequent clock edge. This is the first stage of the video pipeline. The block memory generator has a configurable read latency ([see here](/pictures/IP_BRAM_LATENCY.png)), and setting the latency to 1 (used in this design) actually means the output of the block ram is valid before the next clock edge arrives with the new address. This is in contrast to the hand-written block ram used in design 2, which uses one clock cycle to latch in the address and another to output the correct data (a 2 cycle delay). After this 1 (or 2) cycle delay, the block ram produces a single pixel of colour (RGB888) as an output. In the case of design 1, this is padded to 32 bits for alignment, but only the lower 24 are used. Design 2 uses an initial block to configure the block RAM memory before the design runs, as can be seen below.

![IP BRAM ADDRESS DECODE](/pictures/IP_BRAM_SELECT_LOGIC.png)

![design 2 BRAM logic](/pictures/custom_BRAM_logic.png)

![design 2 BRAM init](/pictures/custom_BRAM_init.png)

### Pipeline delay for HDMI signals

- since the BRAM has at least one cycle of delay (or 2 for design$ #2), it is necessary for the vsync/hsync/display enable signals to be delayed when they enter the rgb2dvi IP block. If they were not delayed, then the dvi encoder would receive the pixel colours late relative to the timing signals. Delaying these signals only impacts the latency of the design, but the troughput remains 1 pixel/clock cycle after the first pixel enters the rgb2dvi encoder

### multiplexer for selecting the pixel to display

- In the case of design 1, the image being rendered is only 300x300 px, so for most of the time the visible portion of the screen needs to be black (empty). However, since the output of the block ram is not known when the display is not enabled (recall that the enable for the block ram is only asserted when x and y are below 300 and the display enable is high), it is necessary to choose between the output of the block ram and a black pixel. This can be acheived easily with a 24 bit 2-to-1 mux which uses the block ram enable as a selection line and passes the block ram output if it was enabled or a black pixel if it was disabled. Since the AXI BRAM has a one cycle latency relative to the timing generator signals, the bram enable signal that is used for multiplexing is delayed by one clock cycle. If this signal were not delayed for the multiplexer, the design would use the bram enable from one clock cycle (pixel) ago, and the right border of the image will be truncated due to the misalignment.

![IP BRAM MUX SELECTION](/pictures/IP_BRAM_MUX_SELECTION.png)

### RGB888 to RBG888

- The rgb2dvi IP block specifically requires RBG888 data, so combinational vector slicing is used to create the correct ordering before the final stage.

### rgb2dvi encoding

- the Digilent RGB-to-DVI encoding IP takes the delayed Hsync/Vsync/Display enable and the multiplexed pixel output along with the pixel clock to encode the image data according to TMDS standards. This involves serializing the data such that transitions are minimized outputting a differential pair for the HDMI clock/data channels (hence the name). It is uses as an IP block since TMDS encoding is beyond the scope of the project. The output pins of this block are connected to the HDMI port using the PL nets and constraints file.

## Design implementation

- [HDMI_timing_generator.v](/src/HDMI_timing_generator.v)
  Generates industry-standard video timings (800x600, 1280x720, and 1920x1080) including active video regions, porches, and synchronization pulses. Uses a simple counter to determine which portion of the screen the scanner should be at. Also produces x/y coordinates (starting at the top left) used for BRAM addressing

- [BRAM_framebuffer.v](/src/BRAM_framebuffer.v)
  The custom BRAM framebuffer used in design 2 only. This framebuffer actually covers the whole screen for the 800x600 px resolution instead of only using the 300x300 window like the AXI BRAM does.

- [mux2.v](/src/mux2.v)
  a 24 bit 2 to 1 mux that passes the first input when the select is 0 and the second input if the select is 1.
- [pipeline_delay.v](/src/pipeline_delay.v)
  a modular block that can delay any group of signals (a variably sized vector) for a small known number of cycles. Necessary for pipeline synchronization.

- [rgb_to_rbg.v](/src/rgb_to_rbg.v)
  converts rgb888 to rbg888 using a simple slice operation.

- [image_to_raw_file.py](/src/image_to_raw_file.py)
  a python script that uses numpy and cv2 to write any image to an uncompressed 300x300 RGB888 array on a mounted SD card. This allows the ZYNQ to read this file at runtime to fill in the AXI BRAM with the raw pixels. Has some options for hardcoded test images

- [main.c](/src/main.c)
  Vitis C code for design 1 that reads the binary data created with the python script from the SD card to populate the AXI BRAM

- [ZSD_card.h](/src/ZSD_card.h)
  C code library header for interacting with the SD card at runtime to load/save files

- [ZSD_card.c](/src/ZSD_card.c)
C code implementation for a simple SD card library (based on fatffs)

The final block diagrams are:

Design 1 (AXI BRAM IP):
![design 1 layout](/IP_block_ram.pdf)

Design 2 (Custom BRAM implementation):
![design 1 layout](/design_custom_block_ram.pdf)

## Lessons learned and development issues

### Pipeline misalignment

Throughout development, using undelayed signals for the HDMI timings caused image skew, which was especially noticible for the white 1 pixel border. One subtle bug with design 1 was caused by an earlier version with andelayed bram enable used for multiplexing the pixel input of the rgb2dvi encoder -- The current mux selection line would be early relative to the output of the BRAM, so the far right side of the loaded image would be truncated by one pixel/vertical column. This was not visible for "normal" pictures since they normally look the same with one column removed, but was clearly visible with the 1 pixel border pattern used to test design 2.

### AXI BRAM Uses Byte Addressing

A significant debugging issue was caused by
assuming BRAM addresses were word-based.

The AXI BRAM controller expects byte addresses,
so framebuffer addresses had to be multiplied by 4.

Incorrect addressing resulted in multiple adjacent
pixels displaying the same value because the lower
address bits were effectively ignored by the axi BRAM memory module.

The correct formula is:  address = (y * width + x)  << 2. Notably, this was not necessary for the custom BRAM implementation, which could be indexed using a word address

## Results

The following use a resolution of 800x600 px at 60 Hz, but 720p and 1080p also work. Frame rates above 60 Hz are theoretically possible with an increased clock frequency, but will introduce serious timing constraints and may not be possible to generate with the clocking wizard.

### Design 1 Dynamic Image Rendering

300x300 RGB888 image loaded from SD card
into BRAM through the AXI BRAM Controller.

![design_1_test](/pictures/design_1_test.jpg)

### Design 2 hard coded white border with custom BRAM

800x600 1 pixel wide white border hard coded into the inital block

![design_2_test_1](/pictures/design_2_test_1.jpg)

### Design 2 hard coded colour stripes with custom BRAM

800x600 RGB colour stripes to indicate colour channel correctness

![design_2_test_2](/pictures/design_2_test_2.jpg)

### Design Utilizations

The AXI BRAM implementation uses the following resources:
![AXI BRAM resources used](/pictures/IP_BRAM_UTILIZATION.png)

The custom BRAM implementation uses the following resources:
![custom BRAM resources used](/pictures/CUSTOM_BRAM_UTILIZATION.png)

These results suggest that the AXI BRAM generator uses the on-chip BRAM resources (as expected). Using a 300 x 300 x 32 bit memory uses 2.88 Mbits. This should be about half the BRAM, but it's reported as 91%, so this specific ZYNQ may have less BRAM or BRAM is used elsewhere. The custom BRAM implementation doesn't report any BRAM usage or high LUT usage, so it's unclear how the verilog memory is inferred by the tools. Regardless, both designs display pixels correctly and report the correct frame rate and resolution on the monitor.

## Future work and next steps

- add any optional image filters to the HDMI pipeline to take advantage of the PL fabric
- add AXI DMA IP for DMA access to a full screen framebuffer instead of block ram (BRAM resources are very limited, only about 600 KB are available on ZYNQ 7020)
- create a graphics API for general use for HDMI (text/images/graphics primitaves) like with the [ZLCD library](https://github.com/msergo4314/ZLCD_graphics)

## Building the Project

### Vivado

1. Open Vivado 2025.x
2. Create a project targeting XC7Z020 (clg484 - 1)
3. Add RTL sources from /src
4. Add constraints file as constraint source
5. Generate bitstream

### Vitis

1. Export hardware platform
2. Create standalone application using C files in /src
3. Build and program FPGA
4. Copy image file to SD card using python script (you will need to have something to read/write to the SD card from your PC)
