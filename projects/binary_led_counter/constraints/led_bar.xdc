# Constraints reused from led_bar for KCU105 pins

# 125 MHz differential system clock
set_property PACKAGE_PIN G10 [get_ports "CLK_125MHZ_P"]
set_property IOSTANDARD LVDS [get_ports "CLK_125MHZ_P"]
set_property PACKAGE_PIN F10 [get_ports "CLK_125MHZ_N"]
set_property IOSTANDARD LVDS [get_ports "CLK_125MHZ_N"]
create_clock -name clk_125mhz -period 8.000 [get_ports "CLK_125MHZ_P"]

# Center push button
set_property PACKAGE_PIN AE10 [get_ports "GPIO_SW_C"]
set_property IOSTANDARD LVCMOS18 [get_ports "GPIO_SW_C"]

# User LEDs
set_property PACKAGE_PIN AP8 [get_ports "GPIO_LED_0_LS"]
set_property IOSTANDARD LVCMOS18 [get_ports "GPIO_LED_0_LS"]
set_property PACKAGE_PIN H23 [get_ports "GPIO_LED_1_LS"]
set_property IOSTANDARD LVCMOS18 [get_ports "GPIO_LED_1_LS"]
set_property PACKAGE_PIN P20 [get_ports "GPIO_LED_2_LS"]
set_property IOSTANDARD LVCMOS18 [get_ports "GPIO_LED_2_LS"]
set_property PACKAGE_PIN P21 [get_ports "GPIO_LED_3_LS"]
set_property IOSTANDARD LVCMOS18 [get_ports "GPIO_LED_3_LS"]
set_property PACKAGE_PIN N22 [get_ports "GPIO_LED_4_LS"]
set_property IOSTANDARD LVCMOS18 [get_ports "GPIO_LED_4_LS"]
set_property PACKAGE_PIN M22 [get_ports "GPIO_LED_5_LS"]
set_property IOSTANDARD LVCMOS18 [get_ports "GPIO_LED_5_LS"]
set_property PACKAGE_PIN R23 [get_ports "GPIO_LED_6_LS"]
set_property IOSTANDARD LVCMOS18 [get_ports "GPIO_LED_6_LS"]
set_property PACKAGE_PIN P23 [get_ports "GPIO_LED_7_LS"]
set_property IOSTANDARD LVCMOS18 [get_ports "GPIO_LED_7_LS"]
