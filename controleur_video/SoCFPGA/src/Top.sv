`default_nettype none
`ifdef SIMULATION
  localparam hcmpt=100;
  localparam hcmpt_pix=32;
`else
  localparam hcmpt= 100000000;
  localparam hcmpt_pix = 32000000;
`endif

module Top#(parameter HDISP = 800, VDISP = 480)(
    // Les signaux externes de la partie FPGA
	input  wire         FPGA_CLK1_50,
	input  wire  [1:0]	KEY,
	output logic [7:0]	LED,
	input  wire	 [3:0]	SW,

    // Les signaux du support matériel sont regroupés dans une interface
    hws_if.master       hws_ifm,
    video_if.master video_ifm
);

//====================================
//  Déclarations des signaux internes
//====================================
  wire        sys_rst;   // Le signal de reset du système
  wire        sys_clk;   // L'horloge système a 100Mhz
  wire        pixel_clk; // L'horloge de la video 32 Mhz
  logic        pixel_rst;
  logic[26:0] count;
  logic[26:0] count_pix;
  logic Q;


//=======================================================
//  La PLL pour la génération des horloges == Phase-Locked Loop
//=======================================================

sys_pll  sys_pll_inst(
		   .refclk(FPGA_CLK1_50),   // refclk.clk
		   .rst(1'b0),              // pas de reset
		   .outclk_0(pixel_clk),    // horloge pixels a 32 Mhz
		   .outclk_1(sys_clk)       // horloge systeme a 100MHz
);


//=============================
//  Les bus Wishbone internes
//=============================
wshb_if #( .DATA_BYTES(4)) wshb_if_sdram  (sys_clk, sys_rst);
wshb_if #( .DATA_BYTES(4)) wshb_if_stream (sys_clk, sys_rst);

//=============================
//  Le support matériel
//=============================
hw_support hw_support_inst (
    .wshb_ifs (wshb_if_sdram),
    .wshb_ifm (wshb_if_stream),
    .hws_ifm  (hws_ifm),
	.sys_rst  (sys_rst), // output
    .SW_0     ( SW[0] ),
    .KEY      ( KEY )
 );

//=============================
// On neutralise l'interface
// du flux video pour l'instant
// A SUPPRIMER PLUS TARD
//=============================

assign wshb_if_stream.ack = 1'b1;
assign wshb_if_stream.dat_sm = '0 ;
assign wshb_if_stream.err =  1'b0 ;
assign wshb_if_stream.rty =  1'b0 ;

//=============================
// On neutralise l'interface SDRAM
// pour l'instant
// A SUPPRIMER PLUS TARD
//=============================

assign wshb_if_sdram.stb  = 1'b0;
assign wshb_if_sdram.cyc  = 1'b0;
assign wshb_if_sdram.we   = 1'b0;
assign wshb_if_sdram.adr  = '0  ;
assign wshb_if_sdram.dat_ms = '0 ;
assign wshb_if_sdram.sel = '0 ;
assign wshb_if_sdram.cti = '0 ;
assign wshb_if_sdram.bte = '0 ;

//--------------------------
//------- Code Eleves ------
//--------------------------

//---------------------------
//------ Instance VGA -------
//---------------------------

vga #(.VDISP(VDISP), .HDISP(HDISP)) vga_inst(
    .pixel_clk(pixel_clk),
    .pixel_rst(pixel_rst),
    .video_ifm(video_ifm)
);

always_comb 
    LED[0] = KEY[0];

// Synchronisation de pixel_clk
always_ff @(posedge pixel_clk or posedge sys_rst)
begin 
    if(sys_rst)
        begin
        pixel_rst <= 1;
        Q <= 1;
        end
    else begin
        pixel_rst <= Q;
        Q <= 0;
    end
end

// Clignotage de LED[1] sur sys_clk
always_ff @(posedge sys_clk or posedge sys_rst) begin // sys_clk à 100Mhz donc il faut multiplier la période par 100 000 000 pour avoir 1Hz donc on compte jusqu'à 99 999 999
    if(sys_rst) 
        begin
            LED[1] <= 0;
            count <= 0;
        end
    else begin
        count <= count + 1;
        if(count == hcmpt) begin
            count <= 0;
            LED[1] <= ~LED[1];
        end
    end   
end

// Clignotage de LED[2] sur pixel_clk
always_ff @(posedge pixel_clk or posedge pixel_rst) begin // sys_clk à 100Mhz donc il faut multiplier la période par 100 000 000 pour avoir 1Hz donc on compte jusqu'à 99 999 999
    if(pixel_rst) begin
            LED[2] <= 0;
            count_pix <= 0;
    end
    else begin
        count_pix <= count_pix + 1;
        if(count_pix == hcmpt_pix) begin
            count_pix <= 0;
            LED[2] <= ~LED[2];
        end
    end   
end

endmodule
