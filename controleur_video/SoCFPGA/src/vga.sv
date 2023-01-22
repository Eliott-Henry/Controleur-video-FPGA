localparam HFP = 40; //Horizontal Front Porch40	40	pixels
localparam HPULSE = 48; //	Largeur de la synchro ligne	48	pixels
localparam HBP = 40; //	Horizontal Back Porch	40	pixels

localparam VFP = 13; // Vertical Front Porch	13	lignes
localparam VPULSE = 3; // Largeur de la sync image 3 lignes
localparam VBP = 29; // Vertical Back Porch	29	lignes

module vga #(parameter HDISP = 800, VDISP = 480)
(   input wire pixel_clk,
    input wire pixel_rst,
    video_if.master video_ifm);

// ATTENTION IL FAUT MODIFIER ICI AVANT DE SIMULER ETC
// Ici il faudra adapter la taille du tableau aux dimensions de l'écran (HDIPS + HFP + HBP + HPULSE pour les pix et V pour les lines)
logic[9:0] count_pix;
logic[9:0] count_lines;
logic[8:0] x_pix;
logic[8:0] y_pix;

assign video_ifm.CLK = pixel_clk;

always@(posedge pixel_clk or posedge pixel_rst)
begin
    if(pixel_rst) begin
        count_lines <= 0;
        count_pix <= 0;
        video_ifm.HS <= 1;
        video_ifm.VS <= 1;
        video_ifm.BLANK <= 0;
    end
    else begin

        // Gestion des compteurs
        if(count_pix == HDISP + HBP + HPULSE + HFP) begin 
            count_pix<=0;
            count_lines <= count_lines+1; end
        else count_pix <= count_pix+1;
        
        if(count_lines == VDISP + VBP + VPULSE + VFP) count_lines <= 0;
    
         // Gestion des signaux maître
        if(count_lines < VFP | count_lines >= VPULSE + VFP) video_ifm.VS <= 1;
        else video_ifm.VS <= 0;

        if(count_pix < HFP | count_pix >= HPULSE + HFP) video_ifm.HS <= 1;
        else video_ifm.HS <= 0;

        if(count_lines >= VBP + VFP + VPULSE && count_pix >= HBP + HPULSE + HFP) video_ifm.BLANK <= 1;
        else video_ifm.BLANK <= 0;
    end
end
// Coordonnées des pixels actifs

always_comb begin
x_pix = count_pix - (HFP + HPULSE + HBP);
y_pix = count_lines - (VFP + VPULSE + VBP);
end

always@(posedge pixel_clk) begin

// Gestion des pixels actifs
if((x_pix % 2 == 0) | (y_pix % 2 == 0)) begin
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