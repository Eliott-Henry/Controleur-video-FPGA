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

logic[31:0] wshb_count;


// ----------- SIGNAUX INTERNES FIFO ----------

logic fifo_rst; // à définir

wire  fifo_rclk; // plus tard
wire  fifo_read; // plus tard
logic [31:0] fifo_rdata; // plus tard
logic fifo_rempty; // plus tard

wire  fifo_wclk; // à définir
wire  [31:0] fifo_wdata; // à définir 
logic fifo_write; // à définir
logic fifo_wfull; // output
logic fifo_walmost_full; // output


logic fifo_has_been_full_wshb;
logic fifo_has_been_full_pix;

// ----------------------------------------------

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

assign video_ifm.RGB = fifo_rdata;


// ------------ Gestion des différentes domaines d'horloge ------------- //

logic Q_pix;

// Echantillonage de fifo_has_been_full_wshb dans le domaine pixel_clk
always@(posedge pixel_clk or posedge pixel_rst) begin 
    if(pixel_rst) Q_pix <= 0;
    else Q_pix <= fifo_has_been_full_wshb;
end

// Gestion de fifo_has_been_full_pix
always@(posedge pixel_clk or posedge pixel_rst) begin 
    if(pixel_rst) fifo_has_been_full_pix <= 0;
    else fifo_has_been_full_pix <= Q_pix;
end

// ------------ Lecture Wishbone ----------- //

// Dans cette partie, le bus Wishbone lit des données en SDRAM //

// Gestion de cyc    
always@(posedge pixel_clk or posedge pixel_rst)
begin
    if(pixel_rst) wshb_ifm.cyc <= 1;
    else begin
        if(~fifo_walmost_full) wshb_ifm.cyc <= 1;
        if(fifo_wfull) wshb_ifm.cyc <= 0;
    end
end

// Le bus est sélectionné
// Idée de possibiltés pour régler : 
// Augmenter la taille de la fenêtre de walmostfull
// regarder les signaux fifo_wfull (synchrone, asynchrone etc) : et ce qu'il a du retard ,
assign wshb_ifm.we	= 1'b0; // Transaction en lecture à chaque fois
assign wshb_ifm.stb	= wshb_ifm.cyc & ~fifo_wfull; //	Nous demandons une transaction lorsque la FIFO n'est pleine

assign wshb_ifm.sel	= 4'b1111; // Les 4 octets sont à écrire
assign wshb_ifm.cti	='0; // Transfert classique
assign wshb_ifm.bte	= '0;	// Sans utilité
assign wshb_ifm.dat_ms = 32'hBABECAFE; // Inutile ici :	Donnée 32 bits émises

// Gestion de adr : init à 0 et incrémenté si on a bien lu le précédent

always_ff@(posedge wshb_ifm.clk or posedge wshb_ifm.rst)
begin
    if(wshb_ifm.rst) wshb_count <= 0;
    else begin
        if(wshb_ifm.ack) begin
            if(wshb_count == HDISP * VDISP - 1) wshb_count <= 0;
            else wshb_count <= wshb_count + 1; end
    end
end

// Adresse mémoire où l'on fait la lecture
assign wshb_ifm.adr = wshb_count * 4;

// ---------------- ASSIGNATION VALEURS SIGNAUX FIFO ---------- //

assign fifo_rst = wshb_ifm.rst;
assign fifo_wclk = wshb_ifm.clk;
assign fifo_wdata = wshb_ifm.dat_sm;
assign fifo_write = wshb_ifm.ack; // On écrit dans la fifo dès qu'on a une nouvelle valeur à présenter

assign fifo_rclk = pixel_clk;
assign fifo_read = video_ifm.BLANK & fifo_has_been_full_pix & ~fifo_rempty;


// Gestion du signal qui indique si la FIFO a déjà été remplie avant de lire les pixels
always@(posedge fifo_wclk or posedge fifo_rst)
begin
    if(fifo_rst) fifo_has_been_full_wshb <= 0;
    else if(fifo_wfull) fifo_has_been_full_wshb <= 1;
end

// -------------- INSTANCIATION DE LA FIFO ------------------- //

async_fifo #(.DATA_WIDTH(32), .DEPTH_WIDTH(8)) async_fifo_inst (
    .rst(fifo_rst),
    .rclk(fifo_rclk), 
    .read(fifo_read), 
    .rdata(fifo_rdata), 
    .rempty(fifo_rempty), 
    .wclk(fifo_wclk), 
    .wdata(fifo_wdata), 
    .write(fifo_write), 
    .wfull(fifo_wfull),
    .walmost_full(fifo_walmost_full)
);

endmodule