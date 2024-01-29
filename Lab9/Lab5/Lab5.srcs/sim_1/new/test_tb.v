`timescale 1ns / 1ps
module lab9_tb;

  reg clk;
  reg reset_n;
  reg [3:0] usr_btn;
  wire [3:0] usr_led;
  wire LCD_RS, LCD_RW, LCD_E;
  wire [3:0] LCD_D;

  // Instantiate the lab9 module
  lab9 uut (
    .clk(clk),
    .reset_n(reset_n),
    .usr_btn(usr_btn),
    .usr_led(usr_led),
    .LCD_RS(LCD_RS),
    .LCD_RW(LCD_RW),
    .LCD_E(LCD_E),
    .LCD_D(LCD_D)
  );

  // Clock generation
  initial begin
    clk = 0;
    forever #5 clk = ~clk;
  end

  // Test sequence
  initial begin
    // Initialize inputs
    reset_n = 1;
    usr_btn = 4'b0000;
    #10 reset_n = 0;
    #10 reset_n = 1;
    #20 usr_btn = 4'b1111;
    #40 usr_btn = 4'b0000;
  end

endmodule

/*
  reg reset_n;
  reg clk;
  reg in;
  reg [0:63] txt;
  wire valid;
  wire [0:127] hash;

  // Instantiate the md5 module
  md5 uut (
    .reset_n(reset_n),
    .clk(clk),
    .in(in),
    .txt(txt),
    .valid(valid),
    .hash(hash)
  );

  initial begin
    clk = 0;
    forever #5 clk = ~clk;
  end

  initial begin
    reset_n = 1;
    in = 1;
    txt = "12345678"; // Replace with your eight-character string in hex format
    #20 reset_n = 0;
    #20 reset_n = 1;
    #20 in = 0;

  end

endmodule
*/
/*
  reg clk;
  reg reset_n;
  reg [3:0] usr_btn;
  wire [3:0] usr_led;
  wire LCD_RS, LCD_RW, LCD_E;
  wire [3:0] LCD_D;

  // Instantiate the lab9 module
  lab9 uut (
    .clk(clk),
    .reset_n(reset_n),
    .usr_btn(usr_btn),
    .usr_led(usr_led),
    .LCD_RS(LCD_RS),
    .LCD_RW(LCD_RW),
    .LCD_E(LCD_E),
    .LCD_D(LCD_D)
  );

  // Clock generation
  initial begin
    clk = 0;
    forever #5 clk = ~clk;
  end

  // Test sequence
  initial begin
    // Initialize inputs
    reset_n = 1;
    usr_btn = 4'b0000;

    // Apply reset
    #10 reset_n = 0;

    // Release reset and perform test
    #10 reset_n = 1;

    // Test scenario
    // (You need to add more meaningful test cases based on your module functionality)

    // Simulate button press
    #20 usr_btn = 4'b0001;

    // Simulate clock cycles
    #50 usr_btn = 4'b1111;

    // Add more test scenarios as needed...

    // Finish simulation
  end

endmodule*/
