module wshb_intercon(
    wshb_if.slave wshb_ifs_mire,
    wshb_if.slave wshb_ifs_vga,
    wshb_if.master wshb_ifm
);

enum logic{TOK_MIRE, TOK_VGA} tok;

// Gestion du jeton 
always@(posedge wshb_ifm.clk or posedge wshb_ifm.rst)
begin
    if(wshb_ifm.rst) tok <= TOK_MIRE;
    else begin
        case(tok)
            TOK_MIRE : if(~wshb_ifs_mire.cyc) tok <= TOK_VGA;
            TOK_VGA : if(~wshb_ifs_vga.cyc) tok <= TOK_MIRE; 
        endcase
    end
end

// ---------- Signaux de commande pour le wishbone de la SDRAM  ------- //

// cyc
always_comb 
begin
    case(tok)
        TOK_MIRE : wshb_ifm.cyc = wshb_ifs_mire.cyc;
        TOK_VGA : wshb_ifm.cyc = wshb_ifs_vga.cyc;
    endcase
end

// stb
always_comb 
begin
    case(tok)
        TOK_MIRE : wshb_ifm.stb = wshb_ifs_mire.stb;
        TOK_VGA : wshb_ifm.stb = wshb_ifs_vga.stb;
    endcase
end

// we
always_comb 
begin
    case(tok)
        TOK_MIRE : wshb_ifm.we = wshb_ifs_mire.we;
        TOK_VGA : wshb_ifm.we = wshb_ifs_vga.we;
    endcase
end

// adr
always_comb 
begin
    case(tok)
        TOK_MIRE : wshb_ifm.adr = wshb_ifs_mire.adr;
        TOK_VGA : wshb_ifm.adr = wshb_ifs_vga.adr;
    endcase
end

// sel
always_comb 
begin
    case(tok)
        TOK_MIRE : wshb_ifm.sel = wshb_ifs_mire.sel;
        TOK_VGA : wshb_ifm.sel = wshb_ifs_vga.sel;
    endcase
end

// dat_ms
always_comb 
begin
    case(tok)
        TOK_MIRE : wshb_ifm.dat_ms = wshb_ifs_mire.dat_ms;
        TOK_VGA : wshb_ifm.dat_ms = wshb_ifs_vga.dat_ms;
    endcase
end

// ------------ SIGNAUX DE REPONSE POUR LES ESCLAVES VGA ET MIRE ----------- //

// ack mire
always_comb
begin
    case(tok)
        TOK_MIRE: wshb_ifs_mire.ack = wshb_ifm.ack;
        TOK_VGA: wshb_ifs_mire.ack = 0;
    endcase
end

// ack vga
always_comb
begin
    case(tok)
        TOK_VGA: wshb_ifs_vga.ack = wshb_ifm.ack;
        TOK_MIRE: wshb_ifs_vga.ack = 0;
    endcase
end

assign wshb_ifs_vga.dat_sm = wshb_ifm.dat_sm;

endmodule