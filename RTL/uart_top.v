`timescale 1ns / 1ps

module uart_top
#(
  parameter SYMULATION_RES      = 1_000_000_000, //Symultion resolution
  parameter CLK_F_HZ            = 50_000_000,    //Clock freq in HZ
  parameter CLK_T               = SYMULATION_RES / CLK_F_HZ, 
  parameter BAUD_RATE           = 115_200,       //UART Baud Rate
  parameter BAUD_RATE_T         = SYMULATION_RES / BAUD_RATE,  
  parameter BYTE_TO_SEND_NUM    = 9,             //Number of Bytes to send
  parameter BIT_TO_SEND_NUM     = BYTE_TO_SEND_NUM * 10 + 1
)
(
    input clk,
    input rst,
    input reg [7:0] data_in,
    output reg [7:0] data_out,
    output reg data_rdy,
    output reg o_transmission,
    input reg send_data
);

uart_rx #                      //Uart receiver
(
  .BAUD_RATE  (BAUD_RATE),    
  .CLOCK_RATE (CLK_F_HZ)
)
uart_rx_i
(
  .i_clk         (clk),
  .i_rst         (rst),

  .i_rx_in       (rx_in),
  .o_rx_in_i_clk (),

  .o_rx_data     (data_out),

  .o_rx_data_rdy (data_rdy),
  .o_frm_err     ()
);

uart_tx #(
 .BAUD_RATE(BAUD_RATE),
 .CLOCK_RATE(CLK_F_HZ)
) uart_tx_i (
 .i_clk(clk),
 .i_rst(rst),
 .o_tx_out(rx_in),
 .o_transmission(o_transmission),
 .i_data_in(data_in),
 .i_send_data(send_data)
);

endmodule
// Compare this snippet from RTL/uart_tx.v: