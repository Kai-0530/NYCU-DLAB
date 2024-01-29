`timescale 1ns / 1ps

module lab8(
  // General system I/O ports
  input  clk,
  input  reset_n,
  input  [3:0] usr_btn,
  output [3:0] usr_led,

  // SD card specific I/O ports
  output spi_ss,
  output spi_sck,
  output spi_mosi,
  input  spi_miso,

  // 1602 LCD Module Interface
  output LCD_RS,
  output LCD_RW,
  output LCD_E,
  output [3:0] LCD_D
);

localparam [2:0] S_MAIN_INIT = 3'b000, S_MAIN_IDLE = 3'b001,
                 S_MAIN_WAIT1 = 3'b010, S_MAIN_READ1 = 3'b011,
                 S_MAIN_SHOW = 3'b101,
                 S_MAIN_WAIT2 = 3'b110, S_MAIN_READ2 = 3'b111;

// Declare system variables
wire btn_level, btn_pressed;
reg  prev_btn_level;
reg  [2:0] P, P_next;
reg  [9:0] sd_counter;
reg  [31:0] blk_addr;

reg  [127:0] row_A = "SD card cannot  ";
reg  [127:0] row_B = "be initialized! ";

// Declare SD card interface signals
wire clk_sel;
wire clk_500k;
reg  rd_req;
wire init_finished;
wire [7:0] sd_dout;
wire sd_valid;

// Declare the control/data signals of an SRAM memory block
wire [7:0] data_in;
wire [7:0] data_out;
wire [8:0] sram_addr;
wire       sram_we, sram_en;

assign clk_sel = (init_finished)? clk : clk_500k; // clock for the SD controller
assign usr_led = 4'h00;

clk_divider#(200) clk_divider0(
  .clk(clk),
  .reset(~reset_n),
  .clk_out(clk_500k)
);

debounce btn_db0(
  .clk(clk),
  .btn_input(usr_btn[2]),
  .btn_output(btn_level)
);

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

sd_card sd_card0(
  .cs(spi_ss),
  .sclk(spi_sck),
  .mosi(spi_mosi),
  .miso(spi_miso),

  .clk(clk_sel),
  .rst(~reset_n),
  .rd_req(rd_req),
  .block_addr(blk_addr),
  .init_finished(init_finished),
  .dout(sd_dout),
  .sd_valid(sd_valid)
);

sram ram0(
  .clk(clk),
  .we(sram_we),
  .en(sram_en),
  .addr(sram_addr),
  .data_i(data_in),
  .data_o(data_out)
);

//
// Enable one cycle of btn_pressed per each button hit
//
always @(posedge clk) begin
  if (~reset_n)
    prev_btn_level <= 0;
  else
    prev_btn_level <= btn_level;
end

assign btn_pressed = (btn_level == 1 && prev_btn_level == 0)? 1 : 0;

// ------------------------------------------------------------------------
// The following code sets the control signals of an SRAM memory block
// that is connected to the data output port of the SD controller.
// Once the read request is made to the SD controller, 512 bytes of data
// will be sequentially read into the SRAM memory block, one byte per
// clock cycle (as long as the sd_valid signal is high).
assign sram_we = sd_valid;          // Write data into SRAM when sd_valid is high.
assign sram_en = 1;                 // Always enable the SRAM block.
assign data_in = sd_dout;           // Input data always comes from the SD controller.
assign sram_addr = sd_counter[8:0]; // Set the driver of the SRAM address signal.
// End of the SRAM memory block
// ------------------------------------------------------------------------

// ------------------------------------------------------------------------
reg [63:0] str;
reg [15:0] ans_cnt;
always @(posedge clk) begin
    if(~reset_n) P <= S_MAIN_INIT;
    else P <= P_next;
end
always @(*) begin // FSM next-state logic
  case (P)
    S_MAIN_INIT: // wait for SD card initialization
      if (init_finished == 1) P_next = S_MAIN_IDLE;
      else P_next = S_MAIN_INIT;
    S_MAIN_IDLE: // wait for button click
      if (btn_pressed == 1) P_next = S_MAIN_WAIT1;
      else P_next = S_MAIN_IDLE;
    S_MAIN_WAIT1: // issue a rd_req to the SD controller until it's ready
      P_next = S_MAIN_READ1;
    S_MAIN_READ1: // wait for the input data to enter the SRAM buffer
      if(str == "DLAB_TAG") P_next = S_MAIN_READ2;
      else if (sd_counter == 512) P_next = S_MAIN_WAIT1;
      else P_next = S_MAIN_READ1;
    S_MAIN_READ2:
      if(str == "DLAB_END") P_next = S_MAIN_SHOW;
      else if(sd_counter == 512) P_next = S_MAIN_WAIT2;
      else P_next = S_MAIN_READ2;
    S_MAIN_WAIT2:
      P_next = S_MAIN_READ2;
    S_MAIN_SHOW:
      if (btn_pressed == 1) P_next = S_MAIN_IDLE;
    else P_next = S_MAIN_SHOW;
    default:
      P_next = S_MAIN_IDLE;
  endcase
end
    
always @(*) begin
  rd_req = (P == S_MAIN_WAIT1) || (P == S_MAIN_WAIT2);
end

always @(posedge clk) begin
    if (~reset_n || P == S_MAIN_WAIT1)
        ans_cnt <= 16'hFFFF;  // -1 for DLAB_TAG(find TAG)
    else if (P == S_MAIN_READ2 && sd_valid) begin
        if (!("a" <= (str[39:32]|8'h20) && (str[39:32]|8'h20) <= "z")
         &&  ("a" <= (str[31:24]|8'h20) && (str[31:24]|8'h20) <= "z")
         &&  ("a" <= (str[23:16]|8'h20) && (str[23:16]|8'h20) <= "z")
         &&  ("a" <= (str[15: 8]|8'h20) && (str[15: 8]|8'h20) <= "z")
         && !("a" <= (str[ 7: 0]|8'h20) && (str[ 7: 0]|8'h20) <= "z"))
            ans_cnt <= ans_cnt + 1;
    end
end

always @(posedge clk) begin
  if (~reset_n || P == S_MAIN_IDLE) blk_addr <= 32'h2000;
  else if(P == S_MAIN_WAIT1 || P == S_MAIN_WAIT2) blk_addr <= blk_addr + 1; // To next address
end

// FSM output logic: controls the 'sd_counter' signal.
// SD card read address incrementer
always @(posedge clk) begin
  if (~reset_n || P == S_MAIN_WAIT1 || P == S_MAIN_WAIT2)
    sd_counter <= 0;
  else if (sd_valid == 1)
    sd_counter <= sd_counter + 1;
end

always@(posedge clk) begin
    if(~reset_n) str <= 64'h0;
    else if(sd_valid && (P == S_MAIN_READ1 || P == S_MAIN_READ2)) begin
        str <= {str[55:0],sd_dout};//shift left
    end
end
// End of the FSM of the SD card reader
// ------------------------------------------------------------------------

// ------------------------------------------------------------------------
// LCD Display function.
always @(posedge clk) begin
  if (~reset_n) begin
    row_A = "SD card cannot  ";
    row_B = "be initialized! ";
  end 
  else if (P == S_MAIN_READ1) begin
    row_A <=  "Finding DLAB_TAG";
    row_B <= {"Cursor at 0x",
                ((blk_addr[15:12] > 9) ? "7" : "0") + blk_addr[15:12],
                ((blk_addr[11: 8] > 9) ? "7" : "0") + blk_addr[11: 8],
                ((blk_addr[ 7: 4] > 9) ? "7" : "0") + blk_addr[ 7: 4],
                ((blk_addr[ 3: 0] > 9) ? "7" : "0") + blk_addr[ 3: 0]};
  end
  else if (P == S_MAIN_SHOW) begin
    row_A <= {"Found ",
                ((ans_cnt[15:12] > 9)? "7" : "0") + ans_cnt[15:12],
                ((ans_cnt[11: 8] > 9)? "7" : "0") + ans_cnt[11: 8],
                ((ans_cnt[ 7: 4] > 9)? "7" : "0") + ans_cnt[ 7: 4],
                ((ans_cnt[ 3: 0] > 9)? "7" : "0") + ans_cnt[ 3: 0],
                " words"};
    row_B <= "in the text file";
  end
  else if (P == S_MAIN_IDLE) begin
    row_A <= "Hit BTN2 to read";
    row_B <= "the SD card ... ";
  end
end
// End of the LCD display function
// ------------------------------------------------------------------------

endmodule
