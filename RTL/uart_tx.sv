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

always @(posedge i_clk or negedge i_rst) begin
  if (!i_rst) begin
    current_state <= IDLE;
    next_state <= IDLE;
    data_pointer <= 0;
    transmission <= 0;
    tx_out <= 1; // idle state for tx is high
  end
  else if (i_baud_x16_en) begin
    // State transition
    current_state <= next_state;


    // TX out driving logic
    case (current_state)
      IDLE: begin
        if (i_send_data) begin
          next_state <= START;
          data_pointer <= 0;
        end
        tx_out <= 1; // idle state
      end

      START: begin

        next_state <= DATA;
        if (next_state == DATA) begin
          // transmission <= 1; // transmission in progress
          tx_out <= 0;
          transmission <= 1;
        end
      end

      DATA: begin
        tx_out <= i_data_in[data_pointer];
        if (data_pointer == 7) begin
          next_state <= STOP;
        end
        else begin
          data_pointer <= data_pointer + 1;
        end
        if (next_state == STOP) begin
          // transmission <= 0; // transmission complete
          tx_out <= 0;
        end
      end

      STOP: begin
        tx_out <= 1; // stop bit is high
        next_state <= IDLE;
        transmission <= 0; // transmission complete
      end

      default: begin
        next_state <= IDLE;
      end
    endcase
  end
end

assign o_transmission = transmission;
assign o_tx_out = tx_out;

endmodule // uart_tx