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
 reg rx_in;

 reg [(BYTE_TO_SEND_NUM * 8)-1 : 0] bytes_to_send;
 reg [BIT_TO_SEND_NUM-1:0]          bits_to_send;
 
 wire [7:0] data_out;
 wire       data_rdy;
 
 integer bit_num;
 integer i;
 
 
   uart_rx #                      //Uart receiver
   (
     .BAUD_RATE  (BAUD_RATE),    
     .CLOCK_RATE (CLK_F_HZ)
   )
   uart_rx_i
   (
     .i_clk         (clk),
     .i_rst         (rst),
   
     .i_rx_in       (tx_out),
     .o_rx_in_i_clk (),
   
     .o_rx_data     (data_out),
   
     .o_rx_data_rdy (data_rdy),
     .o_frm_err     ()
   );


   reg send_data;
   reg [7:0] bits_to_send_tx;
   wire tx_out;
   wire transmission;
   uart_tx uart_tx_i
   (
        .i_clk         (clk),
        .i_rst         (rst),
    
        .i_data_in     (bits_to_send_tx),
        .i_send_data   (send_data),
    
        .o_tx_out      (tx_out),
        .o_transmission(transmission)
   ) ;//Uart transmitter
 
    // initial  //Data to send preparation
    //    begin
    //        bytes_to_send = { 8'h57,
    //                          8'h65,
    //                          8'h6C,
    //                          8'h6C,
    //                          8'h20,
    //                          8'h44,
    //                          8'h6F,
    //                          8'h6E,
    //                          8'h65 };
       
    //        bits_to_send[0] = 1'b1;
           
    //        for (i = 0 ; i < BYTE_TO_SEND_NUM ; i=i+1)
    //           begin
    //               bits_to_send[(i*10+1)+:10] = add_start_and_stop_bit(bytes_to_send[(i*8)+:8]);
    //           end                      
    //    end
   
//    initial //Main Inital
//        begin
//            clk = 1'b1;
//            rst = 1'b0;
//            rx_in = 1'b1;
//            bit_num = 0;
//            send_data = 1'b0;

//            #4000
//            rst = 1'b1;   
//            bits_to_send_tx = 8'b10101011; // 8'h55;
//            send_data = 1'b1;
//            #((BIT_TO_SEND_NUM + 10) * BAUD_RATE_T + 10000) 
//            $finish;
//        end      


       initial //Main Initial
       begin
           clk = 1'b1;
           rst = 1'b0;
           rx_in = 1'b1;
           bit_num = 0;
           send_data = 1'b0;
       
           #4000
           rst = 1'b1;
       
           for (i = 0; i < BYTE_TO_SEND_NUM; i = i + 1) begin
            //    wait(data_rdy); // Wait for data ready signal
               bits_to_send_tx = 8'b10101011; // 8'h55;
               send_data = 1'b1; // Pulse send_data
               #CLK_T;           // Wait for one clock cycle
               send_data = 1'b0;
       
               // Wait for transmission to complete
               wait (!transmission);
               #BAUD_RATE_T; // Add some delay before sending the next byte
           end
       
           #1000000
           $finish;
       end       
   always #(CLK_T/2) clk = ~clk; //clock 
   
//    always #(BAUD_RATE_T) //data sender
//         begin
//            bit_num = bit_num + 1;
//            rx_in = bits_to_send[bit_num];
//            if (bit_num >= BIT_TO_SEND_NUM) rx_in = 1'b1;
//         end  
   
   always @ (posedge data_rdy) //data monitor
    begin
        $display("Data received on UART interface:"); 
        $display("Data received (hex, ASCII) = %h at time: %t", data_out, $time);
    end    

    always # (BAUD_RATE_T) //Simulation monitor
        begin
            // $display("bitnum: %d  at time: %t", bit_num, $time);
            if (bit_num%10 ==0 && rx_in==1) begin
                $display("Start bit at time: %t", $time);
            end 
            else if (bit_num%10 ==9 && rx_in==0) begin
                $display("Stop bit at time: %t", $time);
            end 
            else begin

                $display("DATA send = %d at time: %t", rx_in, $time);
            end

        end
    

    function [9:0] add_start_and_stop_bit;
        input [7:0] data;
        begin
            add_start_and_stop_bit = {1'b1,data,1'b0};
        end
    endfunction        
 
endmodule
