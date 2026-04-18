`timescale 1ns / 1ps

module led_bar #(
    parameter int unsigned DEBOUNCE_CYCLES = 1_250_000
) (
    input  logic CLK_125MHZ_P,
    input  logic CLK_125MHZ_N,
    input  logic GPIO_SW_C,
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

  localparam int unsigned DBNCCNTW = (DEBOUNCE_CYCLES > 1) ? $clog2(DEBOUNCE_CYCLES) : 1;
  localparam logic [DBNCCNTW-1:0] DBNCLAST = DBNCCNTW'(DEBOUNCE_CYCLES - 1);

  logic sw_meta = 1'b0;
  logic sw_sync = 1'b0;
  logic sw_stable = 1'b0;
  logic sw_stable_d = 1'b0;
  logic [DBNCCNTW-1:0] dbnc_cnt = '0;
  logic [3:0] led_count = '0;
  logic [7:0] led_mask;

  always_ff @(posedge clk_125mhz) begin
    sw_meta <= GPIO_SW_C;
    sw_sync <= sw_meta;
  end

  always_ff @(posedge clk_125mhz) begin
    if (sw_sync == sw_stable) begin
      dbnc_cnt <= '0;
    end else if (dbnc_cnt == DBNCLAST) begin
      sw_stable <= sw_sync;
      dbnc_cnt  <= '0;
    end else begin
      dbnc_cnt <= dbnc_cnt + 1'b1;
    end
  end

  always_ff @(posedge clk_125mhz) begin
    sw_stable_d <= sw_stable;

    if (!sw_stable_d && sw_stable) begin
      if (led_count >= 4'd8) begin
        led_count <= 4'd0;
      end else begin
        led_count <= led_count + 1'b1;
      end
    end
  end

  always_comb begin
    if (led_count == 4'd0) begin
      led_mask = 8'h00;
    end else if (led_count >= 4'd8) begin
      led_mask = 8'hFF;
    end else begin
      led_mask = (8'h01 << led_count) - 8'h01;
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
