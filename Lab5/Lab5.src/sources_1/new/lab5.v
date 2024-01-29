`timescale 1ns / 1ps
/////////////////////////////////////////////////////////
module lab5(
  input clk,
  input reset_n,
  input [3:0] usr_btn,
  output [3:0] usr_led,
  output LCD_RS,
  output LCD_RW,
  output LCD_E,
  output [3:0] LCD_D
);

// turn off all the LEDs
assign usr_led = 4'b0000;
reg p_btn;
wire btn;
reg [127:0] row_A = "Press BTN3 to   "; // Initialize the text of the first row. 
reg [127:0] row_B = "show a message.."; // Initialize the text of the second row.
reg [15:0] F[24:0];
integer i;
reg [5:0] now;

LCD_module lcd0(
  .clk(clk),
  .reset(~reset_n),
  .row_A(row_A),
  .row_B(row_B),
  .LCD_E(LCD_E),
  .LCD_RS(LCD_RS),
  .LCD_RW(LCD_RW),
  .LCD_D(LCD_D)
);
reg dir;//1=順時針 0=逆時針(回去)
reg start;//1=啟動 0=靜止(按下後啟動)
reg [5:0] index;
reg [47:0] f_str;
reg [31:0] m_str;
reg [7:0] str_0;
wire [127:0] result;
wire [15:0] num_str,now_num;
wire [7:0] num_1, num_2;
wire [31:0] real_str;
reg [31:0] timer;
assign num_1=(index+1)/10+"0";
assign num_2=(index+1)%10+"0";
assign num_str={num_1,num_2};
assign now_num = F[index];
assign result = {f_str,num_str,m_str,real_str};
debounce d1(.btn(usr_btn[3]), .clk(clk), .reset_n(reset_n), .a(btn));
convert c1(.clk(clk), .reset_n(reset_n), .number(now_num), .str(real_str));
always @(posedge clk,negedge reset_n) begin
    if(reset_n==0) begin
     // Initialize the text when the user hit the reset button
        row_A <= "Press BTN3 to   ";
        row_B <= "show a message..";
        f_str <= "Fibo #";
        str_0 <= "0";
        m_str <= " is ";
        timer <= 0;
        for(i=2; i<=25; i=i+1) begin
            F[i] <= 0;
        end
        F[0] <= 0;
        F[1] <= 16'd1;
        now <= 6'd2;
        dir <= 1;
        start <= 0;
        p_btn <= 0;
        index <= 1;//tmp
    end
    else begin
        if(now<6'd25) begin
            F[now] <= F[now-1] + F[now-2];
            now <= now+1;
        end
        else begin
            if(btn==1&&p_btn==0) begin
                if(start==0) begin
                    start <= 1;
                    row_A <= "Fibo #01 is 0000";
                    row_B <= "Fibo #02 is 0001";
                end
                else if(dir==1) begin
                    index <= (index-1+25)%25;//2(1,2) -> 1(1,2)  0(1,2) 1(-1,0)
                    dir <= 0;
                    timer <= 0;
                end
                else begin
                    index <= (index+1)%25;
                    dir <= 1;
                    timer <= 0;
                end
            end
            else begin
                if(start) begin
                    if(timer<32'd80_000_000) begin
                        if(timer==32'd75_000_000) begin
                            if(dir==1) index<=(index+1)%25;
                            else index<=(index-1+25)%25;
                        end
                        timer<=timer+1;
                    end
                    else begin
                        if(dir==1) begin
                            row_A <= row_B;
                            row_B <= result;
                        end
                        else begin
                            row_A <= result;
                            row_B <= row_A;
                        end
                        timer <= 0;
                    end
                end
            end
            p_btn <= btn;
        end
    end
end

endmodule

module convert(input clk,input reset_n,input[15:0] number,output [31:0] str);
    reg [31:0] result;
    reg [15:0] t_n;
    wire[7:0] a;
    reg [7:0] char[3:0];
    reg [3:0] counter;
    assign a = t_n%16;
    assign str = result;
    always @(posedge clk,negedge reset_n)begin
        if(reset_n==0) begin
            result <= 0;
            char[0] <= 0;
            char[1] <= 0;
            char[2] <= 0;
            char[3] <= 0;
            t_n <= 0;
            counter <= 4;
        end
        else begin
            if(counter==4) begin
               result <= {char[3],char[2],char[1],char[0]};
                t_n <= number;
                counter <= 0;
            end
            else begin
                case(a)
                    8'd0: char[counter] <= "0";
                    8'd1: char[counter] <= "1";
                    8'd2: char[counter] <= "2";
                    8'd3: char[counter] <= "3";
                    8'd4: char[counter] <= "4";
                    8'd5: char[counter] <= "5";
                    8'd6: char[counter] <= "6";
                    8'd7: char[counter] <= "7";
                    8'd8: char[counter] <= "8";
                    8'd9: char[counter] <= "9";
                    8'd10: char[counter] <= "A";
                    8'd11: char[counter] <= "B";      
                    8'd12: char[counter] <= "C";      
                    8'd13: char[counter] <= "D";      
                    8'd14: char[counter] <= "E";      
                    8'd15: char[counter] <= "F";      
                    default: char[counter] <="0";
                endcase
                t_n <= t_n/16;
                counter <= counter +1;
            end
        end
    end
endmodule

module debounce(input btn, input clk, input reset_n, output a);
    reg[31:0] timer=32'd0;
    reg out;
    assign a = out;
    always@(posedge clk,negedge reset_n)begin
        if(reset_n==0) begin
            out <= 0;
            timer <= 0;
        end 
        else begin
            if(a==btn) timer <= 32'd0;
            else begin
                timer<=timer+1;//100ns = 10次
                if(timer == 32'd500_0000) begin
                    out <= btn;
                    timer <= 0;
                end
            end
        end//用計時的方式完成
    end
endmodule
/*
0.7s auto scroll cyclically
BTN3 => revereed direction
*/