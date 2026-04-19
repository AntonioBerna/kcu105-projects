# Encoder LED Brightness

This project uses the KCU105 rotary encoder in two modes:

1. Volume mode: rotating the encoder lights the 8 GPIO LEDs in sequence as a bar graph.
2. Brightness mode: pressing SW7 (mapped to GPIO_SW_C) toggles to global brightness control for all active LEDs. Rotating the encoder changes brightness with PWM. Pressing SW7 again returns to volume mode.

Clock, rotary encoder, and LED pin assignments are provided in constraints/encoder_led_brightness.xdc.

Tool options for Verilator and Verible are read from the shared configuration directory at ../../config.

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
