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
      // a vous de jouer a partir d'ici

assign wb_s.err = 0;
assign wb_s.rty = 0;
// il y a d'autres assign qu'on peut faire (voir photo tableau)
// quel octet modifier ? sel ou deux bits poids faible de l'adresse
// mot = 4 octets [ | | | ] 
// et sel sur 4b  [ | | | ] donc on sait quels octets prendre

always_ff @(posedge wb_s.clk) 
begin
      
end

endmodule

/*

Pour une ecriture : ACK au même cycle pour une écriture (combinatoirement) ack = strb
Pour une lecture : quand STB, on reçoit une adresse, on produit une donnée mais elle ne sort qu'au cycle suivant (ack) (séquentiellement) (ack = strb en retard de 1 cycle)
On va voir ack en cas de read et write différents

Essayer de séparer les deux (mémoire et contrôle : ctrl génère juste ack au bon moment)
*/