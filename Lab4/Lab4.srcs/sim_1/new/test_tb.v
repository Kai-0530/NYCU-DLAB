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
  
  // 模???
  always begin
    #5 clk = ~clk;
  end
  
  // 初始化
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
    
    // 等待一段??，?察去抖后的按?信?
    #100 $display("debounced_button = %b", debounced_button);
    
    // ?止仿真
    $finish;
  end

endmodule