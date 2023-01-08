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

//localparam SIZE = 2 ** mem_adr_width;
logic [3:0][7:0] mem [0:2**mem_adr_width -1];
logic [mem_adr_width+1:2] adr; // enlever celui là ?

logic ack_w; // mettre en logic ?
logic ack_r; 

assign adr = wb_s.adr[mem_adr_width+1:2];

// ACK

assign ack_w = wb_s.we & wb_s.stb;

always_ff @(posedge wb_s.clk)
begin      
      if(wb_s.rst) ack_r <= 0;
      else ack_r <= ~wb_s.we & wb_s.stb & ~ack_r;
end

assign wb_s.ack = ack_w | ack_r;

// ECRITURE

always_ff  @(posedge wb_s.clk)
begin
      if(ack_w) // En fait l'acquittement assure plutôt qu'on a bine écrit mais ça revient au même
      begin
            if(wb_s.sel[0]) mem[adr][0] <= wb_s.dat_ms[7:0];
            if(wb_s.sel[1]) mem[adr][1] <= wb_s.dat_ms[15:8];
            if(wb_s.sel[2]) mem[adr][2] <= wb_s.dat_ms[23:16];
            if(wb_s.sel[3]) mem[adr][3] <= wb_s.dat_ms[31:24];
      end
end

// LECTURE
// Ici il a pas fait ça il a juste mis la mémoire entière dans dat_sm
// on présente la mémoire que si on est dans le cas de la lecture

always_comb begin
      if(ack_r)
      begin      
            if(wb_s.sel[0]) wb_s.dat_sm[7:0] <= mem[adr][0];
            if(wb_s.sel[1]) wb_s.dat_sm[15:8] <= mem[adr][1];
            if(wb_s.sel[2]) wb_s.dat_sm[23:16] <= mem[adr][2];
            if(wb_s.sel[3]) wb_s.dat_sm[31:24] <= mem[adr][3];
      end
end

endmodule