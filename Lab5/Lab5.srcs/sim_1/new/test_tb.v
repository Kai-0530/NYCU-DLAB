module tb_example;
    reg [3:0] usr_btn;
    wire [3:0] usr_led,LCD_D;
    wire LCD_RS,LCD_RW,LCD_E;
    reg reset_n,clk;
    initial begin
        #50 usr_btn[3]=1;
        #150 usr_btn[3]=0;
        #200 usr_btn[3]=1;
        #350 usr_btn[3]=0;
    end
    initial begin
        usr_btn = 0;
        reset_n = 0;
        clk = 0;
        #5 reset_n = 1;
        #5 reset_n = 0;
        #5 reset_n = 1;
        forever #5 clk = ~clk;
    end
    lab5 m1(
        .clk(clk),
        .reset_n(reset_n),
        .usr_btn(usr_btn),
        .usr_led(usr_led),
        .LCD_RS(LCD_RS),
        .LCD_RW(LCD_RW),
        .LCD_E(LCD_E),
        .LCD_D(LCD_D)
        );
// 添加仿真?的??代?

endmodule
