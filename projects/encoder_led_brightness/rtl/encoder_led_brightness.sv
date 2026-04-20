`timescale 1ns / 1ps

module encoder_led_brightness #(
    parameter int unsigned DEBOUNCE_CYCLES = 1_250_000,
    parameter int unsigned BRIGHTNESS_BITS = 8
) (
    input  logic CLK_125MHZ_P,
    input  logic CLK_125MHZ_N,
    input  logic GPIO_SW_C,
    input  logic ROTARY_PUSH,
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
  logic rpush_meta = 1'b0;
  logic rpush_sync = 1'b0;

  logic mode_btn_sync;
  logic mode_btn_stable = 1'b0;
  logic mode_btn_stable_d = 1'b0;
  logic [DbncCntW-1:0] mode_btn_dbnc_cnt = '0;

  logic [1:0] rot_ab_prev = 2'b00;
  logic [1:0] rot_ab_sync;
  logic signed [3:0] rot_delta;
  logic signed [3:0] rot_accum = '0;
  logic signed [3:0] rot_accum_next;
  logic rot_step_cw_pulse;
  logic rot_step_ccw_pulse;

  logic mode_brightness = 1'b0;
  logic [3:0] volume_level = '0;
  logic [BRIGHTNESS_BITS-1:0] brightness = BrightnessMax;
  logic [BRIGHTNESS_BITS-1:0] pwm_cnt = '0;

  // Use coarse brightness steps (16 levels by default) so changes are visible.
  localparam logic [BRIGHTNESS_BITS-1:0] BrightnessStep =
      (BRIGHTNESS_BITS > 4)
          ? ({{(BRIGHTNESS_BITS - 1) {1'b0}}, 1'b1} << (BRIGHTNESS_BITS - 4))
          : {{(BRIGHTNESS_BITS - 1) {1'b0}}, 1'b1};

  logic [7:0] volume_mask;
  logic pwm_en;
  logic [7:0] led_mask;

  assign mode_btn_sync = sw_sync | rpush_sync;
  assign rot_ab_sync   = {rota_sync, rotb_sync};

  always_ff @(posedge clk_125mhz) begin
    rota_meta <= ROTARY_INCA;
    rota_sync <= rota_meta;

    rotb_meta <= ROTARY_INCB;
    rotb_sync <= rotb_meta;

    sw_meta <= GPIO_SW_C;
    sw_sync <= sw_meta;

    rpush_meta <= ROTARY_PUSH;
    rpush_sync <= rpush_meta;
  end

  always_ff @(posedge clk_125mhz) begin
    if (mode_btn_sync == mode_btn_stable) begin
      mode_btn_dbnc_cnt <= '0;
    end else if (mode_btn_dbnc_cnt == DbncLast) begin
      mode_btn_stable   <= mode_btn_sync;
      mode_btn_dbnc_cnt <= '0;
    end else begin
      mode_btn_dbnc_cnt <= mode_btn_dbnc_cnt + 1'b1;
    end
  end

  always_comb begin
    rot_delta = 4'sd0;
    case ({
      rot_ab_prev, rot_ab_sync
    })
      4'b0001, 4'b0111, 4'b1110, 4'b1000: rot_delta = 4'sd1;
      4'b0010, 4'b1011, 4'b1101, 4'b0100: rot_delta = -4'sd1;
      default: rot_delta = 4'sd0;
    endcase
  end

  always_comb begin
    rot_accum_next = rot_accum + rot_delta;
    rot_step_cw_pulse = (rot_accum_next >= 4'sd4);
    rot_step_ccw_pulse = (rot_accum_next <= -4'sd4);
  end

  always_ff @(posedge clk_125mhz) begin
    mode_btn_stable_d <= mode_btn_stable;
    pwm_cnt <= pwm_cnt + 1'b1;

    if (rot_step_cw_pulse || rot_step_ccw_pulse) begin
      rot_accum <= 4'sd0;
    end else begin
      rot_accum <= rot_accum_next;
    end
    rot_ab_prev <= rot_ab_sync;

    if (!mode_btn_stable_d && mode_btn_stable) begin
      mode_brightness <= ~mode_brightness;
    end

    if (rot_step_cw_pulse) begin
      if (!mode_brightness) begin
        if (volume_level < 4'd8) begin
          volume_level <= volume_level + 1'b1;
        end
      end else begin
        if (brightness <= (BrightnessMax - BrightnessStep)) begin
          brightness <= brightness + BrightnessStep;
        end else begin
          brightness <= BrightnessMax;
        end
      end
    end else if (rot_step_ccw_pulse) begin
      if (!mode_brightness) begin
        if (volume_level > 4'd0) begin
          volume_level <= volume_level - 1'b1;
        end
      end else begin
        if (brightness >= BrightnessStep) begin
          brightness <= brightness - BrightnessStep;
        end else begin
          brightness <= '0;
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
