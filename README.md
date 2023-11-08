# hdmi_tx
Software and HDL that enable streaming of HDMI from DE-10 Nano

## Functions
* Run a custom embedded Linux disribution on the HPS for high level software control
* Use Python to pixelate images into desired format and write to HPS/FPGA shared SDRAM
* Use H2F bridge for signalling to/from FPGA about image status in SDRAM
* Use F2H SDRAM bridge to pull RGB frame data into FIFO, cross clock boundary, distribute to HDMI driver
* Custom HDL driver for configuration and control for ADV7513 HDMI transmitter
* TO DO: Rescale/resample images for various frame and resolution formats

### HDMI Driver Development Procedure
1. Develop HDL for I2C master - responsible for ack/nack, writing bits to the wire, timing
2. Develop HDL for I2C controller - State machine for completing various combinations of RW bus transactions and register verification with read after write
3. Develop HDL for Register LUT that is used to hold the configuration data for the ADV7513
4. Develope HDL for ADV7513 driver that incorporates all of the previous modules. Responsible for configuring the ADV7513 after power up, and monitoring the status and debug registers after successful configuration

### Software Development Procedure
1. See other repo, ```de10_nano``` that is used to house the custom Linux distribution built for test and experiment
2. Enable F2H SDRAM bridge via modification to child device tree
3. Add bootparam in ext_linux.conf (SD card image generation script) to limit kernel to 512 Mb of RAM
4. Develop C userspace application to test RW via the H2F bridge, write simple HDL module to trigger when a bridge Avalon write command is asseted by the userspace application, confirm via Signal Tap
5. Write C application to copy test image binary to SDRAM (still not broken down in to RGB data format, just used to verify we can write data here and read via FPGA SDRAM interface)


### Notes
* ```mkimage``` is required to compile the custom bootscript from .txt into a .scr file usable by the SSBL
