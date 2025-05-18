`timescale 1ns / 1ps

module uart_tx #(
  parameter BAUD_RATE ,
  parameter CLOCK_RATE
) (
  input wire i_clk,
  input wire i_rst,
  input wire [7:0] i_data_in,
  input wire i_send_data,
  output wire o_transmission,
  output wire o_tx_out
);

uart_baud_gen #(
  .BAUD_RATE  (BAUD_RATE),
  .CLOCK_RATE (CLOCK_RATE)
) uart_baud_gen_rx_i0 (
  .i_clk         (i_clk),
  .i_rst         (i_rst),
  .o_baud_x16_en (i_baud_x16_en)
);

parameter  IDLE  = 2'b00, START = 2'b01, DATA  = 2'b10, STOP  = 2'b11;

reg [2:0] data_pointer;
reg       transmission;
reg [1:0] current_state;
reg [1:0] next_state;
reg       tx_out;
reg [3:0] bit_timer;  // Counter for baud rate timing

always @(posedge i_clk or negedge i_rst) begin
  if (!i_rst) begin
    current_state <= IDLE;
    data_pointer <= 0;
    transmission <= 0;
    tx_out <= 1; // idle state for tx is high
    bit_timer <= 4'd15; // Start at 15 to count down to 0
  end
  else if (i_baud_x16_en) begin
    case (current_state)
      IDLE: begin
        tx_out <= 1; // idle state
        bit_timer <= 4'd15; // Reset timer for next state
        if (i_send_data) begin
          current_state <= START;
          data_pointer <= 0;
        end
      end

      START: begin
        tx_out <= 0; // start bit
        if (bit_timer == 0) begin
          current_state <= DATA;
          bit_timer <= 4'd15; // Reset timer for data bits
        end else begin
          bit_timer <= bit_timer - 1;
        end
      end

      DATA: begin
        tx_out <= i_data_in[data_pointer];
        if (bit_timer == 0) begin
          if (data_pointer == 7) begin
            current_state <= STOP;
          end else begin
            data_pointer <= data_pointer + 1;
          end
          bit_timer <= 4'd15; // Reset timer for next bit
        end else begin
          bit_timer <= bit_timer - 1;
        end
      end

      STOP: begin
        tx_out <= 1; // stop bit
        if (bit_timer == 0) begin
          current_state <= IDLE;
        end else begin
          bit_timer <= bit_timer - 1;
        end
      end

      default: begin
        current_state <= IDLE;
      end
    endcase

    // Update transmission status
    transmission <= (current_state != IDLE);
  end
end

assign o_transmission = transmission;
assign o_tx_out = tx_out;

endmodule // uart_tx