`timescale 1ns / 1ps

module morse_uart_decoder #(
    parameter int unsigned DEBOUNCE_CYCLES = 1_250_000,
    parameter int unsigned TIME_UNIT_CYCLES = 12_500_000,
    parameter int unsigned DOT_DASH_THRESHOLD_CYCLES = (2 * TIME_UNIT_CYCLES),
    parameter int unsigned LETTER_GAP_CYCLES = (3 * TIME_UNIT_CYCLES),
    parameter int unsigned WORD_GAP_CYCLES = (7 * TIME_UNIT_CYCLES),
    parameter int unsigned UART_CLKS_PER_BIT = 1085
) (
    input  logic CLK_125MHZ_P,
    input  logic CLK_125MHZ_N,
    input  logic GPIO_SW_C,
    output logic USB_UART_RX
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

  localparam logic [2:0] MaxMorseSymbols = 3'd4;

  localparam int unsigned DbncCntW = (DEBOUNCE_CYCLES > 1) ? $clog2(DEBOUNCE_CYCLES) : 1;
  localparam logic [DbncCntW-1:0] DbncLast = DbncCntW'(DEBOUNCE_CYCLES - 1);

  localparam int unsigned TimerMaxCyc =
      (WORD_GAP_CYCLES > DOT_DASH_THRESHOLD_CYCLES) ? WORD_GAP_CYCLES : DOT_DASH_THRESHOLD_CYCLES;
  localparam int unsigned TimerCntW = (TimerMaxCyc > 1) ? $clog2(TimerMaxCyc + 1) : 1;
  localparam logic [TimerCntW-1:0] TimerMaxVal = TimerCntW'(TimerMaxCyc);
  localparam logic [TimerCntW-1:0] DotDashThrVal = TimerCntW'(DOT_DASH_THRESHOLD_CYCLES);
  localparam logic [TimerCntW-1:0] LetterGapVal = TimerCntW'(LETTER_GAP_CYCLES);
  localparam logic [TimerCntW-1:0] WordGapVal = TimerCntW'(WORD_GAP_CYCLES);

  localparam int unsigned FIFO_DEPTH = 16;
  localparam int unsigned FifoPtrW = (FIFO_DEPTH > 1) ? $clog2(FIFO_DEPTH) : 1;
  localparam int unsigned FifoCntW = $clog2(FIFO_DEPTH + 1);
  localparam logic [FifoCntW-1:0] FifoDepthVal = FifoCntW'(FIFO_DEPTH);

  logic sw_meta = 1'b0;
  logic sw_sync = 1'b0;
  logic sw_stable = 1'b0;
  logic sw_stable_d = 1'b0;
  logic sw_idle_level = 1'b0;
  logic sw_idle_locked = 1'b0;
  logic sw_pressed;
  logic [DbncCntW-1:0] dbnc_cnt = '0;

  logic [TimerCntW-1:0] press_ticks = '0;
  logic [TimerCntW-1:0] gap_ticks = '0;

  logic [4:0] morse_bits = '0;
  logic [2:0] morse_len = '0;
  logic wait_word_space = 1'b0;

  logic [7:0] tx_fifo[FIFO_DEPTH];
  logic [FifoPtrW-1:0] fifo_wr_ptr = '0;
  logic [FifoPtrW-1:0] fifo_rd_ptr = '0;
  logic [FifoCntW-1:0] fifo_count = '0;

  logic uart_start = 1'b0;
  logic [7:0] uart_data = 8'h00;
  logic uart_busy;

  logic sw_rise;
  logic sw_fall;

  assign sw_pressed = sw_idle_locked ? (sw_stable ^ sw_idle_level) : 1'b0;
  assign sw_rise = !sw_stable_d && sw_pressed;
  assign sw_fall = sw_stable_d && !sw_pressed;

  function automatic logic [7:0] decode_morse_letter(input logic [2:0] symbol_count,
                                                     input logic [4:0] symbol_bits);
    logic [7:0] key;
    begin
      key = {symbol_count, symbol_bits};
      unique case (key)
        {3'd1, 5'b00000} : decode_morse_letter = "E";
        {3'd1, 5'b00001} : decode_morse_letter = "T";

        {3'd2, 5'b00000} : decode_morse_letter = "I";
        {3'd2, 5'b00001} : decode_morse_letter = "A";
        {3'd2, 5'b00010} : decode_morse_letter = "N";
        {3'd2, 5'b00011} : decode_morse_letter = "M";

        {3'd3, 5'b00000} : decode_morse_letter = "S";
        {3'd3, 5'b00001} : decode_morse_letter = "U";
        {3'd3, 5'b00010} : decode_morse_letter = "R";
        {3'd3, 5'b00011} : decode_morse_letter = "W";
        {3'd3, 5'b00100} : decode_morse_letter = "D";
        {3'd3, 5'b00101} : decode_morse_letter = "K";
        {3'd3, 5'b00110} : decode_morse_letter = "G";
        {3'd3, 5'b00111} : decode_morse_letter = "O";

        {3'd4, 5'b00000} : decode_morse_letter = "H";
        {3'd4, 5'b00001} : decode_morse_letter = "V";
        {3'd4, 5'b00010} : decode_morse_letter = "F";
        {3'd4, 5'b00100} : decode_morse_letter = "L";
        {3'd4, 5'b00110} : decode_morse_letter = "P";
        {3'd4, 5'b00111} : decode_morse_letter = "J";
        {3'd4, 5'b01000} : decode_morse_letter = "B";
        {3'd4, 5'b01001} : decode_morse_letter = "X";
        {3'd4, 5'b01010} : decode_morse_letter = "C";
        {3'd4, 5'b01011} : decode_morse_letter = "Y";
        {3'd4, 5'b01100} : decode_morse_letter = "Z";
        {3'd4, 5'b01101} : decode_morse_letter = "Q";
        default: decode_morse_letter = "?";
      endcase
    end
  endfunction

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

  always @(posedge clk_125mhz) begin : p_morse_uart
    logic enqueue_valid;
    logic [7:0] enqueue_char;
    logic push_valid;
    logic pop_valid;
    logic symbol_is_dash;
    logic [TimerCntW-1:0] gap_ticks_next;

    enqueue_valid = 1'b0;
    enqueue_char = 8'h00;
    push_valid = 1'b0;
    pop_valid = 1'b0;
    symbol_is_dash = 1'b0;
    gap_ticks_next = gap_ticks;

    uart_start  <= 1'b0;
    sw_stable_d <= sw_pressed;

    if (!sw_idle_locked) begin
      sw_idle_level  <= sw_stable;
      sw_idle_locked <= 1'b1;
    end

    if (sw_pressed) begin
      gap_ticks <= '0;
      if (press_ticks < TimerMaxVal) begin
        press_ticks <= press_ticks + 1'b1;
      end
    end else begin
      press_ticks <= '0;
      if (gap_ticks < TimerMaxVal) begin
        gap_ticks_next = gap_ticks + 1'b1;
        gap_ticks <= gap_ticks_next;
      end

      if ((morse_len != 3'd0) && (gap_ticks_next == LetterGapVal)) begin
        enqueue_valid = 1'b1;
        enqueue_char  = decode_morse_letter(morse_len, morse_bits);
        morse_bits <= '0;
        morse_len <= '0;
        wait_word_space <= 1'b1;
      end

      if (wait_word_space && (gap_ticks_next == WordGapVal)) begin
        if (!enqueue_valid) begin
          enqueue_valid = 1'b1;
          enqueue_char  = " ";
        end
        wait_word_space <= 1'b0;
      end
    end

    if (sw_rise) begin
      wait_word_space <= 1'b0;
    end

    if (sw_fall) begin
      symbol_is_dash = (press_ticks >= DotDashThrVal);
      if (morse_len < MaxMorseSymbols) begin
        morse_bits <= {morse_bits[3:0], symbol_is_dash};
        morse_len <= morse_len + 1'b1;
        wait_word_space <= 1'b0;
      end else begin
        morse_bits <= '0;
        morse_len <= '0;
        wait_word_space <= 1'b0;
        enqueue_valid = 1'b1;
        enqueue_char  = "?";
      end
    end

    if (enqueue_valid && (fifo_count < FifoDepthVal)) begin
      tx_fifo[fifo_wr_ptr] <= enqueue_char;
      fifo_wr_ptr <= fifo_wr_ptr + 1'b1;
      push_valid = 1'b1;
    end

    if (!uart_busy && !uart_start && (fifo_count != '0)) begin
      uart_data   <= tx_fifo[fifo_rd_ptr];
      uart_start  <= 1'b1;
      fifo_rd_ptr <= fifo_rd_ptr + 1'b1;
      pop_valid = 1'b1;
    end

    case ({
      push_valid, pop_valid
    })
      2'b10: fifo_count <= fifo_count + 1'b1;
      2'b01: fifo_count <= fifo_count - 1'b1;
      default: begin
      end
    endcase
  end

  uart_tx #(
      .CLKS_PER_BIT(UART_CLKS_PER_BIT)
  ) i_uart_tx (
      .clk(clk_125mhz),
      .start(uart_start),
      .data(uart_data),
      .tx(USB_UART_RX),
      .busy(uart_busy)
  );

endmodule
