module test();
    reg clk;
    reg [127:0] s1;
    initial begin
        clk<=0;
        forever #5 clk<=~clk;
    end
    reg [7:0] counter = 48;
    always@(posedge clk) begin
        s1[7:0] = counter;
        s1 = s1<<8;
        counter = counter + 1;
    end
endmodule
