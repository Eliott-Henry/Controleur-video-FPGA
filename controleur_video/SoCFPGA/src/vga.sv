localparam HFP = 40; //Horizontal Front Porch40	40	pixels
localparam HPULSE = 48; //	Largeur de la synchro ligne	48	pixels
localparam HBP = 40; //	Horizontal Back Porch	40	pixels

localparam VFP = 13; // Vertical Front Porch	13	lignes
localparam VPULSE = 3; // Largeur de la sync image 3 lignes
localparam VBP = 29; // Vertical Back Porch	29	lignes

module vga #(parameter HDISP = 800, VDISP = 480)
(   input wire pixel_clk,
    input wire pixel_rst,
    video_if.master video_ifm,
    wshb_if.master wshb_ifm);

assign wshb_ifm.dat_ms = 32'hBABECAFE; //	Donnée 32 bits émises
assign wshb_ifm.adr	= '0; //	Adresse d'écriture
assign wshb_ifm.cyc	= 1'b1; //	Le bus est sélectionné
assign wshb_ifm.sel	= 4'b1111; //	Les 4 octets sont à écrire
assign wshb_ifm.stb	= 1'b1; //	Nous demandons une transaction
assign wshb_ifm.we	=1'b1; //   Transaction en écriture
assign wshb_ifm.cti	='0;//Transfert classique
assign wshb_ifm.bte	= '0;	//sans utilité

localparam number_lines = VFP + VPULSE + VBP + VDISP;
localparam width_count_lines = $clog2(number_lines);

localparam number_pix = HFP + HPULSE + HBP + HDISP;
localparam width_count_pix = $clog2(number_pix);

// Compteur sur les lignes et pixels
logic[width_count_pix-1:0] count_pix;
logic[width_count_lines-1:0] count_lines;

// Coordonnées des pixels actifs
logic[width_count_pix-1:0] x_pix;
logic[width_count_lines-1:0] y_pix;

assign video_ifm.CLK = pixel_clk;

// Compteur de pixel
always@(posedge pixel_clk or posedge pixel_rst)
begin 
    if(pixel_rst) count_pix <=0;
    else begin
        if(count_pix == number_pix-1) count_pix<=0;
        else count_pix <= count_pix + 1;
    end
end

// Compteur de lignes
always@(posedge pixel_clk or posedge pixel_rst)
begin
    if(pixel_rst) count_lines <= 0;
    else begin
        if(count_pix == number_pix-1) begin 
            count_lines <= count_lines+1; 
            if(count_lines == number_lines-1) count_lines <= 0;
        end
    end
end

// Gestion du signal HS
always@(posedge pixel_clk or posedge pixel_rst)
begin 
    if(pixel_rst) video_ifm.HS <= 1;
    else video_ifm.HS <= (count_pix < HFP) || (count_pix >= HPULSE + HFP);
end

// Gestion du signal VS 
always@(posedge pixel_clk or posedge pixel_rst)
begin 
    if(pixel_rst) video_ifm.VS <= 1;
    else video_ifm.VS <= (count_lines < VFP) || (count_lines >= VPULSE + VFP);
end

// Gestion du signal BLANK
always@(posedge pixel_clk or posedge pixel_rst)
begin 
    if(pixel_rst) video_ifm.BLANK <= 0;
    else video_ifm.BLANK <= (count_lines >= VBP + VFP + VPULSE) && (count_pix >= HBP + HPULSE + HFP);
end

// Coordonnées des pixels actifs
always_comb begin
x_pix = count_pix - (HFP + HPULSE + HBP);
y_pix = count_lines - (VFP + VPULSE + VBP);
end

// Gestion de la couleur des pixels
always@(posedge pixel_clk) begin
    if((x_pix[3:0] == 0) | (y_pix[3:0] == 0)) begin
        video_ifm.RGB[7:0] <= 255;
        video_ifm.RGB[15:8] <= 255;
        video_ifm.RGB[23:16] <= 255;
    end
    else begin
        video_ifm.RGB[7:0] <= 0;
        video_ifm.RGB[15:8] <= 0;
        video_ifm.RGB[23:16] <= 0;
    end
end

endmodule