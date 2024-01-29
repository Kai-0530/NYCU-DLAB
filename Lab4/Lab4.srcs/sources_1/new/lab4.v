`timescale 1ns / 1ps
module lab4(
  input  clk,            // System clock at 100 MHz
  input  reset_n,        // System reset signal, in negative logic
  input  [3:0] usr_btn,  // Four user pushbuttons
  output [3:0] usr_led   // Four yellow LEDs
);
    parameter pwm_period = 21'd1_000_000;//100M PWM
    reg [20:0] pwm_counter;
    reg pwm_now;
    reg [7:0] now_hz;//5%, 25%, 50%, 75%, and 100%
    reg signed [3:0] counter;
    wire [20:0] pwm_out_counter;
    wire btn0,btn1,btn2,btn3;
    debounce d1(.btn(usr_btn[0]), .clk(clk), .reset_n(reset_n), .a(btn0));
    debounce d2(.btn(usr_btn[1]), .clk(clk), .reset_n(reset_n), .a(btn1));
    debounce d3(.btn(usr_btn[2]), .clk(clk), .reset_n(reset_n), .a(btn2));
    debounce d4(.btn(usr_btn[3]), .clk(clk), .reset_n(reset_n), .a(btn3));
       
    assign usr_led = counter & {4{pwm_now}};    
    assign pwm_out_counter = (pwm_period/100)*now_hz;
    
    reg [3:0] b_btn;
    always@(posedge clk,negedge reset_n) begin
        if(reset_n==0) begin
            b_btn <= 0;
            counter <= 0;
            pwm_now <= 0;
            pwm_counter <= 21'b0;
            now_hz <= 8'd50;
        end
        else begin
            //counter
            if(btn1==1&&b_btn[1]==0&&counter!=7)begin
                counter <= counter + 1;
            end
            else if(btn0==1&&b_btn[0]==0&&counter!=-8)begin
                counter <= counter - 1;
            end
            b_btn[0] <= btn0;
            b_btn[1] <= btn1;
            //control brightness
            if(btn3==1&&b_btn[3]==0) begin
                case(now_hz)
                    8'd100: now_hz <= 8'd100;
                    8'd75: now_hz <= 8'd100;
                    8'd50: now_hz <= 8'd75;
                    8'd25: now_hz <= 8'd50;
                    8'd5: now_hz <= 8'd25;
                    default: now_hz <= 8'd100;
                endcase
            end
            else if(btn2==1&&b_btn[2]==0) begin
                case(now_hz)
                    8'd100: now_hz <= 8'd75;
                    8'd75: now_hz <= 8'd50;
                    8'd50: now_hz <= 8'd25;
                    8'd25: now_hz <= 8'd5;
                    8'd5: now_hz <= 8'd5;
                    default: now_hz <= 8'd5;
                endcase
            end
            b_btn[2]=btn2;
            b_btn[3]=btn3;
            //control pwm
            if(pwm_counter == pwm_period) begin
                pwm_counter <= 21'd0;
                pwm_now <= 1'b1;
            end
            else if(pwm_counter < pwm_out_counter) begin
                pwm_counter <= pwm_counter+1;
            end
            else begin
                pwm_now <= 1'b0;
                pwm_counter <= pwm_counter+1;
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
                timer<=timer+1;
                if(timer == 32'd500_0000) begin
                    out <= btn;
                    timer <= 0;
                end
            end
        end
    end
endmodule