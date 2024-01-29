`timescale 1ns / 1ps
module lab9(
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

localparam [1:0] S_INIT = 2'b00, S_CAL = 2'b01, S_SHOW = 2'b10;
reg [1:0] P, P_next;

wire btn_level, btn_pressed;
reg prev_btn_level;
reg [127:0] row_A = "Press BTN3 to   "; // Initialize the text of the first row. 
reg [127:0] row_B = "show a message.."; // Initialize the text of the second row.

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
    
debounce btn_db0(
  .btn(usr_btn[3]),
  .clk(clk),
  .reset_n(reset_n),
  .a(btn_level)
);

always @(posedge clk) begin
  if (~reset_n)
    prev_btn_level <= 1;
  else
    prev_btn_level <= btn_level;
end

assign btn_pressed = (btn_level == 1 && prev_btn_level == 0);

always@(posedge clk)begin
    if(~reset_n) begin
        P <= S_INIT;
        P_next <= S_INIT;
    end
    else P <= P_next;
end

//reg [0:127] passwd_hash = 128'hE8CD0953ABDFDE433DFEC7FAA70DF7F6;
reg [0:127] passwd_hash = 128'h94848cd1667b43859ab1113594528b20;
reg in[0:9];
reg [63:0] txt [0:9];//?
wire [0:127] hash [0:9];
wire valid [0:9];
reg get_answer;
reg [0:63] ans_txt;
//0000_0000 to 9999_9999
md5 ck1(.reset_n(reset_n), .clk(clk), .in(in[0]), .txt(txt[0]), .valid(valid[0]), .hash(hash[0]));
md5 ck2(.reset_n(reset_n), .clk(clk), .in(in[1]), .txt(txt[1]), .valid(valid[1]), .hash(hash[1]));
md5 ck3(.reset_n(reset_n), .clk(clk), .in(in[2]), .txt(txt[2]), .valid(valid[2]), .hash(hash[2]));
md5 ck4(.reset_n(reset_n), .clk(clk), .in(in[3]), .txt(txt[3]), .valid(valid[3]), .hash(hash[3]));
md5 ck5(.reset_n(reset_n), .clk(clk), .in(in[4]), .txt(txt[4]), .valid(valid[4]), .hash(hash[4]));
md5 ck6(.reset_n(reset_n), .clk(clk), .in(in[5]), .txt(txt[5]), .valid(valid[5]), .hash(hash[5]));
md5 ck7(.reset_n(reset_n), .clk(clk), .in(in[6]), .txt(txt[6]), .valid(valid[6]), .hash(hash[6]));
md5 ck8(.reset_n(reset_n), .clk(clk), .in(in[7]), .txt(txt[7]), .valid(valid[7]), .hash(hash[7]));
md5 ck9(.reset_n(reset_n), .clk(clk), .in(in[8]), .txt(txt[8]), .valid(valid[8]), .hash(hash[8]));
md5 ck10(.reset_n(reset_n), .clk(clk), .in(in[9]), .txt(txt[9]), .valid(valid[9]), .hash(hash[9]));


always@(*)begin
    case(P)
    S_INIT:
        if(btn_pressed) P_next = S_CAL;
        else P_next = S_INIT;
    S_CAL:
        if(get_answer) P_next = S_SHOW;
        else P_next = S_CAL;
    S_SHOW:
        if(btn_pressed) P_next = S_INIT;
        else P_next = S_SHOW;
    default:P_next = S_INIT;
    endcase
end

integer idx;
always@(posedge clk)begin
    if(~reset_n)begin
        get_answer <= 0;
        ans_txt <= 0;
    end
    else begin
        for(idx=0; idx<=9; idx=idx+1)begin
            if(hash[idx]==passwd_hash)begin
                ans_txt <= txt[idx];
                get_answer <= 1;
            end
        end
    end
end
reg  [87:0]  cnt;  //every 10ns will count
// Timer
always @(posedge clk) begin
    if (P == S_INIT) cnt <= "00000000000";
    else if (P == S_CAL) begin
        if (cnt[ 0 +: 4] == 4'h9) begin cnt[ 0 +: 4] <= 4'h0;
            if (cnt[ 8 +: 4] == 4'h9) begin cnt[ 8 +: 4] <= 4'h0;
                if (cnt[16 +: 4] == 4'h9) begin cnt[16 +: 4] <= 4'h0;
                    if (cnt[24 +: 4] == 4'h9) begin cnt[24 +: 4] <= 4'h0;
                        if (cnt[32 +: 4] == 4'h9) begin cnt[32 +: 4] <= 4'h0;
                            if (cnt[40 +: 4] == 4'h9) begin cnt[40 +: 4] <= 4'h0;
                                if (cnt[48 +: 4] == 4'h9) begin cnt[48 +: 4] <= 4'h0;
                                    if (cnt[56 +: 4] == 4'h9) begin cnt[56 +: 4] <= 4'h0;
                                        if (cnt[64 +: 4] == 4'h9) begin cnt[64 +: 4] <= 4'h0;
                                            if (cnt[72 +: 4] == 4'h9) begin cnt[72 +: 4] <= 4'h0;
                                                if (cnt[80 +: 4] == 4'h9) begin cnt[80 +: 4] <= 4'h0;
                                                end 
                                                else cnt[80 +: 4] <= cnt[80 +: 4] + 1;
                                            end 
                                            else cnt[72 +: 4] <= cnt[72 +: 4] + 1;
                                        end 
                                        else cnt[64 +: 4] <= cnt[64 +: 4] + 1;
                                    end 
                                    else cnt[56 +: 4] <= cnt[56 +: 4] + 1;
                                end 
                                else cnt[48 +: 4] <= cnt[48 +: 4] + 1;
                            end 
                            else cnt[40 +: 4] <= cnt[40 +: 4] + 1;
                        end 
                        else cnt[32 +: 4] <= cnt[32 +: 4] + 1;
                    end 
                    else cnt[24 +: 4] <= cnt[24 +: 4] + 1;
                end 
                else cnt[16 +: 4] <= cnt[16 +: 4] + 1;
            end 
            else cnt[ 8 +: 4] <= cnt[ 8 +: 4] + 1;
        end 
        else cnt[ 0 +: 4] <= cnt[ 0 +: 4] + 1;
    end
end

reg p_in [0:9];
always@(posedge clk) begin
    if(~reset_n || P == S_INIT)begin
        for(idx=0;idx<=9;idx=idx+1)begin
            p_in[idx] <= 0;
            in[idx] <= (P_next==S_CAL);
        end
    end
    else if(P==S_CAL) begin
        for(idx=0; idx<=9; idx=idx+1)begin
            if(p_in[idx]==1 && in[idx]==1) in[idx] <= 0;
            else if(valid[idx]==1) in[idx] <= 1;
            p_in[idx] <= in[idx];
        end
    end
end
reg check;
always@(posedge clk)begin
    if(~reset_n || P==S_INIT) begin
        check <= 0;
        txt[0] <= "00000000";
        txt[1] <= "10000000";
        txt[2] <= "20000000";
        txt[3] <= "30000000";
        txt[4] <= "40000000";
        txt[5] <= "50000000";
        txt[6] <= "60000000";
        txt[7] <= "70000000";
        txt[8] <= "80000000";
        txt[9] <= "90000000";
    end
    else if(P == S_CAL) begin
        for (idx=0; idx<=9; idx=idx+1) begin
            if(check&&in[idx]==1&&p_in[idx]==0)begin
                if (txt[idx][ 0 +: 4] == 4'h9) begin txt[idx][ 0 +: 4] <= 4'h0;
                if (txt[idx][ 8 +: 4] == 4'h9) begin txt[idx][ 8 +: 4] <= 4'h0;
                if (txt[idx][16 +: 4] == 4'h9) begin txt[idx][16 +: 4] <= 4'h0;
                if (txt[idx][24 +: 4] == 4'h9) begin txt[idx][24 +: 4] <= 4'h0;
                if (txt[idx][32 +: 4] == 4'h9) begin txt[idx][32 +: 4] <= 4'h0;
                if (txt[idx][40 +: 4] == 4'h9) begin txt[idx][40 +: 4] <= 4'h0;
                if (txt[idx][48 +: 4] == 4'h9) begin txt[idx][48 +: 4] <= 4'h0;
                if (txt[idx][56 +: 4] == 4'h9) begin txt[idx][56 +: 4] <= 4'h0;
                end else txt[idx][56 +: 4] <= txt[idx][56 +: 4] + 1;
                end else txt[idx][48 +: 4] <= txt[idx][48 +: 4] + 1;
                end else txt[idx][40 +: 4] <= txt[idx][40 +: 4] + 1;
                end else txt[idx][32 +: 4] <= txt[idx][32 +: 4] + 1;
                end else txt[idx][24 +: 4] <= txt[idx][24 +: 4] + 1;
                end else txt[idx][16 +: 4] <= txt[idx][16 +: 4] + 1;
                end else txt[idx][ 8 +: 4] <= txt[idx][ 8 +: 4] + 1;
                end else txt[idx][ 0 +: 4] <= txt[idx][ 0 +: 4] + 1;
            end
        end
        check <= 1;
    end
end

always @(posedge clk) begin
  if (~reset_n||P==S_INIT) begin
    row_A = "Press BTN3 to   ";
    row_B = "show a message..";
  end else if (P == S_CAL) begin
    row_A <= "Calculating.....";
    row_B <= "                ";
  end
  else if(P == S_CAL && P_next == S_SHOW)begin
    row_A <= {"Passwd: ",ans_txt};
    row_B <= {"Time:    ", cnt[40 +: 40], "ms"};//0~39 1_000_000ns=1ms
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
                if(timer == 32'd2) begin
                    out <= btn;
                    timer <= 0;
                end
            end
        end
    end
endmodule