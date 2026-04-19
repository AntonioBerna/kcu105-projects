# Led Bar

This project implements a push-button controlled LED bar for the AMD KCU105 board using SystemVerilog.

Each valid debounced press of the center button turns on one additional user LED, progressing from LED0 to LED7. After all LEDs are on, the next press turns all LEDs off, and the following press restarts the sequence.

The repository includes the RTL design, board constraints, simulation testbench, and Vivado project/script files needed to build and verify the design.

Tool options for Verilator and Verible are read from the shared configuration directory at `../../config`.

## Usage

Run these commands from the project directory:

```bash
# Build the simulation
make

# Run the simulation
make run

# View the waveform dump
surfer dump.vcd

# Format, syntax-check, and lint
make format

# Clean up build and output files
make clean
```
