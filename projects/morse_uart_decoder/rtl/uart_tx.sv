`timescale 1ns / 1ps

module uart_tx #(
    parameter int unsigned CLKS_PER_BIT = 1085
) (
    input logic clk,
    input logic start,
    input logic [7:0] data,
    output logic tx = 1'b1,
    output logic busy = 1'b0
);

  localparam int unsigned ClkCntW = (CLKS_PER_BIT > 1) ? $clog2(CLKS_PER_BIT) : 1;
  localparam logic [ClkCntW-1:0] ClksPerBitLast = ClkCntW'(CLKS_PER_BIT - 1);

  typedef enum logic [1:0] {
    UartIdle,
    UartStart,
    UartData,
    UartStop
  } uart_state_t;

  uart_state_t state = UartIdle;
  logic [ClkCntW-1:0] clk_cnt = '0;
  logic [2:0] bit_idx = '0;
  logic [7:0] tx_shift = 8'h00;

  always_ff @(posedge clk) begin
    case (state)
      UartIdle: begin
        tx <= 1'b1;
        busy <= 1'b0;
        clk_cnt <= '0;
        bit_idx <= '0;
        if (start) begin
          busy <= 1'b1;
          tx_shift <= data;
          state <= UartStart;
        end
      end

      UartStart: begin
        tx   <= 1'b0;
        busy <= 1'b1;
        if (clk_cnt == ClksPerBitLast) begin
          clk_cnt <= '0;
          state   <= UartData;
        end else begin
          clk_cnt <= clk_cnt + 1'b1;
        end
      end

      UartData: begin
        tx   <= tx_shift[0];
        busy <= 1'b1;
        if (clk_cnt == ClksPerBitLast) begin
          clk_cnt  <= '0;
          tx_shift <= {1'b0, tx_shift[7:1]};
          if (bit_idx == 3'd7) begin
            bit_idx <= '0;
            state   <= UartStop;
          end else begin
            bit_idx <= bit_idx + 1'b1;
          end
        end else begin
          clk_cnt <= clk_cnt + 1'b1;
        end
      end

      default: begin
        tx   <= 1'b1;
        busy <= 1'b1;
        if (clk_cnt == ClksPerBitLast) begin
          clk_cnt <= '0;
          state   <= UartIdle;
        end else begin
          clk_cnt <= clk_cnt + 1'b1;
        end
      end
    endcase
  end

endmodule
