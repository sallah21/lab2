`timescale 1ns / 1ps

module uart_tb
(
);

 parameter SYMULATION_RES      = 1_000_000_000; //Symultion resolution
 
 parameter CLK_F_HZ            = 50_000_000;    //Clock freq in HZ
 parameter CLK_T               = SYMULATION_RES / CLK_F_HZ; 
 
 parameter BAUD_RATE           = 115_200;       //UART Baud Rate
 parameter BAUD_RATE_T         = SYMULATION_RES / BAUD_RATE;  
 
 parameter BYTE_TO_SEND_NUM    = 9;             //Number of Bytes to send
 parameter BIT_TO_SEND_NUM     = BYTE_TO_SEND_NUM * 10 + 1;
   
 reg clk;
 reg rst;
 wire rx_in;
 
 reg [(BYTE_TO_SEND_NUM * 8)-1 : 0] bytes_to_send;
 reg [BIT_TO_SEND_NUM-1:0]          bits_to_send;
 
 wire [7:0] data_out;
 wire       data_rdy;
 
 integer bit_num;
 integer i;
 
 wire o_transmission;
 reg [7:0] data_in;
 reg send_data;

 // UART Receiver Instance
 uart_rx #(
     .BAUD_RATE  (BAUD_RATE),    
     .CLOCK_RATE (CLK_F_HZ)
 ) uart_rx_i (
     .i_clk         (clk),
     .i_rst         (rst),
     .i_rx_in       (rx_in),
     .o_rx_in_i_clk (),
     .o_rx_data     (data_out),
     .o_rx_data_rdy (data_rdy),
     .o_frm_err     ()
 );

 // UART Transmitter Instance
 uart_tx #(
    .BAUD_RATE(BAUD_RATE),
    .CLOCK_RATE(CLK_F_HZ)
 ) uart_tx_i (
    .i_clk(clk),
    .i_rst(rst),
    .o_tx_out(rx_in), // Connect tx output to rx input
    .o_transmission(o_transmission),
    .i_data_in(data_in),
    .i_send_data(send_data)
 );

 initial begin
     clk = 1'b1;
     rst = 1'b0;
     bit_num = 0;
     send_data = 0;
     data_in = 8'b10101010; // First data to send
     #4000 rst = 1'b1;

     // Wait a few clock cycles after reset
     repeat (5) @(posedge clk);

     // Send first byte
     @(posedge clk);
     send_data = 1;
     repeat (500) @(posedge clk);
     send_data = 0;

     // Wait for transmission to finish
     wait (o_transmission == 0);

     // Wait a few cycles before next byte
     repeat (10) @(posedge clk);

     // Send second byte
     data_in = 8'hEF;
     @(posedge clk);
     send_data = 1;
     @(posedge clk);
     send_data = 0;

     // Wait for transmission to finish
     wait (o_transmission == 0);

     // Finish simulation
     #100000 $finish;
 end       

 always #(CLK_T/2) clk = ~clk; // Clock generation

 always @ (posedge data_rdy) begin
     $display("Data received on UART interface:"); 
     $display("Data received (hex, ASCII) = %h at time: %t", data_out, $time);
 end

 always @ (posedge o_transmission) begin
     $display("Transmission started at time: %t", $time);
 end

 always @ (negedge o_transmission) begin
     $display("Transmission ended at time: %t", $time);
 end

endmodule