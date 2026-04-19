`timescale 1ns / 1ps

module tb;
  logic clk_p;
  logic clk_n;
  logic gpio_sw_c;

  logic gpio_led_0_ls;
  logic gpio_led_1_ls;
  logic gpio_led_2_ls;
  logic gpio_led_3_ls;
  logic gpio_led_4_ls;
  logic gpio_led_5_ls;
  logic gpio_led_6_ls;
  logic gpio_led_7_ls;

  logic [7:0] leds;

  binary_led_counter #(
      .DEBOUNCE_CYCLES(4)
  ) dut (
      .CLK_125MHZ_P(clk_p),
      .CLK_125MHZ_N(clk_n),
      .GPIO_SW_C(gpio_sw_c),
      .GPIO_LED_0_LS(gpio_led_0_ls),
      .GPIO_LED_1_LS(gpio_led_1_ls),
      .GPIO_LED_2_LS(gpio_led_2_ls),
      .GPIO_LED_3_LS(gpio_led_3_ls),
      .GPIO_LED_4_LS(gpio_led_4_ls),
      .GPIO_LED_5_LS(gpio_led_5_ls),
      .GPIO_LED_6_LS(gpio_led_6_ls),
      .GPIO_LED_7_LS(gpio_led_7_ls)
  );

  assign clk_n = ~clk_p;
  assign leds = {
    gpio_led_7_ls,
    gpio_led_6_ls,
    gpio_led_5_ls,
    gpio_led_4_ls,
    gpio_led_3_ls,
    gpio_led_2_ls,
    gpio_led_1_ls,
    gpio_led_0_ls
  };

  always #4 clk_p = ~clk_p;  // 125 MHz

  task automatic click_button;
    begin
      gpio_sw_c = 1'b1;
      repeat (10) @(posedge clk_p);
      gpio_sw_c = 1'b0;
      repeat (10) @(posedge clk_p);
    end
  endtask

  initial begin
    $dumpfile("dump.vcd");
    $dumpvars(0, tb);
    $dumpon;
  end

  initial begin
    int i;
    logic [7:0] expected;

    clk_p = 1'b0;
    gpio_sw_c = 1'b0;

    repeat (10) @(posedge clk_p);

    if (leds !== 8'h00) begin
      $fatal(1, "At startup expected LEDs=00000000, got=%b", leds);
    end

    for (i = 1; i <= 8'hFF; i++) begin
      click_button();
      expected = i[7:0];

      if (leds !== expected) begin
        $fatal(1, "Click %0d: expected LEDs=%b, got=%b", i, expected, leds);
      end
    end

    click_button();
    if (leds !== 8'h00) begin
      $fatal(1, "After FF, next click must wrap to 00, got=%b", leds);
    end

    click_button();
    if (leds !== 8'h01) begin
      $fatal(1, "After wrap, next click must be 01, got=%b", leds);
    end

    $display("PASS: binary counter verified from 00 to FF with wrap to 00");
    $dumpflush;
    #20;
    $finish;
  end

endmodule
