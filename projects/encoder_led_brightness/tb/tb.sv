`timescale 1ns / 1ps

module tb;
  logic clk_p;
  logic clk_n;

  logic gpio_sw_c;
  logic rotary_push;
  logic rotary_inca;
  logic rotary_incb;

  logic gpio_led_0_ls;
  logic gpio_led_1_ls;
  logic gpio_led_2_ls;
  logic gpio_led_3_ls;
  logic gpio_led_4_ls;
  logic gpio_led_5_ls;
  logic gpio_led_6_ls;
  logic gpio_led_7_ls;

  logic [7:0] leds;

  encoder_led_brightness #(
      .DEBOUNCE_CYCLES(2),
      .BRIGHTNESS_BITS(4)
  ) dut (
      .CLK_125MHZ_P (clk_p),
      .CLK_125MHZ_N (clk_n),
      .GPIO_SW_C    (gpio_sw_c),
      .ROTARY_PUSH  (rotary_push),
      .ROTARY_INCA  (rotary_inca),
      .ROTARY_INCB  (rotary_incb),
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

  task automatic set_rotary_state(input logic a, input logic b);
    begin
      rotary_inca = a;
      rotary_incb = b;
      repeat (6) @(posedge clk_p);
    end
  endtask

  task automatic set_rotary_state_fast(input logic a, input logic b);
    begin
      rotary_inca = a;
      rotary_incb = b;
      @(posedge clk_p);
    end
  endtask

  // Clockwise sequence: 00 -> 01 -> 11 -> 10 -> 00
  task automatic encoder_step_cw;
    begin
      set_rotary_state(1'b0, 1'b0);
      set_rotary_state(1'b0, 1'b1);
      set_rotary_state(1'b1, 1'b1);
      set_rotary_state(1'b1, 1'b0);
      set_rotary_state(1'b0, 1'b0);
    end
  endtask

  // Counter-clockwise sequence: 00 -> 10 -> 11 -> 01 -> 00
  task automatic encoder_step_ccw;
    begin
      set_rotary_state(1'b0, 1'b0);
      set_rotary_state(1'b1, 1'b0);
      set_rotary_state(1'b1, 1'b1);
      set_rotary_state(1'b0, 1'b1);
      set_rotary_state(1'b0, 1'b0);
    end
  endtask

  task automatic encoder_step_cw_fast;
    begin
      set_rotary_state_fast(1'b0, 1'b0);
      set_rotary_state_fast(1'b0, 1'b1);
      set_rotary_state_fast(1'b1, 1'b1);
      set_rotary_state_fast(1'b1, 1'b0);
      set_rotary_state_fast(1'b0, 1'b0);
    end
  endtask

  task automatic encoder_step_ccw_fast;
    begin
      set_rotary_state_fast(1'b0, 1'b0);
      set_rotary_state_fast(1'b1, 1'b0);
      set_rotary_state_fast(1'b1, 1'b1);
      set_rotary_state_fast(1'b0, 1'b1);
      set_rotary_state_fast(1'b0, 1'b0);
    end
  endtask

  task automatic click_sw7;
    begin
      gpio_sw_c = 1'b1;
      repeat (10) @(posedge clk_p);
      gpio_sw_c = 1'b0;
      repeat (10) @(posedge clk_p);
    end
  endtask

  task automatic click_rotary_push;
    begin
      rotary_push = 1'b1;
      repeat (10) @(posedge clk_p);
      rotary_push = 1'b0;
      repeat (10) @(posedge clk_p);
    end
  endtask

  task automatic measure_led0_high(output int high_count);
    begin
      high_count = 0;
      repeat (16) begin
        @(posedge clk_p);
        if (gpio_led_0_ls) begin
          high_count++;
        end
      end
    end
  endtask

  initial begin
    int i;
    int led0_high;

    clk_p = 1'b0;
    gpio_sw_c = 1'b0;
    rotary_push = 1'b0;
    rotary_inca = 1'b0;
    rotary_incb = 1'b0;

    $dumpfile("dump.vcd");
    $dumpvars(0, tb);
    $dumpon;

    repeat (20) @(posedge clk_p);

    if (leds !== 8'h00) begin
      $fatal(1, "Startup: expected LEDs=00000000, got=%b", leds);
    end

    // Stress test for fast rotation.
    repeat (12) encoder_step_cw_fast();
    if (leds !== 8'hFF) begin
      $fatal(1, "Fast CW: expected saturation to 11111111, got=%b", leds);
    end

    repeat (12) encoder_step_ccw_fast();
    if (leds !== 8'h00) begin
      $fatal(1, "Fast CCW: expected floor to 00000000, got=%b", leds);
    end

    repeat (3) encoder_step_cw();
    if (leds !== 8'h07) begin
      $fatal(1, "Volume mode: expected level 3 (00000111), got=%b", leds);
    end

    repeat (2) encoder_step_ccw();
    if (leds !== 8'h01) begin
      $fatal(1, "Volume mode: expected level 1 (00000001), got=%b", leds);
    end

    click_sw7();

    repeat (8) encoder_step_ccw();
    if (|leds[7:1]) begin
      $fatal(1, "Brightness mode: LEDs[7:1] should remain off at level 1, got=%b", leds);
    end

    measure_led0_high(led0_high);
    if ((led0_high <= 0) || (led0_high >= 16)) begin
      $fatal(1, "Brightness mode: LED0 duty should be between 0 and full, got %0d/16", led0_high);
    end

    repeat (16) encoder_step_cw();
    measure_led0_high(led0_high);
    if (led0_high != 16) begin
      $fatal(1, "Brightness mode: expected full brightness (16/16), got %0d/16", led0_high);
    end

    click_rotary_push();

    repeat (7) encoder_step_cw();
    if (leds !== 8'hFF) begin
      $fatal(1, "Volume mode: expected level 8 (11111111), got=%b", leds);
    end

    encoder_step_ccw();
    if (leds !== 8'h7F) begin
      $fatal(1, "Volume mode: expected level 7 (01111111), got=%b", leds);
    end

    $display("PASS: encoder controls volume level and SW7 toggles global brightness mode");
    $dumpflush;
    #20;
    $finish;
  end

endmodule
