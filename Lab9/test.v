`timescale 1ns / 1ps

module md5(
    input reset_n,
    input clk,
    input in,
    input [0:63] txt,
    output valid,
    output [0:127] hash);

    localparam [0:31] h0 = 32'h67452301, h1 = 32'hefcdab89, h2 = 32'h98badcfe, h3 = 32'h10325476;

    reg [0:127] hash_n;
    reg [0:63] guess_n;
    reg [0:31] a=h0;
    reg [0:31] b=h1;
    reg [0:31] c=h2;
    reg [0:31] d=h3;
    reg p_valid;
    reg [0:511] message;
    reg [0:4] r;
    reg [0:31] k;
    reg [3:0] counter;
    reg [0:3] g; 
    reg [2:0] round;
    wire [0:31] tmp1;
    assign tmp1 = (a+ ((b&c)|((~b)&d) )+ k + message[g*32 +: 32]);
    wire [0:31] tmp2;
    assign tmp2 = (a+ ((d&b)|((~d)&c) )+ k + message[(32*g) +: 32]);
    wire [0:31] tmp3;
    assign tmp3 = (a+ ((b^c^d))+ k + message[(32*g) +: 32]);
    wire [0:31] tmp4;
    assign tmp4 = (a+ (c^(b|(~d)) )+ k + message[(32*g) +: 32]);
    reg [0:31] H0=h0;
    reg [0:31] H1=h1;
    reg [0:31] H2=h2;
    reg [0:31] H3=h3;
    assign valid = (round==4);
    always@(posedge clk) begin
        if(~reset_n) message <= 0;
        else if(in)begin
            message <= {txt[24+:8], txt[16+:8], txt[8+:8], txt[0+:8], txt[56+:8], txt[48+:8], txt[40+:8], txt[32+:8],32'd128,352'b0,24'd0,8'd64,32'd0};
            //note!!! little-endian (per 32bits since chunk = 32bits)
        end
    end

    always@(posedge clk)begin
        if(~reset_n || in==1) begin
            a <= h0;
            b <= h1;
            c <= h2;
            d <= h3;
            counter <= 0;
            round <= 0;
        end
        else begin
            if(valid==0) begin
                case(round)
                    2'd0: b <= b + ((tmp1<<r) | (tmp1>>(32-r)));
                    2'd1: b <= b + ((tmp2<<r) | (tmp2>>(32-r)));
                    2'd2: b <= b + ((tmp3<<r) | (tmp3>>(32-r)));
                    2'd3: b <= b + ((tmp4<<r) | (tmp4>>(32-r)));
                    default:;
                endcase
                a <= d;
                d <= c;
                c <= b;
                if(counter==4'd15) begin
                    counter <= 0;
                    round <= round+1;
                end
                else counter <= counter + 1;
            end
        end
    end

    always@(posedge clk) begin
        if(~reset_n || in==1) begin
            H0 <= h0;
            H1 <= h1;
            H2 <= h2;
            H3 <= h3;
        end
        if(valid==1&&p_valid==0) begin
            H0 <= H0 + a;
            H1 <= H1 + b;
            H2 <= H2 + c;
            H3 <= H3 + d;
        end
        p_valid <= valid;
    end

    //note!!! little-endian (per 32bits)
    assign hash = {H0[24:31],H0[16:23],H0[8:15],H0[0:7],
    H1[24:31],H1[16:23],H1[8:15],H1[0:7],
    H2[24:31],H2[16:23],H2[8:15],H2[0:7],
    H3[24:31],H3[16:23],H3[8:15],H3[0:7]};

    //control r
    always@(*) begin
        case(round) 
            3'd0: begin
                case(counter)
                    4'd0: r <= 5'd7;
                    4'd1: r <= 5'd12;
                    4'd2: r <= 5'd17;
                    4'd3: r <= 5'd22;
                    4'd4: r <= 5'd7;
                    4'd5: r <= 5'd12;
                    4'd6: r <= 5'd17;
                    4'd7: r <= 5'd22;
                    4'd8: r <= 5'd7;
                    4'd9: r <= 5'd12;
                    4'd10: r <= 5'd17;
                    4'd11: r <= 5'd22;
                    4'd12: r <= 5'd7;
                    4'd13: r <= 5'd12;
                    4'd14: r <= 5'd17;
                    4'd15: r <= 5'd22;
                    default:;
                endcase
            end
            3'd1: begin
                case(counter)
                    4'd0: r <= 5'd5;
                    4'd1: r <= 5'd9;
                    4'd2: r <= 5'd14;
                    4'd3: r <= 5'd20;
                    4'd4: r <= 5'd5;
                    4'd5: r <= 5'd9;
                    4'd6: r <= 5'd14;
                    4'd7: r <= 5'd20;
                    4'd8: r <= 5'd5;
                    4'd9: r <= 5'd9;
                    4'd10: r <= 5'd14;
                    4'd11: r <= 5'd20;
                    4'd12: r <= 5'd5;
                    4'd13: r <= 5'd9;
                    4'd14: r <= 5'd14;
                    4'd15: r <= 5'd20;
                    default:;
                endcase
            end
            3'd2: begin
                case(counter)
                    4'd0: r <= 5'd4;
                    4'd1: r <= 5'd11;
                    4'd2: r <= 5'd16;
                    4'd3: r <= 5'd23;
                    4'd4: r <= 5'd4;
                    4'd5: r <= 5'd11;
                    4'd6: r <= 5'd16;
                    4'd7: r <= 5'd23;
                    4'd8: r <= 5'd4;
                    4'd9: r <= 5'd11;
                    4'd10: r <= 5'd16;
                    4'd11: r <= 5'd23;
                    4'd12: r <= 5'd4;
                    4'd13: r <= 5'd11;
                    4'd14: r <= 5'd16;
                    4'd15: r <= 5'd23;
                    default:;
                endcase
            end
            3'd3: begin
                case(counter)
                    4'd0: r <= 5'd6;
                    4'd1: r <= 5'd10;
                    4'd2: r <= 5'd15;
                    4'd3: r <= 5'd21;
                    4'd4: r <= 5'd6;
                    4'd5: r <= 5'd10;
                    4'd6: r <= 5'd15;
                    4'd7: r <= 5'd21;
                    4'd8: r <= 5'd6;
                    4'd9: r <= 5'd10;
                    4'd10: r <= 5'd15;
                    4'd11: r <= 5'd21;
                    4'd12: r <= 5'd6;
                    4'd13: r <= 5'd10;
                    4'd14: r <= 5'd15;
                    4'd15: r <= 5'd21;
                    default:;
                endcase
            end
            default:;
        endcase
    end
    //control k
    always@(*) begin
        case(round) 
            3'd0: begin
                case(counter)
                    4'd0: k <= 32'hd76aa478;
                    4'd1: k <= 32'he8c7b756;
                    4'd2: k <= 32'h242070db;
                    4'd3: k <= 32'hc1bdceee;
                    4'd4: k <= 32'hf57c0faf;
                    4'd5: k <= 32'h4787c62a;
                    4'd6: k <= 32'ha8304613;
                    4'd7: k <= 32'hfd469501;
                    4'd8: k <= 32'h698098d8;
                    4'd9: k <= 32'h8b44f7af;
                    4'd10: k <= 32'hffff5bb1;
                    4'd11: k <= 32'h895cd7be;
                    4'd12: k <= 32'h6b901122;
                    4'd13: k <= 32'hfd987193;
                    4'd14: k <= 32'ha679438e;
                    4'd15: k <= 32'h49b40821;
                    default;
                endcase
            end
            3'd1: begin
                case(counter)
                    4'd0: k <= 32'hf61e2562;
                    4'd1: k <= 32'hc040b340;
                    4'd2: k <= 32'h265e5a51;
                    4'd3: k <= 32'he9b6c7aa;
                    4'd4: k <= 32'hd62f105d;
                    4'd5: k <= 32'h02441453;
                    4'd6: k <= 32'hd8a1e681;
                    4'd7: k <= 32'he7d3fbc8;
                    4'd8: k <= 32'h21e1cde6;
                    4'd9: k <= 32'hc33707d6;
                    4'd10: k <= 32'hf4d50d87;
                    4'd11: k <= 32'h455a14ed;
                    4'd12: k <= 32'ha9e3e905;
                    4'd13: k <= 32'hfcefa3f8;
                    4'd14: k <= 32'h676f02d9;
                    4'd15: k <= 32'h8d2a4c8a;
                    default;
                endcase
            end
            3'd2: begin
                case(counter)
                    4'd0: k <= 32'hfffa3942;
                    4'd1: k <= 32'h8771f681;
                    4'd2: k <= 32'h6d9d6122;
                    4'd3: k <= 32'hfde5380c;
                    4'd4: k <= 32'ha4beea44;
                    4'd5: k <= 32'h4bdecfa9;
                    4'd6: k <= 32'hf6bb4b60;
                    4'd7: k <= 32'hbebfbc70;
                    4'd8: k <= 32'h289b7ec6;
                    4'd9: k <= 32'heaa127fa;
                    4'd10: k <= 32'hd4ef3085;
                    4'd11: k <= 32'h04881d05;
                    4'd12: k <= 32'hd9d4d039;
                    4'd13: k <= 32'he6db99e5;
                    4'd14: k <= 32'h1fa27cf8;
                    4'd15: k <= 32'hc4ac5665;
                    default;
                endcase
            end
            3'd3: begin
                case(counter)
                    4'd0: k <= 32'hf4292244;
                    4'd1: k <= 32'h432aff97;
                    4'd2: k <= 32'hab9423a7;
                    4'd3: k <= 32'hfc93a039;
                    4'd4: k <= 32'h655b59c3;
                    4'd5: k <= 32'h8f0ccc92;
                    4'd6: k <= 32'hffeff47d;
                    4'd7: k <= 32'h85845dd1;
                    4'd8: k <= 32'h6fa87e4f;
                    4'd9: k <= 32'hfe2ce6e0;
                    4'd10: k <= 32'ha3014314;
                    4'd11: k <= 32'h4e0811a1;
                    4'd12: k <= 32'hf7537e82;
                    4'd13: k <= 32'hbd3af235;
                    4'd14: k <= 32'h2ad7d2bb;
                    4'd15: k <= 32'heb86d391;
                    default;
                endcase
            end
            default:;
        endcase
    end
    //control g
    always@(*) begin
        case(round) 
            3'd0: begin
                case(counter)
                    4'd0: g <= 4'd0;
                    4'd1: g <= 4'd1;
                    4'd2: g <= 4'd2;
                    4'd3: g <= 4'd3;
                    4'd4: g <= 4'd4;
                    4'd5: g <= 4'd5;
                    4'd6: g <= 4'd6;
                    4'd7: g <= 4'd7;
                    4'd8: g <= 4'd8;
                    4'd9: g <= 4'd9;
                    4'd10: g <= 4'd10;
                    4'd11: g <= 4'd11;
                    4'd12: g <= 4'd12;
                    4'd13: g <= 4'd13;
                    4'd14: g <= 4'd14;
                    4'd15: g <= 4'd15;
                    default;
                endcase
            end
            3'd1: begin
                case(counter)
                    4'd0: g <= 4'd1;
                    4'd1: g <= 4'd6;
                    4'd2: g <= 4'd11;
                    4'd3: g <= 4'd0;
                    4'd4: g <= 4'd5;
                    4'd5: g <= 4'd10;
                    4'd6: g <= 4'd15;
                    4'd7: g <= 4'd4;
                    4'd8: g <= 4'd9;
                    4'd9: g <= 4'd14;
                    4'd10: g <= 4'd3;
                    4'd11: g <= 4'd8;
                    4'd12: g <= 4'd13;
                    4'd13: g <= 4'd2;
                    4'd14: g <= 4'd7;
                    4'd15: g <= 4'd12;
                    default;
                endcase
            end
            3'd2: begin
                case(counter)
                    4'd0: g <= 4'd5;
                    4'd1: g <= 4'd8;
                    4'd2: g <= 4'd11;
                    4'd3: g <= 4'd14;
                    4'd4: g <= 4'd1;
                    4'd5: g <= 4'd4;
                    4'd6: g <= 4'd7;
                    4'd7: g <= 4'd10;
                    4'd8: g <= 4'd13;
                    4'd9: g <= 4'd0;
                    4'd10: g <= 4'd3;
                    4'd11: g <= 4'd6;
                    4'd12: g <= 4'd9;
                    4'd13: g <= 4'd12;
                    4'd14: g <= 4'd15;
                    4'd15: g <= 4'd2;
                    default;
                endcase
            end
            3'd3: begin
                case(counter)
                    4'd0: g <= 4'd0;
                    4'd1: g <= 4'd7;
                    4'd2: g <= 4'd14;
                    4'd3: g <= 4'd5;
                    4'd4: g <= 4'd12;
                    4'd5: g <= 4'd3;
                    4'd6: g <= 4'd10;
                    4'd7: g <= 4'd1;
                    4'd8: g <= 4'd8;
                    4'd9: g <= 4'd15;
                    4'd10: g <= 4'd6;
                    4'd11: g <= 4'd13;
                    4'd12: g <= 4'd4;
                    4'd13: g <= 4'd11;
                    4'd14: g <= 4'd2;
                    4'd15: g <= 4'd9;
                    default;
                endcase
            end
            default:;
        endcase
    end
endmodule