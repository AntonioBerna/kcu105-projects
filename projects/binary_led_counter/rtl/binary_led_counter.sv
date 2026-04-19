`timescale 1ns / 1ps

module binary_led_counter #(
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

  localparam int unsigned DbncCntW = (DEBOUNCE_CYCLES > 1) ? $clog2(DEBOUNCE_CYCLES) : 1;
  localparam logic [DbncCntW-1:0] DbncLast = DbncCntW'(DEBOUNCE_CYCLES - 1);

  logic sw_meta = 1'b0;
  logic sw_sync = 1'b0;
  logic sw_stable = 1'b0;
  logic sw_stable_d = 1'b0;
  logic [DbncCntW-1:0] dbnc_cnt = '0;
  logic [7:0] led_count = '0;

  always_ff @(posedge clk_125mhz) begin
    sw_meta <= GPIO_SW_C;
    sw_sync <= sw_meta;
  end

  always_ff @(posedge clk_125mhz) begin
    if (sw_sync == sw_stable) begin
      dbnc_cnt <= '0;
    end else if (dbnc_cnt == DbncLast) begin
      sw_stable <= sw_sync;
      dbnc_cnt  <= '0;
    end else begin
      dbnc_cnt <= dbnc_cnt + 1'b1;
    end
  end

  always_ff @(posedge clk_125mhz) begin
    sw_stable_d <= sw_stable;

    if (!sw_stable_d && sw_stable) begin
      led_count <= led_count + 1'b1;
    end
  end

  assign GPIO_LED_0_LS = led_count[0];
  assign GPIO_LED_1_LS = led_count[1];
  assign GPIO_LED_2_LS = led_count[2];
  assign GPIO_LED_3_LS = led_count[3];
  assign GPIO_LED_4_LS = led_count[4];
  assign GPIO_LED_5_LS = led_count[5];
  assign GPIO_LED_6_LS = led_count[6];
  assign GPIO_LED_7_LS = led_count[7];

endmodule
