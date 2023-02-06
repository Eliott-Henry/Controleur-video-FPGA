module mire #(parameter HDISP = 800, VDISP = 480)(
    wshb_if.master wshb_ifm
);

// Module chargé d'érire en continu une mire dans la sdram via un bus wishbone

localparam width_count_lines = $clog2(VDISP);
localparam width_count_pix = $clog2(HDISP);

// Compteur sur les lignes et pixels
logic[width_count_pix-1:0] x_pix;
logic[width_count_lines-1:0] y_pix;
logic[5:0] count_cycles; // Compteur de cycles saturé à 64 : sert à mettre périodiquement des signaux à 0

// Compteur de cycles
always@(posedge wshb_ifm.clk or posedge wshb_ifm.rst)
begin 
    if(wshb_ifm.rst) count_cycles <= 0;
    else if(count_cycles == 63) begin
        if(wshb_ifm.ack) count_cycles <= count_cycles + 1;end
    else 
        count_cycles <= count_cycles + 1;
end

// Compteur de pixels de 0 à HDISP-1
always@(posedge wshb_ifm.clk or posedge wshb_ifm.rst)
begin 
    if(wshb_ifm.rst) x_pix <=0;
    else if(wshb_ifm.ack) begin
        if(x_pix == HDISP-1) x_pix<=0;
        else x_pix <= x_pix + 1;
    end
end

// Compteur de lignes de 0 à VDISP-1
always@(posedge wshb_ifm.clk or posedge wshb_ifm.rst)
begin
    if(wshb_ifm.rst) y_pix <= 0;
    else if(wshb_ifm.ack) begin
        if(x_pix == HDISP-1) begin 
            y_pix <= y_pix+1; 
            if(y_pix == VDISP-1) y_pix <= 0;
        end
    end
end

// Gestion asynchrone de dat_ms
always_comb
begin 
    if((x_pix[3:0] == 0) | (y_pix[3:0] == 0)) begin
        wshb_ifm.dat_ms[7:0] = 255;
        wshb_ifm.dat_ms[15:8] = 255;
        wshb_ifm.dat_ms[23:16] = 255; end
    else begin
        wshb_ifm.dat_ms[7:0] = 0;
        wshb_ifm.dat_ms[15:8] = 0;
        wshb_ifm.dat_ms[23:16] = 0;
    end
end

assign wshb_ifm.adr = 4*(x_pix + y_pix*HDISP);

// Signaux à 0 tous les 64 cycles
assign wshb_ifm.cyc = ~(count_cycles == 0); 
assign wshb_ifm.stb = ~(count_cycles == 0);

// Neutralisation de l'écriture en RAM pour test
//assign wshb_ifm.stb = 0;
//assign wshb_ifm.cyc = 0;

assign wshb_ifm.we = 1;
assign wshb_ifm.sel = 4'b1111;

endmodule