module mmult(
    input clk, // Clock signal.
    input reset_n, // Reset signal (negative logic).
    input enable, // Activation signal for matrix multiplication (tells the circuit  that A and B are ready for use).
    input [0:9*8-1] A_mat, // A matrix.
    input [0:9*8-1] B_mat, // B matrix.
    output valid, // Signals that the output is valid to read.
    output reg [0:9*17-1] C_mat // The result of A x B.
);
    reg [0:71] A,B;
    reg [3:0] counter;
    assign valid = ~|(counter^3);
    always @(posedge clk) begin
        if(!enable||!reset_n) begin
            A <= A_mat;
            B <= B_mat;
            C_mat <= 0;
            counter <= 0;
        end 
        else if(!valid) begin
            C_mat <= (C_mat<<51)
            | ((A[0:7]*B[0:7]+A[8:15]*B[24:31]+A[16:23]*B[48:55])<<34)
            |  ((A[0:7]*B[8:15]+A[8:15]*B[32:39]+A[16:23]*B[56:63])<<17)
            |  (A[0:7]*B[16:23]+A[8:15]*B[40:47]+A[16:23]*B[64:71]);
            A <= A<<24;
            counter <= counter + 1;
        end
    end
endmodule