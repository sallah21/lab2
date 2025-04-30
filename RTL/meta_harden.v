module meta_harden (
  input            i_clk_dst,      // Destination clock
  input            i_rst_dst,      // Reset - synchronous to destination clock
  input            i_signal_src,   // Asynchronous signal to be synchronized
  output           o_signal_dst    // Synchronized signal
);

  reg           signal_dst;
  reg           signal_meta;     // After sampling the async signal, this has
                                 // a high probability of being metastable.
                                 // The second sampling (signal_dst) has
                                 // a much lower probability of being
                                 // metastable

  always @(posedge i_clk_dst or negedge i_rst_dst)
  begin
    if (!i_rst_dst)
    begin
      signal_meta <= 1'b0;
      signal_dst  <= 1'b0;
    end
    else // if !rst_dst
    begin
      signal_meta <= i_signal_src;
      signal_dst  <= signal_meta;
    end // if rst
  end // always

  assign o_signal_dst = signal_dst;
endmodule

