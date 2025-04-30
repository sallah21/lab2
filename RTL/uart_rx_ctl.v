module uart_rx_ctl (
  input            i_clk,           // Clock input
  input            i_rst,          // Active HIGH reset - synchronous to clk_rx
  input            i_baud_x16_en,  // 16x oversampling enable

  input            i_rx_in_i_clk,   // RS232 RXD pin - after sync to clk_rx

  output [7:0]     o_rx_data,      // 8 bit data output
                                   //  - valid when rx_data_rdy is asserted
  output           o_rx_data_rdy,  // Ready signal for rx_data
  output           o_frm_err       // The STOP bit was not detected
);

  // State encoding for main FSM
  localparam 
    IDLE  = 2'b00,
    START = 2'b01,
    DATA  = 2'b10,
    STOP  = 2'b11;

  reg [1:0]    state;                // Main state machine
  reg [1:0]    next_state;
  reg [3:0]    over_sample_cnt;      // Oversample counter - 16 per bit
  reg [2:0]    bit_cnt;              // Bit counter - which bit are we RXing
  reg [7:0]    rx_data;              // 8 bit data output
  reg          rx_data_rdy;          // Ready signal for rx_data
  reg          frm_err;              // The STOP bit was not detected

  wire         over_sample_cnt_done; // We are in the middle of a bit
  wire         bit_cnt_done;         // This is the last data bit

  //State machine comb logic
  always @(*)
      begin
        
        case (state)
          IDLE: 
          begin
            // On detection of i_rx_in_i_clk being low, transition to the START
            // state
            next_state = IDLE;
            if (!i_rx_in_i_clk)
               begin
                 next_state = START;
               end 
          end // IDLE state
    
          START: 
          begin
            // After 1/2 bit period, re-confirm the start state
            next_state = START;
            if (over_sample_cnt_done)
            begin
              if (!i_rx_in_i_clk)
                begin
                  // Was a legitimate start bit (not a glitch)
                  next_state = DATA;
                end
              else
                begin
                  // Was a glitch - reject
                  next_state = IDLE;
                end
            end // if over_sample_cnt_done       
          end // START state
    
          DATA: 
          begin
            // Once the last bit has been received, check for the stop bit
            next_state = DATA;
            if (over_sample_cnt_done && bit_cnt_done)
            begin
              next_state = STOP;
            end
          end // DATA state
    
          STOP: 
          begin
            // Return to idle
            next_state = STOP;
            if (over_sample_cnt_done)
            begin
              next_state = IDLE;
            end
          end // STOP state
          
       default: 
          begin
            // Return to idle
              next_state = IDLE;
          end // default state
          
        endcase
    end // always 

  //State machine seq logic
  always @(posedge i_clk or negedge i_rst)
    begin
     if (!i_rst)
       begin
         state <=  IDLE;
       end
     else
       begin if (i_baud_x16_en) 
         state <= next_state;
       end
    end   

  // Oversample counter
  // Pre-load to 7 when a start condition is detected (i_rx_in_i_clk is 0 while in
  // IDLE) - this will get us to the middle of the first bit.
  // Pre-load to 15 after the START is confirmed and between all data bits.
  always @(posedge i_clk or negedge i_rst)
  begin
    if (!i_rst)
      begin
        over_sample_cnt    <= 4'd0;
      end
    else
    begin
      if (i_baud_x16_en) 
      begin
        if (!over_sample_cnt_done)
        begin
          over_sample_cnt <= over_sample_cnt - 1'b1;
        end
        else
        begin
          if ((state == IDLE) && !i_rx_in_i_clk)
          begin
            over_sample_cnt <= 4'd7;
          end
          else if ( ((state == START) && !i_rx_in_i_clk) || (state == DATA)  )
          begin
            over_sample_cnt <= 4'd15;
          end
        end
      end // if i_baud_x16_en
    end // if rst_clk_rx
  end // always 

  assign over_sample_cnt_done = (over_sample_cnt == 4'd0);

  // Track which bit we are about to receive
  // Set to 0 when we confirm the start condition
  // Increment in all DATA states
  always @(posedge i_clk or negedge i_rst)
  begin
    if (!i_rst)
    begin
      bit_cnt    <= 3'b0;
    end
    else
    begin
      if (i_baud_x16_en) 
      begin
        if (over_sample_cnt_done)
        begin
          if (state == START)
          begin
            bit_cnt <= 3'd0;
          end
          else if (state == DATA)
          begin
            bit_cnt <= bit_cnt + 1'b1;
          end
        end // if over_sample_cnt_done
      end // if i_baud_x16_en
    end // if rst_clk_rx
  end // always 

  assign bit_cnt_done = (bit_cnt == 3'd7);

  // Capture the data and generate the rdy signal
  // The rdy signal will be generated as soon as the last bit of data
  // is captured - even though the STOP bit hasn't been confirmed. It will
  // remain asserted for one BIT period (16 i_baud_x16_en periods)
  always @(posedge i_clk or negedge i_rst)
  begin
    if (!i_rst)
    begin
      rx_data     <= 8'b0000_0000;
      rx_data_rdy <= 1'b0;
    end
    else
    begin
      if (i_baud_x16_en && over_sample_cnt_done) 
      begin
        if (state == DATA)
        begin
          rx_data[bit_cnt] <= i_rx_in_i_clk;
          rx_data_rdy      <= (bit_cnt == 3'd7);
        end
        else
        begin
          rx_data_rdy      <= 1'b0;
        end
      end
    end // if rst_clk_rx
  end // always 

  // Framing error generation
  // Generate for one i_baud_x16_en period as soon as the framing bit
  // is supposed to be sampled
  always @(posedge i_clk or negedge i_rst)
  begin
    if (!i_rst)
    begin
      frm_err     <= 1'b0;
    end
    else
    begin
      if (i_baud_x16_en) 
      begin
        if ((state == STOP) && over_sample_cnt_done && !i_rx_in_i_clk)
        begin
          frm_err <= 1'b1;
        end
        else
        begin
          frm_err <= 1'b0;
        end
      end // if i_baud_x16_en
    end // if rst_clk_rx
  end // always 

  assign o_rx_data = rx_data;   
  assign o_rx_data_rdy = rx_data_rdy;
  assign o_frm_err = frm_err;    

endmodule
