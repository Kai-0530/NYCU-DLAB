module alu(
    output reg [7:0] alu_out,
    output wire zero,
    input wire [2:0] opcode,
    input wire [7:0] data,
    input wire [7:0] accum,
    input wire clk,
    input wire reset
);
    assign zero = (accum == 0) ? 1 : 0;
    always@(posedge clk) begin
        if(reset) begin
            alu_out <= 0;
        end
        else if(opcode[0] == 1'bx) begin
            alu_out <= 0;
        end
        else begin
            case(opcode)
                3'b000: alu_out <= accum;
                3'b001: alu_out <= accum + data;
                3'b010: alu_out <= accum - data;
                //10011010
                //01000110
                //10111010
                3'b011: alu_out <= accum & data;
                3'b100: alu_out <= accum ^ data;
                3'b101: alu_out <= (accum & {8{~accum[7]}}) | ((~accum+1) & {8{accum[7]}}); //pos |  neg 
                //-4
                //0000 0100
                //1111 1100
                //0000 0100
                //1111 1111
                //0000 0100
                3'b110: alu_out <= accum * data;
                3'b111: alu_out <= data; 
                default: alu_out <= 0;
            endcase
        end
    end
endmodule
