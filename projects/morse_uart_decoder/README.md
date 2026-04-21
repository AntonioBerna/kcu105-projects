<h1 align="center">
    <br>
    <img src=".github/imgs/morse-code.jpg" alt="Morse Code" width="600">
    <br>
    Morse UART Decoder (SW7)
    <br>
</h1>

This project uses SW7 (GPIO_SW_C) on the AMD KCU105 as a Morse key input.

The FPGA measures press and pause durations, decodes Morse symbols into plaintext letters, and streams the decoded text in real time through USB UART TX at 115200 baud (8N1).

Clock, switch, and UART pin assignments are provided in `constraints/morse_uart_decoder.xdc`.

Tool options for Verilator and Verible are read from the shared configuration directory at `../../config`.

## Morse Timing Model

The decoder uses a configurable Morse timing unit (`TIME_UNIT_CYCLES`):

- Dot: short press (`< DOT_DASH_THRESHOLD_CYCLES`)
- Dash: long press (`>= DOT_DASH_THRESHOLD_CYCLES`)
- Letter separator: idle gap of `LETTER_GAP_CYCLES`
- Word separator: idle gap of `WORD_GAP_CYCLES` (sends a space character)

Default values target manual keying with SW7 at 125 MHz clock.

## Morse Alphabet Table (A-Z)

| Character | Morse |
|---|---|
| A | .- |
| B | -... |
| C | -.-. |
| D | -.. |
| E | . |
| F | ..-. |
| G | --. |
| H | .... |
| I | .. |
| J | .--- |
| K | -.- |
| L | .-.. |
| M | -- |
| N | -. |
| O | --- |
| P | .--. |
| Q | --.- |
| R | .-. |
| S | ... |
| T | - |
| U | ..- |
| V | ...- |
| W | .-- |
| X | -..- |
| Y | -.-- |
| Z | --.. |

## Usage

Run these commands from the project directory:

```bash
# Build the simulation
make

# Run simulation and generate dump.vcd
make run

# View waveform
surfer dump.vcd

# Format, syntax-check, and lint
make format

# Clean generated files
make clean
```

## Hardware Bring-Up

1. Create/open Vivado project:

```bash
vivado -mode batch -source scripts/create_vivado_2019_project.tcl
```

2. Synthesize, implement, generate bitstream, and program the board.
3. Open a serial terminal at 115200 baud and read the incoming plaintext stream.

Linux example with `screen` (recommended stable path):

```bash
screen /dev/serial/by-id/usb-Silicon_Labs_CP2105_Dual_USB_to_UART_Bridge_Controller_00F13524-if01-port0 115200
```

Alternative dynamic device name:

```bash
screen /dev/ttyUSB1 115200
```

## Troubleshooting UART

- If you see this menu:

    ```
    KCU105 System Controller v1.0
    ```

    you are connected to the System Controller UART (`if00` / usually `/dev/ttyUSB0`), not the FPGA UART.

- Use the FPGA UART channel (`if01` / usually `/dev/ttyUSB1`).

- If still no characters appear:
    - Confirm the FPGA is programmed with this project bitstream.
    - Disable software and hardware flow control on the host serial port.
    - Try a clear timing test on SW7:
        - short press then release, wait about 0.5 s -> should decode `E`
        - long press then release, wait about 0.5 s -> should decode `T`

Example (`stty` + `cat`):

```bash
stty -F /dev/ttyUSB1 115200 cs8 -cstopb -parenb -ixon -ixoff -crtscts -echo
cat /dev/ttyUSB1
```

When you key Morse on SW7, decoded characters are transmitted continuously over UART.
