//-----------------------------------------------------------------
// Wishbone BlockRAM
//-----------------------------------------------------------------
//
// Le paramètre mem_adr_width doit permettre de déterminer le nombre 
// de mots de la mémoire : (2048 pour mem_adr_width=11)


// La simulation montre que la lecture des cases mémoires n'est pas bonne. Soit on ne retourne pas la case au bon moment, soit on a mal écrit dans la mémoire

module wb_bram #(parameter mem_adr_width = 11) (
      // Wishbone interface
      wshb_if.slave wb_s
      );
      // a vous de jouer a partir d'ici

localparam SIZE = 2 ** mem_adr_width;
logic [31:0] mem [0:SIZE];

wire ack_w;
logic ack_r;

assign wb_s.ack = ack_w | ack_r;
assign ack_w = wb_s.we & wb_s.stb;

// ack_r est synchrone

// ack écriture de manière combinatoire
// ack lecture aura un cycle de retard par rapport à la requête

// il y a d'autres assign qu'on peut faire (voir photo tableau)

// quel octet modifier ? sel ou deux bits poids faible de l'adresse
// mot = 4 octets [ | | | ] 
// et sel sur 4   [ | | | ] donc on sait quels octets prendre

always_ff @(posedge wb_s.clk)
begin      
      if(wb_s.rst) ack_r <= 0;
      else ack_r <= ~wb_s.we & wb_s.stb;
end

always_ff  @(posedge wb_s.clk)
begin
      if(wb_s.we) mem[wb_s.adr] <= wb_s.dat_ms & wb_s.sel;  // rajouter ack_w ? ça doit être synchrone ?
end

always_ff @(posedge wb_s.clk)
wb_s.dat_sm <= mem[wb_s.adr] & wb_s.sel; 
endmodule

/*
Pour une ecriture : ACK au même cycle pour une écriture (combinatoirement) ack = stb
Pour une lecture : quand STB, on reçoit une adresse, on produit une donnée mais elle ne sort qu'au cycle suivant (ack) (séquentiellement) (ack = strb en retard de 1 cycle)
On va voir ack en cas de read et write différents

Essayer de séparer les deux (mémoire et contrôle : ctrl génère juste ack au bon moment)
*/