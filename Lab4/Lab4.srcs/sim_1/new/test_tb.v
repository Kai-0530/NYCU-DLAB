//`timescale 1ns/1ps

module testbench;
  reg clk;
  reg button;
  reg reset_n;
  wire debounced_button;
  
  // debounce(input btn, input clk, output a);
  debounce d5(
    .btn(button),
    .clk(clk),
    .reset_n(reset_n),
    .a(debounced_button)
  );
  
  // ��???
  always begin
    #5 clk = ~clk;
  end
  
  // ��l��
  initial begin
    clk = 0;
    reset_n = 1;
    button = 0;
    #5 reset_n = 0;
    #10 button = 1;
    #5 button = 0;
    #20 button = 1;
    #30 button = 0;
    #10 button = 1;
    
    // ���ݤ@�q??�A?��h�ݦZ����?�H?
    #100 $display("debounced_button = %b", debounced_button);
    
    // ?���u
    $finish;
  end

endmodule