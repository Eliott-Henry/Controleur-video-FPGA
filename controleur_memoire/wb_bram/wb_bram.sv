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

localparam SIZE = 2 ** mem_adr_width;
logic [3:0][7:0] mem [0:SIZE-1];
logic [mem_adr_width+1:2] adr;

logic ack_w;
logic ack_r;
logic ack_r_classic; 
logic ack_r_pipeline;
logic init;

assign adr = wb_s.adr[mem_adr_width+1:2];

// ACKs

assign ack_w = wb_s.we & wb_s.stb;

always_ff @(posedge wb_s.clk)
begin      
      if(wb_s.rst)
      begin
            ack_r_classic <= 0;
            ack_r_pipeline <= 0;
      end
      else 
      begin 
            ack_r_classic <= ~wb_s.we & wb_s.stb & ~ack_r_classic;
            ack_r_pipeline <= ~wb_s.we & wb_s.stb & (wb_s.cti == 3'b010);
      end
end

assign ack_r = ack_r_classic | ack_r_pipeline;
assign wb_s.ack = ack_w | ack_r;

// ECRITURE

always_ff  @(posedge wb_s.clk)
begin
      if(wb_s.stb & wb_s.we)
      begin
            if(wb_s.sel[0]) mem[adr][0] <= wb_s.dat_ms[7:0];
            if(wb_s.sel[1]) mem[adr][1] <= wb_s.dat_ms[15:8];
            if(wb_s.sel[2]) mem[adr][2] <= wb_s.dat_ms[23:16];
            if(wb_s.sel[3]) mem[adr][3] <= wb_s.dat_ms[31:24];
      end
end

// LECTURE

// Classic mode
always_ff@(posedge wb_s.clk) begin
      if(wb_s.stb & ~wb_s.we & ~ack_r_classic) wb_s.dat_sm <= mem[adr];
end

// Pipeline mode
always_ff@(posedge wb_s.clk) begin
      if(wb_s.stb & ~wb_s.we & (wb_s.cti == 3'b010)) begin
            if(init) wb_s.dat_sm <= mem[adr];
            else wb_s.dat_sm <= mem[adr + 1];
      end
end

always_comb begin
      init = wb_s.stb & ~wb_s.we & (wb_s.cti == 3'b010) & ~ack_r_pipeline;
end

/*

always_ff@(posedge wb_s.clk) begin
      if(wb_s.stb & ~wb_s.we & (wb_s.cti == 0'b010))
      begin
            if(init) 
            begin
                  wb_s.dat_sm <= mem[adr];
                  adr_pipeline <= adr + 1;
            end
            else 
            begin
                  wb_s.dat_sm <= mem[adr_pipeline];
                  adr_pipeline <= adr_pipeline + 1;
            end
      end
end

always_comb begin
      init = wb_s.stb & wb_s.we & (wb_s.cti == 3'b010) & ~ack_r_pipeline;
end*/

endmodule