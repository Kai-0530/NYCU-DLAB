`timescale 1ns / 1ps

module lab10(
    input  clk,
    input  reset_n,
    input  [3:0] usr_btn,
    output [3:0] usr_led,
    
    // VGA specific I/O ports
    output VGA_HSYNC,
    output VGA_VSYNC,
    output [3:0] VGA_RED,
    output [3:0] VGA_GREEN,
    output [3:0] VGA_BLUE
    );

// Declare FISH variables
reg  [31:0] fish_clock,fish_clock_2,fish_clock_3;
reg  [31:0] fish_clock_1c,fish_clock_2c,fish_clock_3c;
wire [9:0]  pos,pos2,pos3,pos2c,pos3c,pos1c;
wire        fish_region,fish_region_2,fish_region_3,fish_region_2c,fish_region_3c,fish_region_1c;

// declare SRAM control signals
wire [16:0] sram_addr,sram_addr_fh1,sram_addr_fh2,sram_addr_fh3;
wire [11:0] data_in;
wire [11:0] data_out,data_out_fh1,data_out_fh2,data_out_fh3;
wire        sram_we, sram_en;

// General VGA control signals
wire vga_clk;         // 50MHz clock for VGA control
wire video_on;        // when video_on is 0, the VGA controller is sending
                      // synchronization signals to the display device.
  
wire pixel_tick;      // when pixel tick is 1, we must update the RGB value
                      // based for the new coordinate (pixel_x, pixel_y)


wire [9:0] pixel_x;   // x coordinate of the next pixel (between 0 ~ 639) 
wire [9:0] pixel_y;   // y coordinate of the next pixel (between 0 ~ 479)


wire [3:0] btn_level, btn;
reg  [3:0] prev_btn;
debounce btn_db0(.clk(clk), .btn_input(usr_btn[0]), .btn_output(btn_level[0]));
debounce btn_db1(.clk(clk), .btn_input(usr_btn[1]), .btn_output(btn_level[1]));
debounce btn_db2(.clk(clk), .btn_input(usr_btn[2]), .btn_output(btn_level[2]));
reg dir;
always @(posedge clk) begin
  if (~reset_n) prev_btn <= 4'h0;
  else prev_btn <= btn_level;
end

assign btn = (btn_level & ~prev_btn);
  
reg  [11:0] rgb_reg;  // RGB value for the current pixel
reg  [11:0] rgb_next; // RGB value for the next pixel
  
// Application-specific VGA signals
reg  [17:0] pixel_addr,pixel_addr_fh1,pixel_addr_fh2,pixel_addr_fh3;

// Declare the video buffer size
localparam VBUF_W = 320; // video buffer width
localparam VBUF_H = 240; // video buffer height

// Set parameters for the fish images
localparam FISH_VPOS   = 64; // Vertical location of the fish in the sea image.
//localparam FISH2_VPOS   = 100;
reg [17:0] FISH2_V;
localparam FISH3_VPOS   = 180;
localparam FISH1c_VPOS   = 100;
localparam FISH2c_VPOS   = 120;
localparam FISH3c_VPOS   = 16;

localparam FISH_W      = 64; // Width of the fish.
localparam FISH_H1      = 32; // Height of the fish.
localparam FISH_H2      = 44; // Height of the fish.
localparam FISH_H3      = 44; // Height of the fish.

reg [17:0] fish_addr[0:8];   // Address array for up to 2 fish images.
reg [17:0] fish2_addr[0:8];   // Address array for up to 2 fish images.
reg [17:0] fish3_addr[0:8];   // Address array for up to 2 fish images.


initial begin
  fish_addr[0] = VBUF_W*VBUF_H + 18'd0;         /* Addr for fish image #1 */
  fish_addr[1] = VBUF_W*VBUF_H + FISH_W*FISH_H1; /* Addr for fish image #2 */
  fish_addr[2] = VBUF_W*VBUF_H + FISH_W*FISH_H1*2; /* Addr for fish image #3 */
  fish_addr[3] = VBUF_W*VBUF_H + FISH_W*FISH_H1*3; /* Addr for fish image #4 */
  fish_addr[4] = VBUF_W*VBUF_H + FISH_W*FISH_H1*4; /* Addr for fish image #5 */
  fish_addr[5] = VBUF_W*VBUF_H + FISH_W*FISH_H1*5; /* Addr for fish image #6 */
  fish_addr[6] = VBUF_W*VBUF_H + FISH_W*FISH_H1*6; /* Addr for fish image #7 */
  fish_addr[7] = VBUF_W*VBUF_H + FISH_W*FISH_H1*7; /* Addr for fish image #8 */

  fish2_addr[0] = 0;
  fish2_addr[1] = FISH_W*FISH_H2;
  fish2_addr[2] = FISH_W*FISH_H2*2;
  fish2_addr[3] = FISH_W*FISH_H2*3;
  fish2_addr[4] = FISH_W*FISH_H2*4;
  fish2_addr[5] = FISH_W*FISH_H2*5;
  fish2_addr[6] = FISH_W*FISH_H2*6;
  fish2_addr[7] = FISH_W*FISH_H2*7;

  fish3_addr[0] = 0;
  fish3_addr[1] = FISH_W*FISH_H2;
  fish3_addr[2] = FISH_W*FISH_H2*2;
  fish3_addr[3] = FISH_W*FISH_H2*3;
  fish3_addr[4] = FISH_W*FISH_H2*4;
  fish3_addr[5] = FISH_W*FISH_H2*5;
  fish3_addr[6] = FISH_W*FISH_H2*6;
  fish3_addr[7] = FISH_W*FISH_H2*7;

end
reg [1:0] speed [0:1];
// Instiantiate the VGA sync signal generator
vga_sync vs0(
  .clk(vga_clk), .reset(~reset_n), .oHS(VGA_HSYNC), .oVS(VGA_VSYNC),
  .visible(video_on), .p_tick(pixel_tick),
  .pixel_x(pixel_x), .pixel_y(pixel_y)
);

clk_divider#(2) clk_divider0(
  .clk(clk),
  .reset(~reset_n),
  .clk_out(vga_clk)
);

// ------------------------------------------------------------------------
// The following code describes an initialized SRAM memory block that
// stores a 320x240 12-bit seabed image, plus two 64x32 fish images.
sram #(.DATA_WIDTH(12), .ADDR_WIDTH(18), .RAM_SIZE(VBUF_W*VBUF_H + FISH_W*FISH_H1*8 + 1), .FILE("images.mem"))
  ramA (.clk(clk), .en(sram_en), .we1(sram_we), .we2(sram_we),
          .addr1(sram_addr), .data_i1(data_in), .data_o1(data_out),
          .addr2(sram_addr_fh1), .data_i2(data_in), .data_o2(data_out_fh1));

sram #(.DATA_WIDTH(12), .ADDR_WIDTH(18), .RAM_SIZE(FISH_W*FISH_H2*8+1), .FILE("images2.mem"))
  ramB (.clk(clk), .en(sram_en), .we1(sram_we), .we2(sram_we),
          .addr1(sram_addr_fh2), .data_i1(data_in), .data_o1(data_out_fh2),
          .addr2(sram_addr_fh3), .data_i2(data_in), .data_o2(data_out_fh3));

assign sram_we = usr_btn[3]; // In this demo, we do not write the SRAM. However, if
                             // you set 'sram_we' to 0, Vivado fails to synthesize
                             // ram0 as a BRAM -- this is a bug in Vivado.
assign sram_en = 1;          // Here, we always enable the SRAM block.
assign sram_addr = pixel_addr;
assign sram_addr_fh1 = pixel_addr_fh1;
assign sram_addr_fh2 = pixel_addr_fh2;
assign sram_addr_fh3 = pixel_addr_fh3;

//assign sram_addr_fh5 = pixel_addr_fh5;
assign data_in = 12'h000; // SRAM is read-only so we tie inputs to zeros.
// End of the SRAM memory block.
// ------------------------------------------------------------------------

// VGA color pixel generator
assign {VGA_RED, VGA_GREEN, VGA_BLUE} = rgb_reg;

// ------------------------------------------------------------------------
// An animation clock for the motion of the fish, upper bits of the
// fish clock is the x position of the fish on the VGA screen.
// Note that the fish will move one screen pixel every 2^20 clock cycles,
// or 10.49 msec
assign pos = fish_clock[31:20]; // the x position of the right edge of the fish image
                                // in the 640x480 VGA screen
assign pos2 = fish_clock_2[31:20];
assign pos3 = fish_clock_3[31:20];
assign pos1c =fish_clock_1c[31:20];
assign pos3c =fish_clock_3c[31:20];
assign pos2c = fish_clock_2c[31:20];

always @(posedge clk) begin
  if (~reset_n || fish_clock[31:21] > VBUF_W + FISH_W)
    fish_clock <= 0;
  else if(speed[0]==1) fish_clock <= fish_clock + 1;
  else fish_clock <= fish_clock;
  
  if(~reset_n) fish_clock_1c <= 0;
  else if(speed[1]==1) begin
    if (fish_clock_1c[31:21] > VBUF_W + FISH_W) fish_clock_1c <= 0;
    else fish_clock_1c <= fish_clock_1c + 1;
  end
  else if(speed[1]==2) begin
      if(fish_clock_1c == 0) fish_clock_1c[31:21] <= VBUF_W + FISH_W;
      else fish_clock_1c <= fish_clock_1c - 1;
  end
  else fish_clock_1c <= fish_clock_1c;
  
  if (~reset_n)
    fish_clock_2 <= 168100200;
  else if(fish_clock_2[31:21] > VBUF_W + FISH_W)
    fish_clock_2 <= 0;
  else fish_clock_2 <= fish_clock_2 + 1;

  if (~reset_n)
    fish_clock_2c <= 168100200+167772160;
  else if(fish_clock_2c[31:21] > VBUF_W + FISH_W)
    fish_clock_2c <= 0;
  else fish_clock_2c <= fish_clock_2c + 1;


  if (~reset_n) fish_clock_3 <= 0;
  else if(fish_clock_3 == 0) fish_clock_3[31:21] <= VBUF_W + FISH_W;
  else fish_clock_3 <= fish_clock_3 - 1;

  if (~reset_n) fish_clock_3c <= 84100200;
  else if(fish_clock_3c == 0) fish_clock_3c[31:21] <= VBUF_W + FISH_W;
  else fish_clock_3c <= fish_clock_3c - 1;

end

// End of the animation clock code.
// ------------------------------------------------------------------------

// ------------------------------------------------------------------------
// Video frame buffer address generation unit (AGU) with scaling control
// Note that the width x height of the fish image is 64x32, when scaled-up
// on the screen, it becomes 128x64. 'pos' specifies the right edge of the
// fish image.
assign fish_region =
           pixel_y >= (FISH_VPOS<<1) && pixel_y < (FISH_VPOS+FISH_H1)<<1 &&
           (pixel_x + 127) >= pos && pixel_x < pos + 1;
           
assign fish_region_1c =
           pixel_y >= (FISH1c_VPOS<<1) && pixel_y < (FISH1c_VPOS+FISH_H1)<<1 &&
           (pixel_x + 127) >= pos1c && pixel_x < pos1c + 1;

assign fish_region_2 =
           (pixel_y) < (FISH2_V<<1) && (pixel_y + (FISH_H2<<1)) >= (FISH2_V<<1) &&
           (pixel_x + 127) >= pos2 && pixel_x < pos2 + 1;

assign fish_region_3 =
            pixel_y >= (FISH3_VPOS<<1) && pixel_y < (FISH3_VPOS+FISH_H3)<<1 &&
            (pixel_x + 127) >= pos3 && pixel_x < pos3 + 1;
            
assign fish_region_3c =
            pixel_y >= (FISH3c_VPOS<<1) && pixel_y < (FISH3c_VPOS+FISH_H3)<<1 &&
            (pixel_x + 127) >= pos3c && pixel_x < pos3c + 1;
            
assign fish_region_2c =    
            pixel_y >= (FISH2c_VPOS<<1) && pixel_y < (FISH2c_VPOS+FISH_H2)<<1 &&
           (pixel_x + 127) >= pos2c && pixel_x < pos2c + 1;
           
reg [3:0] now_pic;
reg p_fish_clock_23;
always @ (posedge clk) begin
  if(~reset_n) p_fish_clock_23 <= 0;
  else p_fish_clock_23 <= fish_clock_2[23];
end

always @ (posedge clk) begin
  if(~reset_n) begin
    now_pic <= 0;
    FISH2_V <= 100;
  end
  else if(fish_clock_2[23] != p_fish_clock_23) begin
    if(FISH2_V == 0) FISH2_V <= VBUF_H+FISH_H2;
    else FISH2_V <= FISH2_V - 1;

    if(now_pic==4'd7) now_pic <= 0;
    else now_pic <= now_pic + 1;
  end
end

always @(posedge clk) begin
  if (~reset_n||btn[0]) begin
    speed[0] <= 0;
    speed[1] <= 0;//0 reset(stop)
  end
  else if(btn[1]) begin
    case(speed[0])
      2'd0: speed[0] <= 1;
      2'd1: speed[0] <= 0;
      default:speed[0]<=0;
    endcase
  end
  else if(btn[2]) begin
    case(speed[1])
      2'd0: speed[1] <= 1;
      2'd1: speed[1] <= 2;
      2'd2: speed[1] <= 1;
    default:speed[1] <= 2;
    endcase
  end
  else begin
    speed[0] <= speed[0];
    speed[1] <= speed[1];
  end
end

always @ (posedge clk) begin
  if (~reset_n) begin
    pixel_addr <= 0;
    pixel_addr_fh1 <= 0;
    pixel_addr_fh2 <= 0;
    pixel_addr_fh3 <= 0;
  end 
  else begin
    if (fish_region)
      pixel_addr_fh1 <= fish_addr[now_pic] +
                    ((pixel_y>>1)-FISH_VPOS)*FISH_W +
                    ((pixel_x +(FISH_W*2-1)-pos)>>1);
    else if(fish_region_1c) begin
        if(speed[1] == 1) 
        pixel_addr_fh1 <= fish_addr[now_pic] +
                    ((pixel_y>>1)-FISH1c_VPOS)*FISH_W +
                    ((pixel_x +(FISH_W*2-1)-pos1c)>>1);
        else if(speed[1] == 2)
        pixel_addr_fh1 <= fish_addr[now_pic] +
                    ((pixel_y>>1)-FISH1c_VPOS+1)*FISH_W -
                    ((pixel_x +(FISH_W*2-1)-pos1c)>>1);
        else pixel_addr_fh1 <= fish_addr[0];
    end
    else pixel_addr_fh1 <= fish_addr[0];//must be green

    if (fish_region_2)
      pixel_addr_fh2 <= fish2_addr[now_pic] +
                    ((pixel_y>>1) + FISH_H2 - FISH2_V)*FISH_W +
                    ((pixel_x +(FISH_W*2-1)-pos2)>>1);
    else if(fish_region_2c)
      pixel_addr_fh2 <= fish2_addr[now_pic] +
                    ((pixel_y>>1) - FISH2c_VPOS)*FISH_W +
                    ((pixel_x +(FISH_W*2-1)-pos2c)>>1);
    else pixel_addr_fh2 <= fish2_addr[0];//must be green

    if (fish_region_3)
      pixel_addr_fh3 <= fish3_addr[now_pic] +
                    ((pixel_y>>1)-FISH3_VPOS+1)*FISH_W -
                    ((pixel_x +(FISH_W*2-1)-pos3)>>1);
    else if(fish_region_3c)
      pixel_addr_fh3 <= fish3_addr[now_pic] +
                    ((pixel_y>>1)-FISH3c_VPOS+1)*FISH_W -
                    ((pixel_x +(FISH_W*2-1)-pos3c)>>1);
    else pixel_addr_fh3 <= fish3_addr[0];

    pixel_addr <= (pixel_y >> 1) * VBUF_W + (pixel_x >> 1);
  end
end
// End of the AGU code.
// ------------------------------------------------------------------------

// ------------------------------------------------------------------------
// Send the video data in the sram to the VGA controller
always @(posedge clk) begin
  if (pixel_tick) rgb_reg <= rgb_next;
end

always @(*) begin
  if (~video_on)
    rgb_next = 12'h000; // Synchronization period, must set RGB values to zero.
  else if (data_out_fh1 != 12'h0F0)
    rgb_next <= data_out_fh1;//fish1 and not green
  else if (data_out_fh2 != 12'h0F0)
    rgb_next <= data_out_fh2;//fish2 and not green
  else if (data_out_fh3 != 12'h0F0)
    rgb_next <= data_out_fh3;//fish3 and not green
  else
    rgb_next <= data_out;
end
// End of the video data display code.
// ------------------------------------------------------------------------

endmodule
