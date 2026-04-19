`timescale 1ns / 1ps

module encoder_led_brightness #(
    parameter int unsigned DEBOUNCE_CYCLES = 1_250_000,
    parameter int unsigned BRIGHTNESS_BITS = 8
) (
    input  logic CLK_125MHZ_P,
    input  logic CLK_125MHZ_N,
    input  logic GPIO_SW_C,
    input  logic ROTARY_INCA,
    input  logic ROTARY_INCB,
    output logic GPIO_LED_0_LS,
    output logic GPIO_LED_1_LS,
    output logic GPIO_LED_2_LS,
    output logic GPIO_LED_3_LS,
    output logic GPIO_LED_4_LS,
    output logic GPIO_LED_5_LS,
    output logic GPIO_LED_6_LS,
    output logic GPIO_LED_7_LS
);

  logic clk_125mhz;

`ifdef SYNTHESIS
  IBUFDS #(
      .DIFF_TERM("TRUE"),
      .IBUF_LOW_PWR("FALSE")
  ) i_clk_125mhz (
      .I (CLK_125MHZ_P),
      .IB(CLK_125MHZ_N),
      .O (clk_125mhz)
  );
`else
  assign clk_125mhz = CLK_125MHZ_P;
`endif

  localparam int unsigned DbncCntW = (DEBOUNCE_CYCLES > 1) ? $clog2(DEBOUNCE_CYCLES) : 1;
  localparam logic [DbncCntW-1:0] DbncLast = DbncCntW'(DEBOUNCE_CYCLES - 1);
  localparam logic [BRIGHTNESS_BITS-1:0] BrightnessMax = {BRIGHTNESS_BITS{1'b1}};

  logic rota_meta = 1'b0;
  logic rota_sync = 1'b0;
  logic rotb_meta = 1'b0;
  logic rotb_sync = 1'b0;
  logic sw_meta = 1'b0;
  logic sw_sync = 1'b0;

  logic rota_stable = 1'b0;
  logic rotb_stable = 1'b0;
  logic sw_stable = 1'b0;

  logic rota_stable_d = 1'b0;
  logic sw_stable_d = 1'b0;

  logic [DbncCntW-1:0] rota_dbnc_cnt = '0;
  logic [DbncCntW-1:0] rotb_dbnc_cnt = '0;
  logic [DbncCntW-1:0] sw_dbnc_cnt = '0;

  logic mode_brightness = 1'b0;
  logic [3:0] volume_level = '0;
  logic [BRIGHTNESS_BITS-1:0] brightness = BrightnessMax;
  logic [BRIGHTNESS_BITS-1:0] pwm_cnt = '0;

  logic [7:0] volume_mask;
  logic pwm_en;
  logic [7:0] led_mask;

  always_ff @(posedge clk_125mhz) begin
    rota_meta <= ROTARY_INCA;
    rota_sync <= rota_meta;

    rotb_meta <= ROTARY_INCB;
    rotb_sync <= rotb_meta;

    sw_meta   <= GPIO_SW_C;
    sw_sync   <= sw_meta;
  end

  always_ff @(posedge clk_125mhz) begin
    if (rota_sync == rota_stable) begin
      rota_dbnc_cnt <= '0;
    end else if (rota_dbnc_cnt == DbncLast) begin
      rota_stable   <= rota_sync;
      rota_dbnc_cnt <= '0;
    end else begin
      rota_dbnc_cnt <= rota_dbnc_cnt + 1'b1;
    end

    if (rotb_sync == rotb_stable) begin
      rotb_dbnc_cnt <= '0;
    end else if (rotb_dbnc_cnt == DbncLast) begin
      rotb_stable   <= rotb_sync;
      rotb_dbnc_cnt <= '0;
    end else begin
      rotb_dbnc_cnt <= rotb_dbnc_cnt + 1'b1;
    end

    if (sw_sync == sw_stable) begin
      sw_dbnc_cnt <= '0;
    end else if (sw_dbnc_cnt == DbncLast) begin
      sw_stable   <= sw_sync;
      sw_dbnc_cnt <= '0;
    end else begin
      sw_dbnc_cnt <= sw_dbnc_cnt + 1'b1;
    end
  end

  always_ff @(posedge clk_125mhz) begin
    rota_stable_d <= rota_stable;
    sw_stable_d <= sw_stable;
    pwm_cnt <= pwm_cnt + 1'b1;

    if (!sw_stable_d && sw_stable) begin
      mode_brightness <= ~mode_brightness;
    end

    // One step per debounced rising edge of ROTARY_INCA.
    // ROTARY_INCB defines the direction at that edge.
    if (!rota_stable_d && rota_stable) begin
      if (!mode_brightness) begin
        if (rotb_stable) begin
          if (volume_level < 4'd8) begin
            volume_level <= volume_level + 1'b1;
          end
        end else begin
          if (volume_level > 4'd0) begin
            volume_level <= volume_level - 1'b1;
          end
        end
      end else begin
        if (rotb_stable) begin
          if (brightness < BrightnessMax) begin
            brightness <= brightness + 1'b1;
          end
        end else begin
          if (brightness > '0) begin
            brightness <= brightness - 1'b1;
          end
        end
      end
    end
  end

  always_comb begin
    if (volume_level == 4'd0) begin
      volume_mask = 8'h00;
    end else if (volume_level >= 4'd8) begin
      volume_mask = 8'hFF;
    end else begin
      volume_mask = (8'h01 << volume_level) - 8'h01;
    end
  end

  always_comb begin
    if (brightness == BrightnessMax) begin
      pwm_en = 1'b1;
    end else begin
      pwm_en = (pwm_cnt < brightness);
    end
  end

  always_comb begin
    if (pwm_en) begin
      led_mask = volume_mask;
    end else begin
      led_mask = 8'h00;
    end
  end

  assign GPIO_LED_0_LS = led_mask[0];
  assign GPIO_LED_1_LS = led_mask[1];
  assign GPIO_LED_2_LS = led_mask[2];
  assign GPIO_LED_3_LS = led_mask[3];
  assign GPIO_LED_4_LS = led_mask[4];
  assign GPIO_LED_5_LS = led_mask[5];
  assign GPIO_LED_6_LS = led_mask[6];
  assign GPIO_LED_7_LS = led_mask[7];

endmodule
