module MCE #(parameter WIDTH=8)
        (input [WIDTH-1:0] A, B, 
        output [WIDTH-1:0] MIN, MAX);

assign MAX = A>= B ?  A : B;
assign MIN = A < B ? A : B;

endmodule