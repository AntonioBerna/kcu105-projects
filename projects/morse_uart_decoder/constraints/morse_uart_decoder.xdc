# KCU105 constraints for morse_uart_decoder

# 125 MHz differential system clock
set_property PACKAGE_PIN G10 [get_ports "CLK_125MHZ_P"]
set_property IOSTANDARD LVDS [get_ports "CLK_125MHZ_P"]
set_property PACKAGE_PIN F10 [get_ports "CLK_125MHZ_N"]
set_property IOSTANDARD LVDS [get_ports "CLK_125MHZ_N"]
create_clock -name clk_125mhz -period 8.000 [get_ports "CLK_125MHZ_P"]

# SW7 center push button used as Morse key input
set_property PACKAGE_PIN AE10 [get_ports "GPIO_SW_C"]
set_property IOSTANDARD LVCMOS18 [get_ports "GPIO_SW_C"]

# USB-UART RX net on board connector (driven by FPGA UART TX)
set_property PACKAGE_PIN K26 [get_ports "USB_UART_RX"]
set_property IOSTANDARD LVCMOS18 [get_ports "USB_UART_RX"]
