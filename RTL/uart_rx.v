module uart_rx #
(
  parameter BAUD_RATE    = 115_200,             // Baud rate
  parameter CLOCK_RATE   = 50_000_000
)
(
  // Write side inputs
  input            i_clk,       // Clock input
  input            i_rst,   // Active LOW reset

  input            i_rx_in,        // RS232 RXD pin - Directly from pad
  output           o_rx_in_i_clk,   // RXD pin after synchronization to i_clk

  output     [7:0] o_rx_data,      // 8 bit data output
                                 //  - valid when rx_data_rdy is asserted
  output           o_rx_data_rdy,  // Ready signal for rx_data
  output           o_frm_err       // The STOP bit was not detected
);

  wire             baud_x16_en;  // 1-in-N enable for uart_rx_ctl FFs
  wire             rx_in_i_clk;

  meta_harden meta_harden_rxd_i0 
  (
    .i_clk_dst      (i_clk),
    .i_rst_dst      (i_rst), 
    .i_signal_src   (i_rx_in),
    .o_signal_dst   (rx_in_i_clk)
  );

  uart_baud_gen #
  ( 
    .BAUD_RATE  (BAUD_RATE),
    .CLOCK_RATE (CLOCK_RATE)
  )
  uart_baud_gen_rx_i0 
  (
    .i_clk         (i_clk),
    .i_rst         (i_rst),
    .o_baud_x16_en (baud_x16_en)
  );

  uart_rx_ctl uart_rx_ctl_i0 
  (
    .i_clk         (i_clk),
    .i_rst         (i_rst),
    .i_baud_x16_en (baud_x16_en),

    .i_rx_in_i_clk (rx_in_i_clk),
    
    .o_rx_data_rdy (o_rx_data_rdy),
    .o_rx_data     (o_rx_data),
    .o_frm_err     (o_frm_err)
  );

  assign o_rx_in_i_clk = rx_in_i_clk;
endmodule
