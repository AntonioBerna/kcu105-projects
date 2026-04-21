`timescale 1ns / 1ps

module tb;
  localparam int unsigned DebounceCycles = 2;
  localparam int unsigned UnitCycles = 8;
  localparam int unsigned DotDashThresholdCycles = (2 * UnitCycles);
  localparam int unsigned LetterGapCycles = (3 * UnitCycles);
  localparam int unsigned WordGapCycles = (7 * UnitCycles);
  localparam int unsigned UartClksPerBit = 8;
  localparam int unsigned ExpectedBytes = 26;

  logic clk_p;
  logic clk_n;
  logic gpio_sw_c;
  logic usb_uart_rx;

  logic [7:0] rx_data[ExpectedBytes];
  logic [7:0] expected[ExpectedBytes];
  int rx_count;

  morse_uart_decoder #(
      .DEBOUNCE_CYCLES(DebounceCycles),
      .TIME_UNIT_CYCLES(UnitCycles),
      .DOT_DASH_THRESHOLD_CYCLES(DotDashThresholdCycles),
      .LETTER_GAP_CYCLES(LetterGapCycles),
      .WORD_GAP_CYCLES(WordGapCycles),
      .UART_CLKS_PER_BIT(UartClksPerBit)
  ) dut (
      .CLK_125MHZ_P(clk_p),
      .CLK_125MHZ_N(clk_n),
      .GPIO_SW_C(gpio_sw_c),
      .USB_UART_RX(usb_uart_rx)
  );

  assign clk_n = ~clk_p;

  always #4 clk_p = ~clk_p;  // 125 MHz

  task automatic hold_switch(input logic level, input int unsigned unit_count);
    int i;
    begin
      gpio_sw_c = level;
      for (i = 0; i < (unit_count * UnitCycles); i++) begin
        @(posedge clk_p);
      end
    end
  endtask

  task automatic morse_dot;
    begin
      hold_switch(1'b1, 1);
      hold_switch(1'b0, 1);
    end
  endtask

  task automatic morse_dash;
    begin
      hold_switch(1'b1, 3);
      hold_switch(1'b0, 1);
    end
  endtask

  task automatic finish_letter_gap;
    begin
      hold_switch(1'b0, 2);
    end
  endtask

  task automatic send_letter(input logic [7:0] letter);
    begin
      case (letter)
        "A": begin
          morse_dot();
          morse_dash();
        end
        "B": begin
          morse_dash();
          morse_dot();
          morse_dot();
          morse_dot();
        end
        "C": begin
          morse_dash();
          morse_dot();
          morse_dash();
          morse_dot();
        end
        "D": begin
          morse_dash();
          morse_dot();
          morse_dot();
        end
        "E": begin
          morse_dot();
        end
        "F": begin
          morse_dot();
          morse_dot();
          morse_dash();
          morse_dot();
        end
        "G": begin
          morse_dash();
          morse_dash();
          morse_dot();
        end
        "H": begin
          morse_dot();
          morse_dot();
          morse_dot();
          morse_dot();
        end
        "I": begin
          morse_dot();
          morse_dot();
        end
        "J": begin
          morse_dot();
          morse_dash();
          morse_dash();
          morse_dash();
        end
        "K": begin
          morse_dash();
          morse_dot();
          morse_dash();
        end
        "L": begin
          morse_dot();
          morse_dash();
          morse_dot();
          morse_dot();
        end
        "M": begin
          morse_dash();
          morse_dash();
        end
        "N": begin
          morse_dash();
          morse_dot();
        end
        "O": begin
          morse_dash();
          morse_dash();
          morse_dash();
        end
        "P": begin
          morse_dot();
          morse_dash();
          morse_dash();
          morse_dot();
        end
        "Q": begin
          morse_dash();
          morse_dash();
          morse_dot();
          morse_dash();
        end
        "R": begin
          morse_dot();
          morse_dash();
          morse_dot();
        end
        "S": begin
          morse_dot();
          morse_dot();
          morse_dot();
        end
        "T": begin
          morse_dash();
        end
        "U": begin
          morse_dot();
          morse_dot();
          morse_dash();
        end
        "V": begin
          morse_dot();
          morse_dot();
          morse_dot();
          morse_dash();
        end
        "W": begin
          morse_dot();
          morse_dash();
          morse_dash();
        end
        "X": begin
          morse_dash();
          morse_dot();
          morse_dot();
          morse_dash();
        end
        "Y": begin
          morse_dash();
          morse_dot();
          morse_dash();
          morse_dash();
        end
        "Z": begin
          morse_dash();
          morse_dash();
          morse_dot();
          morse_dot();
        end
        default: begin
          $fatal(1, "Unsupported letter '%c'", letter);
        end
      endcase

      finish_letter_gap();
    end
  endtask

  task automatic uart_read_byte(output logic [7:0] byte_out);
    int i;
    begin
      byte_out = 8'h00;
      @(negedge usb_uart_rx);
      repeat (UartClksPerBit + (UartClksPerBit / 2)) @(posedge clk_p);

      for (i = 0; i < 8; i++) begin
        byte_out[i] = usb_uart_rx;
        repeat (UartClksPerBit) @(posedge clk_p);
      end

      if (usb_uart_rx !== 1'b1) begin
        $fatal(1, "UART stop bit error");
      end
    end
  endtask

  initial begin : p_capture_uart
    logic [7:0] byte_rx;

    forever begin
      uart_read_byte(byte_rx);
      if (rx_count < ExpectedBytes) begin
        rx_data[rx_count] = byte_rx;
        rx_count = rx_count + 1;
      end
    end
  end

  initial begin
    int i;
    int timeout_cycles;

    for (i = 0; i < ExpectedBytes; i++) begin
      rx_data[i]  = 8'h00;
      expected[i] = 8'h00;
    end

    expected[0] = "A";
    expected[1] = "B";
    expected[2] = "C";
    expected[3] = "D";
    expected[4] = "E";
    expected[5] = "F";
    expected[6] = "G";
    expected[7] = "H";
    expected[8] = "I";
    expected[9] = "J";
    expected[10] = "K";
    expected[11] = "L";
    expected[12] = "M";
    expected[13] = "N";
    expected[14] = "O";
    expected[15] = "P";
    expected[16] = "Q";
    expected[17] = "R";
    expected[18] = "S";
    expected[19] = "T";
    expected[20] = "U";
    expected[21] = "V";
    expected[22] = "W";
    expected[23] = "X";
    expected[24] = "Y";
    expected[25] = "Z";

    clk_p = 1'b0;
    gpio_sw_c = 1'b0;
    rx_count = 0;

    $dumpfile("dump.vcd");
    $dumpvars(0, tb);
    $dumpon;

    repeat (20) @(posedge clk_p);

    send_letter("A");
    send_letter("B");
    send_letter("C");
    send_letter("D");
    send_letter("E");
    send_letter("F");
    send_letter("G");
    send_letter("H");
    send_letter("I");
    send_letter("J");
    send_letter("K");
    send_letter("L");
    send_letter("M");
    send_letter("N");
    send_letter("O");
    send_letter("P");
    send_letter("Q");
    send_letter("R");
    send_letter("S");
    send_letter("T");
    send_letter("U");
    send_letter("V");
    send_letter("W");
    send_letter("X");
    send_letter("Y");
    send_letter("Z");

    timeout_cycles = 0;
    while ((rx_count < ExpectedBytes) && (timeout_cycles < 200_000)) begin
      @(posedge clk_p);
      timeout_cycles++;
    end

    if (rx_count < ExpectedBytes) begin
      $fatal(1, "Timeout waiting UART bytes: got %0d expected %0d", rx_count, ExpectedBytes);
    end

    for (i = 0; i < ExpectedBytes; i++) begin
      if (rx_data[i] !== expected[i]) begin
        $fatal(1, "Byte %0d mismatch: expected '%c' (0x%02h), got '%c' (0x%02h)", i, expected[i],
               expected[i], rx_data[i], rx_data[i]);
      end
    end

    $display("PASS: decoded Morse alphabet from SW7 to UART plaintext: A-Z");
    $dumpflush;
    #20;
    $finish;
  end

endmodule
