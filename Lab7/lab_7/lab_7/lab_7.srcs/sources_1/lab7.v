`timescale 1ns / 1ps

module lab7(
  input  clk,
  input  reset_n,
  input  [3:0] usr_btn,
  input  uart_rx,
  output uart_tx,
  output [3:0] usr_led,
  output LCD_RS,
  output LCD_RW,
  output LCD_E,
  output [3:0] LCD_D
);
                 
localparam [2:0] S_INIT=3'b000, S_CVT=3'b111,
                 S_READ=3'b001, S_ADDR=3'b101,
                 S_MUL=3'b010, S_WAIT=3'b011,
                 S_ADD=3'b110, S_SHOW=3'b100;
localparam [1:0] S_UART_IDLE = 0, S_UART_WAIT = 1,
                 S_UART_SEND = 2, S_UART_INCR = 3;
localparam msg_len = 170;
localparam str1 = 344,str2 = 600, str3 = 856, str4 = 1112; //after start +7 per number ( this if only 0x000)
localparam INIT_DELAY = 100_000; // 1 msec @ 100 MHz
reg  p_btn1;
wire btn1,btn_pressed;
reg  [2:0]  P, P_next;
reg  [11:0] user_addr;
wire print_enable, print_done;
reg [$clog2(msg_len):0] send_counter;
reg [1:0] Q, Q_next;
reg [$clog2(INIT_DELAY):0] init_counter;
reg  [0:msg_len*8-1] data = {"\015\012The matrix multiplication result is: \015\012[ 00000, 00000, 00000, 00000 ]\015\012[ 00000, 00000, 00000, 00000 ]\015\012[ 00000, 00000, 00000, 00000 ]\015\012[ 00000, 00000, 00000, 00000 ]\015\012",8'h00};
reg  [5:0] cnt,cnt2,i,j;
wire [10:0] sram_addr;
wire [10:0] sram_addr2;
wire [7:0]  data_in;
wire [7:0]  data_out;
wire [7:0]  data_out2;
wire        sram_we, sram_en;

// declare UART signals
wire transmit;
wire received;
wire [7:0] rx_byte;
wire [7:0] tx_byte;
wire is_receiving;
wire is_transmitting;
wire recv_error;
assign usr_led = 4'h00;

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
  

debounce btn_db1(
  .clk(clk),
  .btn_input(usr_btn[1]),
  .btn_output(btn1)
);

uart uart(
  .clk(clk),
  .rst(~reset_n),
  .rx(uart_rx),
  .tx(uart_tx),
  .transmit(transmit),
  .tx_byte(tx_byte),
  .received(received),
  .rx_byte(rx_byte),
  .is_receiving(is_receiving),
  .is_transmitting(is_transmitting),
  .recv_error(recv_error)
);

//
// Enable one cycle of btn_pressed per each button hit
//
always @(posedge clk) begin
  if (~reset_n)
    p_btn1 <= 0;
  else
    p_btn1 <= btn1;
end

assign btn_pressed = (btn1 & ~p_btn1);

always @(*) begin // FSM next-state logic
  case (P)
    S_INIT:
        if (init_counter < INIT_DELAY) P_next = S_INIT;
		else P_next = S_ADDR;
    S_ADDR:
        P_next = S_READ;
    S_READ:
        if(cnt < 6'd16) P_next = S_ADDR;
        else P_next = S_MUL;
    S_MUL:
        P_next = S_ADD;
    S_ADD:
        P_next = S_CVT;
    S_CVT:
        if(i==4) P_next = S_WAIT;
        else P_next = S_MUL;
    S_WAIT:
        if(btn_pressed) P_next = S_SHOW;
        else P_next = S_WAIT;
    S_SHOW:
        if(print_done) P_next = S_INIT;
        else P_next = S_SHOW;
  endcase
end

sram ram0(.clk(clk), .we(sram_we), .en(sram_en), .addr(sram_addr), .data_i(data_in), .data_o(data_out));
sram ram1(.clk(clk), .we(sram_we), .en(sram_en), .addr(sram_addr2), .data_i(data_in), .data_o(data_out2));

assign sram_we = usr_btn[3]; 
assign sram_en = (P == S_ADDR || P == S_READ); // Enable the SRAM block.
assign sram_addr = user_addr[11:0];//get what addr
assign sram_addr2= user_addr[11:0]+16;//get two addr
assign data_in = 8'b0; // SRAM is read-only so we tie inputs to zeros.
// End of the SRAM memory block.
// ------------------------------------------------------------------------

//preprocessed the output data
reg [7:0] matrixA[0:15];
reg [7:0] matrixB[0:15];
reg [39:0] matrix [0:3][0:3];
reg [17:0] tmp[0:3];//18-bit
reg [17:0] result; 
integer idx,idx2;

always @(posedge clk) begin
    if (P == S_SHOW) begin
        for(idx = 0, idx2 = 0; idx < 4; idx = idx + 1,idx2 = idx2 + 56) begin
            //idx and idx2 ok?
            data[str1+idx2 +: 40] <= matrix[0][idx];
            data[str2+idx2 +: 40] <= matrix[1][idx];
            data[str3+idx2 +: 40] <= matrix[2][idx];
            data[str4+idx2 +: 40] <= matrix[3][idx];
            /*
            data[str1+idx2 +: 40] <= matrix[0][idx][39:32]; 
            data[str1+idx2+1 +: 8] <= matrix[0][idx][31:24]; 
            data[str1+idx2+2 +: 8] <= matrix[0][idx][23:16]; 
            data[str1+idx2+3 +: 8] <= matrix[0][idx][15:8]; 
            data[str1+idx2+4 +: 8] <= matrix[0][idx][7:0];

            data[str2+idx2  +: 8] <= matrix[1][idx][39:32]; 
            data[str2+idx2+1+: 8] <= matrix[1][idx][31:24]; 
            data[str2+idx2+2+: 8] <= matrix[1][idx][23:16]; 
            data[str2+idx2+3+: 8] <= matrix[1][idx][15:8]; 
            data[str2+idx2+4+: 8] <= matrix[1][idx][7:0];
            
            data[str3+idx2  +: 8] <= matrix[2][idx][39:32]; 
            data[str3+idx2+1+: 8] <= matrix[2][idx][31:24]; 
            data[str3+idx2+2+: 8] <= matrix[2][idx][23:16]; 
            data[str3+idx2+3+: 8] <= matrix[2][idx][15:8]; 
            data[str3+idx2+4+: 8] <= matrix[2][idx][7:0];
            
            data[str4+idx2  +: 8] <= matrix[3][idx][39:32]; 
            data[str4+idx2+1+: 8] <= matrix[3][idx][31:24]; 
            data[str4+idx2+2+: 8] <= matrix[3][idx][23:16]; 
            data[str4+idx2+3+: 8] <= matrix[3][idx][15:8]; 
            data[str4+idx2+4+: 8] <= matrix[3][idx][7:0];*/
        end
  end
end
reg[3:0] pri[0:3];
always@(posedge clk) begin
    if(~reset_n) begin
        pri[0] <= 0;
        pri[1] <= 4'd4;
        pri[2] <= 4'd8;
        pri[3] <= 4'd12;
        cnt2 <= 0;
        i <= 0;
        j <= 0;
        for(idx = 0; idx<4; idx = idx + 1) tmp[idx] <= 0;
    end
    else if(P == S_INIT) begin
        cnt2 <= 0;
        i <= 0;
        j <= 0;
        for(idx = 0; idx<4; idx = idx + 1) tmp[idx] <= 0;
    end
    else if(P == S_MUL) begin
        tmp[0] <= matrixA[pri[i]]*matrixB[j];//i=0 j=0
        tmp[1] <= matrixA[pri[i]+1]*matrixB[j+4];
        tmp[2] <= matrixA[pri[i]+2]*matrixB[j+8];
        tmp[3] <= matrixA[pri[i]+3]*matrixB[j+12];
    end
    else if(P == S_ADD) begin
        result <= tmp[0]+tmp[1]+tmp[2]+tmp[3];
    end
    else if(P == S_CVT) begin
        matrix[i][j][39:32] = ((result[17:16] > 9)? "7" : "0") + result[17:16];
        matrix[i][j][31:24] = ((result[15:12] > 9)? "7" : "0") + result[15:12];
        matrix[i][j][23:16] = ((result[11:8] > 9)? "7" : "0") + result[11:8];
        matrix[i][j][15:8]  = ((result[7:4] > 9)? "7" : "0") + result[7:4];
        matrix[i][j][7:0]   = ((result[3:0] > 9)? "7" : "0") + result[3:0];
        if(j==4) begin
            j = 0;
            i = i + 1;
        end
        else j = j + 1;
    end
end

always @(posedge clk) begin
    if(~reset_n||P==S_INIT) begin
        user_addr <= 12'h000;
        cnt <= 0;
        for(idx = 0; idx<16; idx = idx + 1) begin
            matrixA[idx] <= 0;
            matrixB[idx] <= 0;
        end
    end
    else if(P == S_READ && cnt < 6'd16) begin
        matrixA[cnt] = data_out[7:0];
        matrixB[cnt] = data_out2[7:0];
//        matrixA[cnt][15:08] = ((data_out[7:4] > 9)? "7" : "0") + data_out[7:4];
//        matrixA[cnt][07: 0] = ((data_out[3:0] > 9)? "7" : "0") + data_out[3:0];
//        matrixB[cnt][15:08] = ((data_out2[7:4] > 9)? "7" : "0") + data_out2[7:4];
//        matrixB[cnt][07: 0] = ((data_out2[3:0] > 9)? "7" : "0") + data_out2[3:0];
        user_addr = user_addr + 1;
        cnt = cnt + 1;//move to changing state
    end
end

always @(posedge clk) begin
  if (~reset_n) begin
    P <= S_INIT; // read samples at 000 first
  end
  else begin
    P <= P_next;
  end
end

always @(posedge clk) begin
  if (P == S_INIT) init_counter <= init_counter + 1;
  else init_counter <= 0;
end

// ------------------------------------------------------------------------
//UART control

// FSM of the controller that sends a string to the UART.
always @(posedge clk) begin
  if (~reset_n) Q <= S_UART_IDLE;
  else Q <= Q_next;
end

always @(*) begin // FSM next-state logic
  case (Q)
    S_UART_IDLE: // wait for the print_string flag
      if (print_enable) Q_next = S_UART_WAIT;
      else Q_next = S_UART_IDLE;
    S_UART_WAIT: // wait for the transmission of current data byte begins
      if (is_transmitting == 1) Q_next = S_UART_SEND;
      else Q_next = S_UART_WAIT;
    S_UART_SEND: // wait for the transmission of current data byte finishes
      if (is_transmitting == 0) Q_next = S_UART_INCR; // transmit next character
      else Q_next = S_UART_SEND;
    S_UART_INCR:
      if (tx_byte == 8'h0) Q_next = S_UART_IDLE; // string transmission ends
      else Q_next = S_UART_WAIT;
  endcase
end

assign print_enable = (P != S_SHOW && P_next == S_SHOW);
assign print_done = (tx_byte == 8'h0);
assign transmit = (Q_next == S_UART_WAIT || print_enable);
assign tx_byte  = data[send_counter];

always @(posedge clk) begin
  case (P_next)
    S_INIT: send_counter <= 0;
    S_WAIT: send_counter <= 0;
    default: send_counter <= send_counter + (Q_next == S_UART_INCR);
  endcase
end

endmodule
