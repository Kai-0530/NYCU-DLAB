module SeqMultiplier_tb();
    reg clk;
    reg enable;
    reg [7:0] A;
    reg [7:0] B;
    wire [15:0] C;
    
    SeqMultiplier seqmultiplier(.clk(clk), .enable(enable), .A(A), .B(B), .C(C));
    
    initial begin
        clk=1;
        enable=0;
        A=8'b00000000;
        B=8'b00000000;
        #20;
        A=8'b11101111;
        B=8'b10100011;
        #20;
        enable=1;
    end
    
    always #5 clk = ~clk;
endmodule