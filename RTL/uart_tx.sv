`timescale 1ns / 1ps

module uart_tx (
  input wire i_clk,
  input wire i_rst,
  input wire [7:0] i_data_in,
  input wire i_send_data,
  output wire o_transmission,
  output wire o_tx_out
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
  else begin 
    current_state <= next_state;
    case (current_state)
      IDLE: begin
        if (i_send_data) begin
          next_state <= START;
        end else begin
          next_state <= IDLE;
        end
      end
      START: begin
          next_state <= DATA;
          transmission <= 1;
          tx_out <= 0; // start bit is low
      end
      DATA: begin
        if (data_pointer < 7) begin
          next_state <= DATA;
          data_pointer <= data_pointer + 1;
          tx_out <= i_data_in[data_pointer];
        end else begin
          next_state <= STOP;
        end
      end
      STOP: begin
          next_state <= IDLE;
          tx_out <= 1; // stop bit is high
          transmission <= 0; // transmission complete
          data_pointer <= 0; // reset data pointer
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