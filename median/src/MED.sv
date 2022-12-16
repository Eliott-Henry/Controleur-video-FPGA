module MED #(parameter WIDTH=8, parameter NUMBER=9)
        (input [WIDTH-1:0] DI,
        input DSI,
        input BYP, 
        input CLK,
        output [WIDTH-1:0] DO);

logic[WIDTH-1:0] R[0:NUMBER-1];
logic[WIDTH-1:0] MIN, MAX;

MCE #(.WIDTH(WIDTH)) MCE1 (.A(R[NUMBER-1]), .B(R[NUMBER-2]), .MIN(MIN), .MAX(MAX));
assign DO = R[NUMBER-1];

always_ff @(posedge CLK)
begin 
    
    if(BYP)
        R[NUMBER-1] <= R[NUMBER-2];
    else
        R[NUMBER-1] <= MAX;

    // les registres à décalage de R1 à R7
    for(int i = 0; i<NUMBER-2; i++)
    begin
        R[i+1] <= R[i];
    end

    if(DSI)
        R[0] <= DI;
    else
        R[0] <= MIN;      

end

endmodule
