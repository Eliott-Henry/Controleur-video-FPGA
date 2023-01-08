//-----------------------------------------------------------------
// Wishbone BlockRAM
//-----------------------------------------------------------------
//
// Le paramètre mem_adr_width doit permettre de déterminer le nombre 
// de mots de la mémoire : (2048 pour mem_adr_width=11)


module wb_bram #(parameter mem_adr_width = 11) (
      // Wishbone interface
      wshb_if.slave wb_s
      );


localparam SIZE = 2 ** mem_adr_width;
logic [3:0][7:0] mem [0:SIZE-1];

logic [mem_adr_width-1:0] adr;
logic [mem_adr_width-1:0] counter;
logic [mem_adr_width-1:0] start_adr;

logic burst_mode_on;

logic ack_w;
logic ack_r;
logic ack_r_classic;
logic ack_r_pipeline; // nouvelle condition possible pour le ack

assign burst_mode_on = (wb_s.cti == 3'b010) | (wb_s.cti == 3'b001); // mode incrémentation ou adresse constante

// ACKS

always_ff @(posedge wb_s.clk)
begin      
      if(wb_s.rst)
      begin
            ack_r_pipeline <= 0;
            ack_r_classic <= 0;
      end
      else 
      begin
            ack_r_classic <= ~wb_s.we & wb_s.stb & ~ack_r;
            ack_r_pipeline <= ~wb_s.we & wb_s.stb & burst_mode_on;
      end
end

assign ack_w = wb_s.we & wb_s.stb;
assign ack_r = ack_r_classic | ack_r_pipeline;
assign wb_s.ack = ack_r | ack_w;


// Counter qui compte depuis combien de cycles on est dans le burst pour actualiser l'adresse
always_ff@(posedge wb_s.clk)
begin 
      if(wb_s.stb & burst_mode_on) counter <= counter + 1;
      else counter<=0; 
end

// Adresse initiale au début du cycle
always_ff@(posedge wb_s.clk)
      if(wb_s.stb & (counter==0)) start_adr <= wb_s.adr[mem_adr_width+1 : 2]; 

// Calcul de l'adresse courante
always_comb
      if(counter == 0) // si on est encore en mode classique
            adr = wb_s.adr[mem_adr_width+1 : 2];
      else if(wb_s.cti == 3'b001) // mode où l'adresse reste constante
            adr = start_adr;
      else // mode où on incrémente l'adresse 
            adr = start_adr + counter;

// ECRITURE ET LECTURE

always_ff  @(posedge wb_s.clk)
begin
      if(wb_s.we)
      begin
            if(wb_s.sel[0]) mem[adr][0] <= wb_s.dat_ms[7:0];
            if(wb_s.sel[1]) mem[adr][1] <= wb_s.dat_ms[15:8];
            if(wb_s.sel[2]) mem[adr][2] <= wb_s.dat_ms[23:16];
            if(wb_s.sel[3]) mem[adr][3] <= wb_s.dat_ms[31:24];
      end
      wb_s.dat_sm <= mem[adr];
end

endmodule