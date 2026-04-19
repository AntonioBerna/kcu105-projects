# Binary LED Counter

This project implements an 8-bit binary counter on the AMD KCU105 board using SystemVerilog.

Each valid debounced click on GPIO_SW_C increments the 8-bit counter by one. The eight GPIO LEDs show the counter value in binary. After reaching 8'hFF (all LEDs on), the next click wraps to 8'h00 (all LEDs off).

The constraints reuse the same clock, button, and LED pin mapping as `led_bar`.

Tool options for Verilator and Verible are read from the shared configuration directory at `../../config`.

## Usage

Run these commands from the project directory:

```bash
# Build the simulation
make

# Run the simulation and generate dump.vcd
make run

# View the waveform dump
surfer dump.vcd

# Format, syntax-check, and lint
make format

# Clean generated files
make clean
```
