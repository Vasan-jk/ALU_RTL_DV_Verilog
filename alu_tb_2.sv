module tb_alu_rtl;

// -------------------------------------------------------
// Parameters
// -------------------------------------------------------
parameter W   = 8;
parameter CW  = 4;

// -------------------------------------------------------
// DUT Signals
// -------------------------------------------------------
reg [W-1:0]     OPA, OPB;
reg             CLK, RST, CIN, CE, MODE;
reg [1:0]       INP_VALID;
reg [CW-1:0]    CMD;

wire [2*W-1:0]  RES;
wire            OFLOW, COUT, G, L, E, ERR;

// -------------------------------------------------------
// DUT Instantiation
// -------------------------------------------------------
alu_rtl #(.width(W), .cmd_width(CW)) DUT (
    .CLK(CLK), .RST(RST),
    .INP_VALID(INP_VALID), .MODE(MODE),
    .CMD(CMD), .CE(CE),
    .OPA(OPA), .OPB(OPB), .CIN(CIN),
    .ERR(ERR), .RES(RES), .OFLOW(OFLOW),
    .COUT(COUT), .G(G), .L(L), .E(E)
);

// -------------------------------------------------------
// Clock  (period = 10 ns)
// -------------------------------------------------------
initial CLK = 0;
always  #5 CLK = ~CLK;

// -------------------------------------------------------
// Scoreboard
// -------------------------------------------------------
integer pass_cnt, fail_cnt, tc_num;
initial begin pass_cnt=0; fail_cnt=0; tc_num=0; end

// -------------------------------------------------------
// Helper Tasks
// -------------------------------------------------------

// Set inputs on the negedge so they are stable before posedge
task set_inp;
    input [W-1:0] opa, opb;
    input cin, ce, mode;
    input [1:0]   inv;
    input [CW-1:0] cmd;
    begin
        @(negedge CLK);
        OPA=opa; OPB=opb; CIN=cin; CE=ce; MODE=mode; INP_VALID=inv; CMD=cmd;
    end
endtask

// Advance one clock and sample outputs
task tick; begin @(posedge CLK); #1; end endtask

// Individual output checkers ----------------------------------------

task chk_res;
    input [2*W-1:0] exp;
    input [63:0]    tc;
    input [255:0]   lbl;
    begin
        tc_num = tc_num + 1;
        if (RES !== exp) begin
            $display("[FAIL] TC%0d %-50s | RES exp=%04h got=%04h", tc, lbl, exp, RES);
            fail_cnt = fail_cnt + 1;
        end else begin
            $display("[PASS] TC%0d %-50s", tc, lbl);
            pass_cnt = pass_cnt + 1;
        end
    end
endtask

task chk_cout;
    input exp;
    input [63:0]  tc;
    input [255:0] lbl;
    begin
        tc_num = tc_num + 1;
        if (COUT !== exp) begin
            $display("[FAIL] TC%0d %-50s | COUT exp=%0b got=%0b", tc, lbl, exp, COUT);
            fail_cnt = fail_cnt + 1;
        end else begin
            $display("[PASS] TC%0d %-50s", tc, lbl);
            pass_cnt = pass_cnt + 1;
        end
    end
endtask

task chk_oflow;
    input exp;
    input [63:0]  tc;
    input [255:0] lbl;
    begin
        tc_num = tc_num + 1;
        if (OFLOW !== exp) begin
            $display("[FAIL] TC%0d %-50s | OFLOW exp=%0b got=%0b", tc, lbl, exp, OFLOW);
            fail_cnt = fail_cnt + 1;
        end else begin
            $display("[PASS] TC%0d %-50s", tc, lbl);
            pass_cnt = pass_cnt + 1;
        end
    end
endtask

task chk_gle;
    input exp_g, exp_l, exp_e;
    input [63:0]  tc;
    input [255:0] lbl;
    begin
        tc_num = tc_num + 1;
        if (G!==exp_g || L!==exp_l || E!==exp_e) begin
            $display("[FAIL] TC%0d %-50s | G/L/E exp=%0b/%0b/%0b got=%0b/%0b/%0b",
                     tc, lbl, exp_g, exp_l, exp_e, G, L, E);
            fail_cnt = fail_cnt + 1;
        end else begin
            $display("[PASS] TC%0d %-50s", tc, lbl);
            pass_cnt = pass_cnt + 1;
        end
    end
endtask

task chk_err;
    input exp;
    input [63:0]  tc;
    input [255:0] lbl;
    begin
        tc_num = tc_num + 1;
        if (ERR !== exp) begin
            $display("[FAIL] TC%0d %-50s | ERR exp=%0b got=%0b", tc, lbl, exp, ERR);
            fail_cnt = fail_cnt + 1;
        end else begin
            $display("[PASS] TC%0d %-50s", tc, lbl);
            pass_cnt = pass_cnt + 1;
        end
    end
endtask

// Composite: apply + one tick + check RES
task apply_chk_res;
    input [W-1:0]  opa, opb;
    input          cin, ce, mode;
    input [1:0]    inv;
    input [CW-1:0] cmd;
    input [2*W-1:0] exp_res;
    input [63:0]   tc;
    input [255:0]  lbl;
    begin
        set_inp(opa, opb, cin, ce, mode, inv, cmd);
        tick;
        chk_res(exp_res, tc, lbl);
    end
endtask

// Multi-cycle test helper (4 posedges, then check)
task multi_cyc_chk;
    input [W-1:0]   opa, opb;
    input [CW-1:0]  cmd;
    input [2*W-1:0] exp_res;
    input [63:0]    tc;
    input [255:0]   lbl;
    integer i;
    begin
        @(negedge CLK);
        OPA=opa; OPB=opb; CIN=0; CE=1; MODE=1; INP_VALID=2'b11; CMD=cmd;
        repeat(3) @(posedge CLK);
        #1;
        tc_num = tc_num + 1;
        if (RES !== exp_res) begin
            $display("[FAIL] TC%0d %-50s | RES exp=%04h got=%04h", tc, lbl, exp_res, RES);
            fail_cnt = fail_cnt + 1;
        end else begin
            $display("[PASS] TC%0d %-50s", tc, lbl);
            pass_cnt = pass_cnt + 1;
        end
    end
endtask

// -------------------------------------------------------
// Convenience constants
// -------------------------------------------------------
localparam ZZ   = {2*W{1'bz}};   // all-z result bus
localparam Zb   = 1'bz;          // single z bit

// ============================================================
//  STIMULUS
// ============================================================
initial begin
    $dumpfile("tb_alu_rtl.vcd");
    $dumpvars(0, tb_alu_rtl);

    // Initialise
    RST=1; CLK=0; CE=0; MODE=0; CMD=0;
    OPA=0; OPB=0; CIN=0; INP_VALID=0;
    repeat(3) @(posedge CLK);
    RST=0;

    // ============================================================
    $display("\n=== SECTION 1: RST / CE=0 / INP_VALID mismatch ===");
    // ============================================================

    // RST forces outputs to z
    RST=1; @(posedge CLK); #1;
    tc_num=tc_num+1;
    if (RES!==ZZ || COUT!==Zb || OFLOW!==Zb) begin
        $display("[FAIL] TC%0d RST: outputs should be z", tc_num);
        fail_cnt=fail_cnt+1;
    end else begin
        $display("[PASS] TC%0d RST: outputs=z", tc_num);
        pass_cnt=pass_cnt+1;
    end
    RST=0; @(posedge CLK); #1;

    // CE=0 forces outputs to z regardless of inputs
    apply_chk_res(8'hAA,8'hBB, 0,0,1, 2'b11, 4'd0, ZZ, tc_num+1, "CE=0 -> RES=z");

    // MODE=1 CMD=0 (ADD) needs INP_VALID==3
    apply_chk_res(8'h0A,8'h05, 0,1,1, 2'b01, 4'd0, ZZ, tc_num+1, "ADD INP_VALID=1 (invalid) -> z");
    apply_chk_res(8'h0A,8'h05, 0,1,1, 2'b10, 4'd0, ZZ, tc_num+1, "ADD INP_VALID=2 (invalid) -> z");

    // CMD4 INC_A valid for INP_VALID=1 or 3, NOT 2
    apply_chk_res(8'h05,8'h00, 0,1,1, 2'b10, 4'd4, ZZ, tc_num+1, "INC_A INP_VALID=2 (invalid) -> z");

    // CMD6 INC_B valid for INP_VALID=2 or 3, NOT 1
    apply_chk_res(8'h00,8'h05, 0,1,1, 2'b01, 4'd6, ZZ, tc_num+1, "INC_B INP_VALID=1 (invalid) -> z");

    // MODE=0 CMD=0 (AND) needs INP_VALID==3
    apply_chk_res(8'hFF,8'hFF, 0,1,0, 2'b01, 4'd0, ZZ, tc_num+1, "AND INP_VALID=1 (invalid) -> z");

    // MODE=0 CMD=6 (NOT_A) valid for INP_VALID=1 or 3, NOT 2
    apply_chk_res(8'hFF,8'h00, 0,1,0, 2'b10, 4'd6, ZZ, tc_num+1, "NOT_A INP_VALID=2 (invalid) -> z");

    // MODE=0 CMD=7 (NOT_B) valid for INP_VALID=2 or 3, NOT 1
    apply_chk_res(8'h00,8'hFF, 0,1,0, 2'b01, 4'd7, ZZ, tc_num+1, "NOT_B INP_VALID=1 (invalid) -> z");

    // Default/unused CMD codes
    apply_chk_res(8'hAA,8'hBB, 0,1,1, 2'b11, 4'd15, ZZ, tc_num+1, "MODE1 CMD15 (undefined) -> z");
    apply_chk_res(8'hAA,8'hBB, 0,1,0, 2'b11, 4'd14, ZZ, tc_num+1, "MODE0 CMD14 (undefined) -> z");

    // ============================================================
    $display("\n=== SECTION 2: Arithmetic Mode (MODE=1) ===");
    // ============================================================

    // ----- CMD 0 : ADD (OPA + OPB) -----
    $display("-- CMD0: ADD --");
    set_inp(8'h05,8'h03, 0,1,1, 2'b11, 4'd0); tick;
    chk_res(16'h0008, tc_num+1, "ADD 5+3=8");
    chk_cout(1'b0,    tc_num+1, "ADD 5+3 COUT=0");        // BUG-1 will fail

    set_inp(8'hFF,8'h01, 0,1,1, 2'b11, 4'd0); tick;
    chk_res(16'h0100, tc_num+1, "ADD 0xFF+1=0x100");
    chk_cout(1'b1,    tc_num+1, "ADD 0xFF+1 COUT=1");     // BUG-1 will fail

    set_inp(8'h00,8'h00, 0,1,1, 2'b11, 4'd0); tick;
    chk_res(16'h0000, tc_num+1, "ADD 0+0=0");

    set_inp(8'hFF,8'hFF, 0,1,1, 2'b11, 4'd0); tick;
    chk_res(16'h01FE, tc_num+1, "ADD 0xFF+0xFF=0x1FE");

    set_inp(8'h7F,8'h01, 0,1,1, 2'b11, 4'd0); tick;
    chk_res(16'h0080, tc_num+1, "ADD 0x7F+1=0x80");

    // ----- CMD 1 : SUB (OPA - OPB) -----
    $display("-- CMD1: SUB --");
    set_inp(8'h0A,8'h03, 0,1,1, 2'b11, 4'd1); tick;
    chk_res(16'h0007, tc_num+1, "SUB 10-3=7");
    chk_oflow(1'b0,   tc_num+1, "SUB 10-3 OFLOW=0");

    set_inp(8'h03,8'h0A, 0,1,1, 2'b11, 4'd1); tick;
    chk_res({16{1'b1}} & ((~8'h06)+1'b1), tc_num+1, "SUB 3-10 underflow result");
    chk_oflow(1'b1,   tc_num+1, "SUB 3-10 OFLOW=1");

    set_inp(8'hFF,8'hFF, 0,1,1, 2'b11, 4'd1); tick;
    chk_res(16'h0000, tc_num+1, "SUB 0xFF-0xFF=0");
    chk_oflow(1'b0,   tc_num+1, "SUB equal operands OFLOW=0");

    set_inp(8'h00,8'h01, 0,1,1, 2'b11, 4'd1); tick;
    chk_res(16'hFFFF, tc_num+1, "SUB 0-1 wrap");
    chk_oflow(1'b1,   tc_num+1, "SUB 0-1 OFLOW=1");

    set_inp(8'h00,8'hFF, 0,1,1, 2'b11, 4'd1); tick;
    chk_oflow(1'b1,   tc_num+1, "SUB 0-0xFF OFLOW=1");

    // ----- CMD 2 : ADDC (OPA + OPB + CIN) -----
    $display("-- CMD2: ADDC --");
    set_inp(8'h05,8'h03, 1,1,1, 2'b11, 4'd2); tick;
    chk_res(16'h0009, tc_num+1, "ADDC 5+3+1=9");
    chk_cout(1'b0,    tc_num+1, "ADDC 5+3+1 COUT=0");    // BUG-12 (hardcoded [8]) may pass

    set_inp(8'hFE,8'h01, 1,1,1, 2'b11, 4'd2); tick;
    chk_res(16'h0100, tc_num+1, "ADDC 0xFE+1+1=0x100");
    chk_cout(1'b1,    tc_num+1, "ADDC 0xFE+1+1 COUT=1");

    set_inp(8'hFF,8'hFF, 1,1,1, 2'b11, 4'd2); tick;
    chk_res(16'h01FF, tc_num+1, "ADDC 0xFF+0xFF+1=0x1FF");
    chk_cout(1'b1,    tc_num+1, "ADDC 0xFF+0xFF+1 COUT=1");

    set_inp(8'h05,8'h03, 0,1,1, 2'b11, 4'd2); tick;  // CIN=0
    chk_res(16'h0008, tc_num+1, "ADDC CIN=0: 5+3=8");

    // ----- CMD 3 : SUBB (OPA - OPB - CIN) -----
    $display("-- CMD3: SUBB --");
    set_inp(8'h0A,8'h03, 1,1,1, 2'b11, 4'd3); tick;
    chk_res(16'h0006, tc_num+1, "SUBB 10-3-1=6");
    chk_oflow(1'b0,   tc_num+1, "SUBB 10-3-1 OFLOW=0");

    set_inp(8'h03,8'h03, 1,1,1, 2'b11, 4'd3); tick;  // 3-3-1 = -1
    chk_res(16'hFFFF, tc_num+1, "SUBB 3-3-1=-1 wrap");
    chk_oflow(1'b1,   tc_num+1, "SUBB 3-3-1 OFLOW=1"); // BUG-7: RTL ignores CIN

    set_inp(8'h05,8'h03, 0,1,1, 2'b11, 4'd3); tick;  // CIN=0
    chk_res(16'h0002, tc_num+1, "SUBB 5-3-0=2");

    set_inp(8'h00,8'h00, 1,1,1, 2'b11, 4'd3); tick;  // 0-0-1 = -1
    chk_oflow(1'b1,   tc_num+1, "SUBB 0-0-1 OFLOW=1"); // BUG-7

    // ----- CMD 4 : INC_A (OPA + 1) -----
    $display("-- CMD4: INC_A --");
    set_inp(8'h05,8'h00, 0,1,1, 2'b11, 4'd4); tick;
    chk_res(16'h0006, tc_num+1, "INC_A 5+1=6 (INP_VALID=3)");

    set_inp(8'h05,8'h00, 0,1,1, 2'b01, 4'd4); tick;  // INP_VALID=1 also valid
    chk_res(16'h0006, tc_num+1, "INC_A 5+1=6 (INP_VALID=1)");

    set_inp(8'hFF,8'h00, 0,1,1, 2'b11, 4'd4); tick;
    chk_res(16'h0100, tc_num+1, "INC_A 0xFF+1=0x100");

    set_inp(8'h00,8'h00, 0,1,1, 2'b11, 4'd4); tick;
    chk_res(16'h0001, tc_num+1, "INC_A 0+1=1");

    // ----- CMD 5 : DEC_A (OPA - 1) -----
    $display("-- CMD5: DEC_A --");
    set_inp(8'h05,8'h00, 0,1,1, 2'b11, 4'd5); tick;
    chk_res(16'h0004, tc_num+1, "DEC_A 5-1=4");

    set_inp(8'h00,8'h00, 0,1,1, 2'b11, 4'd5); tick;
    chk_res(16'hFFFF, tc_num+1, "DEC_A 0-1 wrap");

    set_inp(8'h01,8'h00, 0,1,1, 2'b01, 4'd5); tick;  // INP_VALID=1
    chk_res(16'h0000, tc_num+1, "DEC_A 1-1=0 (INP_VALID=1)");

    // ----- CMD 6 : INC_B (OPB + 1) -----
    $display("-- CMD6: INC_B --");
    set_inp(8'h00,8'h07, 0,1,1, 2'b11, 4'd6); tick;
    chk_res(16'h0008, tc_num+1, "INC_B 7+1=8 (INP_VALID=3)");

    set_inp(8'h00,8'h07, 0,1,1, 2'b10, 4'd6); tick;  // INP_VALID=2 also valid
    chk_res(16'h0008, tc_num+1, "INC_B 7+1=8 (INP_VALID=2)");

    set_inp(8'h00,8'hFF, 0,1,1, 2'b11, 4'd6); tick;
    chk_res(16'h0100, tc_num+1, "INC_B 0xFF+1=0x100");

    // ----- CMD 7 : DEC_B (OPB - 1) -----
    $display("-- CMD7: DEC_B --");
    set_inp(8'h00,8'h07, 0,1,1, 2'b11, 4'd7); tick;
    chk_res(16'h0006, tc_num+1, "DEC_B 7-1=6");

    set_inp(8'h00,8'h00, 0,1,1, 2'b10, 4'd7); tick;  // INP_VALID=2
    chk_res(16'hFFFF, tc_num+1, "DEC_B 0-1 wrap (INP_VALID=2)");

    // ----- CMD 8 : CMP (compare OPA vs OPB) -----
    $display("-- CMD8: CMP --");
    set_inp(8'h0A,8'h0A, 0,1,1, 2'b11, 4'd8); tick;
    chk_gle(Zb, Zb, 1'b1, tc_num+1, "CMP OPA==OPB: E=1");

    set_inp(8'h0F,8'h0A, 0,1,1, 2'b11, 4'd8); tick;
    chk_gle(1'b1, Zb, Zb, tc_num+1, "CMP OPA>OPB: G=1");

    set_inp(8'h0A,8'h0F, 0,1,1, 2'b11, 4'd8); tick;
    chk_gle(Zb, 1'b1, Zb, tc_num+1, "CMP OPA<OPB: L=1");

    set_inp(8'h00,8'hFF, 0,1,1, 2'b11, 4'd8); tick;
    chk_gle(Zb, 1'b1, Zb, tc_num+1, "CMP 0 < 0xFF: L=1");

    set_inp(8'hFF,8'h00, 0,1,1, 2'b11, 4'd8); tick;
    chk_gle(1'b1, Zb, Zb, tc_num+1, "CMP 0xFF > 0: G=1");

    set_inp(8'h00,8'h00, 0,1,1, 2'b11, 4'd8); tick;
    chk_gle(Zb, Zb, 1'b1, tc_num+1, "CMP 0==0: E=1");

    // ----- CMD 9 : MUL OPA*OPB (4-cycle latency) -----
    // NOTE: RTL bug computes (OPA+1)*(OPB+1) — correct value is OPA*OPB
    $display("-- CMD9: MUL (multi-cycle) --");
    multi_cyc_chk(8'h03,8'h04, 4'd9, 16'h0014, tc_num+1, "MUL 3*4=20");       // BUG-4: RTL gives 20
    multi_cyc_chk(8'h05,8'h05, 4'd9, 16'h0024, tc_num+1, "MUL 5*5=25");       // BUG-4: RTL gives 36
    multi_cyc_chk(8'h01,8'h01, 4'd9, 16'h0004, tc_num+1, "MUL 1*1=1");        // BUG-4: RTL gives 4
    multi_cyc_chk(8'h00,8'h00, 4'd9, 16'h0001, tc_num+1, "MUL 0*0=0");        // BUG-4: RTL gives 1
    multi_cyc_chk(8'hFF,8'hFF, 4'd9, 16'h0000, tc_num+1, "MUL 255*255=65025"); // BUG-4
    multi_cyc_chk(8'h10,8'h10, 4'd9, 16'h0121, tc_num+1, "MUL 16*16=256");

    // INP_VALID mismatch during CMD9 — output must be z on mismatch cycle
    @(negedge CLK);
    OPA=8'h03; OPB=8'h04; CIN=0; CE=1; MODE=1; INP_VALID=2'b11; CMD=4'd9;
    @(posedge CLK);             // cnt: 0->1
    @(negedge CLK);
    INP_VALID=2'b01;            // invalid
    tick;
    chk_res(ZZ, tc_num+1, "CMD9 INP_VALID mismatch -> z");
    // Drain cnt: run 3 more valid cycles to reset state
    @(negedge CLK); INP_VALID=2'b11;
    repeat(3) @(posedge CLK); #1;

    // ----- CMD 10 : Shift-Multiply (OPA<<1)*OPB (4-cycle latency) -----
    $display("-- CMD10: SHIFT-MUL (multi-cycle) --");
    multi_cyc_chk(8'h03,8'h04, 4'd10, 16'h0018, tc_num+1, "SHIFTMUL (3<<1)*4=24");
    multi_cyc_chk(8'h01,8'h08, 4'd10, 16'h0010, tc_num+1, "SHIFTMUL (1<<1)*8=16");
    multi_cyc_chk(8'h00,8'hFF, 4'd10, 16'h0000, tc_num+1, "SHIFTMUL (0<<1)*255=0");

    // ----- CMD 11 : Signed ADD -----
    // BUG-2: IA/IB undriven; BUG-3: OFLOW formula; all will FAIL until fixed
    $display("-- CMD11: Signed ADD (BUG-2/3 expected failures) --");
    set_inp(8'h05,8'h03, 0,1,1, 2'b11, 4'd11); tick;
    chk_res(16'h0008,   tc_num+1, "SADD +5+3=8");
    chk_oflow(1'b0,     tc_num+1, "SADD +5+3 no overflow");
    chk_gle(1'b1,Zb,Zb, tc_num+1, "SADD IA=5 > IB=3: G=1");

    // +127 + +1 = -128 (positive overflow)
    set_inp(8'h7F,8'h01, 0,1,1, 2'b11, 4'd11); tick;
    chk_oflow(1'b1,     tc_num+1, "SADD +127+1 overflow");

    // -5 + 5 = 0
    set_inp(8'hFB,8'h05, 0,1,1, 2'b11, 4'd11); tick;
    chk_res(16'h0000,   tc_num+1, "SADD -5+5=0");
    chk_oflow(1'b0,     tc_num+1, "SADD -5+5 no overflow");
    chk_gle(Zb,1'b1,Zb, tc_num+1, "SADD IA=-5 < IB=5: L=1");

    // -1 + -1 = -2
    set_inp(8'hFF,8'hFF, 0,1,1, 2'b11, 4'd11); tick;
    chk_res(16'hFFFE,   tc_num+1, "SADD -1+-1=-2");
    chk_oflow(1'b0,     tc_num+1, "SADD -1+-1 no overflow");
    chk_gle(Zb,Zb,1'b1, tc_num+1, "SADD IA==IB=-1: E=1");

    // -128 + -1 = -129 (negative overflow)
    set_inp(8'h80,8'hFF, 0,1,1, 2'b11, 4'd11); tick;
    chk_oflow(1'b1,     tc_num+1, "SADD -128+-1 negative overflow");

    // ----- CMD 12 : Signed SUB -----
    $display("-- CMD12: Signed SUB (BUG-2/3 expected failures) --");
    set_inp(8'h0A,8'h03, 0,1,1, 2'b11, 4'd12); tick;
    chk_res(16'h0007,   tc_num+1, "SSUB +10-3=7");
    chk_oflow(1'b0,     tc_num+1, "SSUB +10-3 no overflow");
    chk_gle(1'b1,Zb,Zb, tc_num+1, "SSUB IA=10 > IB=3: G=1");

    // -128 - 1 = -129 (negative overflow)
    set_inp(8'h80,8'h01, 0,1,1, 2'b11, 4'd12); tick;
    chk_oflow(1'b1,     tc_num+1, "SSUB -128-1 overflow");

    // -1 - (-1) = 0
    set_inp(8'hFF,8'hFF, 0,1,1, 2'b11, 4'd12); tick;
    chk_res(16'h0000,   tc_num+1, "SSUB -1-(-1)=0");
    chk_gle(Zb,Zb,1'b1, tc_num+1, "SSUB IA==IB: E=1");

    // 5 - 10: IA < IB
    set_inp(8'h05,8'h0A, 0,1,1, 2'b11, 4'd12); tick;
    chk_gle(Zb,1'b1,Zb, tc_num+1, "SSUB IA=5 < IB=10: L=1");

    // ============================================================
    $display("\n=== SECTION 3: Logic Mode (MODE=0) ===");
    // ============================================================

    // ----- CMD 0 : AND -----
    $display("-- CMD0: AND --");
    apply_chk_res(8'hAA,8'hF0, 0,1,0, 2'b11, 4'd0, {8'h00,8'hA0}, tc_num+1, "AND 0xAA & 0xF0 = 0xA0");
    apply_chk_res(8'hFF,8'h00, 0,1,0, 2'b11, 4'd0, {8'h00,8'h00}, tc_num+1, "AND 0xFF & 0x00 = 0x00");
    apply_chk_res(8'hFF,8'hFF, 0,1,0, 2'b11, 4'd0, {8'h00,8'hFF}, tc_num+1, "AND 0xFF & 0xFF = 0xFF");
    apply_chk_res(8'hA5,8'h5A, 0,1,0, 2'b11, 4'd0, {8'h00,8'h00}, tc_num+1, "AND 0xA5 & 0x5A = 0x00");

    // ----- CMD 1 : NAND -----
    $display("-- CMD1: NAND --");
    apply_chk_res(8'hAA,8'hF0, 0,1,0, 2'b11, 4'd1, {8'h00,8'h5F}, tc_num+1, "NAND 0xAA & 0xF0 = 0x5F");
    apply_chk_res(8'hFF,8'hFF, 0,1,0, 2'b11, 4'd1, {8'h00,8'h00}, tc_num+1, "NAND 0xFF & 0xFF = 0x00");
    apply_chk_res(8'h00,8'h00, 0,1,0, 2'b11, 4'd1, {8'h00,8'hFF}, tc_num+1, "NAND 0x00 & 0x00 = 0xFF");

    // ----- CMD 2 : OR -----
    $display("-- CMD2: OR --");
    apply_chk_res(8'hA0,8'h0F, 0,1,0, 2'b11, 4'd2, {8'h00,8'hAF}, tc_num+1, "OR 0xA0 | 0x0F = 0xAF");
    apply_chk_res(8'h00,8'h00, 0,1,0, 2'b11, 4'd2, {8'h00,8'h00}, tc_num+1, "OR 0x00 | 0x00 = 0x00");
    apply_chk_res(8'hFF,8'h00, 0,1,0, 2'b11, 4'd2, {8'h00,8'hFF}, tc_num+1, "OR 0xFF | 0x00 = 0xFF");
    apply_chk_res(8'hAA,8'h55, 0,1,0, 2'b11, 4'd2, {8'h00,8'hFF}, tc_num+1, "OR 0xAA | 0x55 = 0xFF");

    // ----- CMD 3 : NOR -----
    $display("-- CMD3: NOR --");
    apply_chk_res(8'hA0,8'h0F, 0,1,0, 2'b11, 4'd3, {8'h00,8'h50}, tc_num+1, "NOR 0xA0|0x0F = 0x50");
    apply_chk_res(8'h00,8'h00, 0,1,0, 2'b11, 4'd3, {8'h00,8'hFF}, tc_num+1, "NOR 0x00|0x00 = 0xFF");
    apply_chk_res(8'hFF,8'hFF, 0,1,0, 2'b11, 4'd3, {8'h00,8'h00}, tc_num+1, "NOR 0xFF|0xFF = 0x00");

    // ----- CMD 4 : XOR -----
    $display("-- CMD4: XOR --");
    apply_chk_res(8'hAA,8'h55, 0,1,0, 2'b11, 4'd4, {8'h00,8'hFF}, tc_num+1, "XOR 0xAA^0x55=0xFF");
    apply_chk_res(8'hFF,8'hFF, 0,1,0, 2'b11, 4'd4, {8'h00,8'h00}, tc_num+1, "XOR 0xFF^0xFF=0x00");
    apply_chk_res(8'hA5,8'h5A, 0,1,0, 2'b11, 4'd4, {8'h00,8'hFF}, tc_num+1, "XOR 0xA5^0x5A=0xFF");
    apply_chk_res(8'h00,8'h00, 0,1,0, 2'b11, 4'd4, {8'h00,8'h00}, tc_num+1, "XOR 0x00^0x00=0x00");

    // ----- CMD 5 : XNOR -----
    $display("-- CMD5: XNOR --");
    apply_chk_res(8'hAA,8'h55, 0,1,0, 2'b11, 4'd5, {8'h00,8'h00}, tc_num+1, "XNOR 0xAA^0x55=0x00");
    apply_chk_res(8'hFF,8'hFF, 0,1,0, 2'b11, 4'd5, {8'h00,8'hFF}, tc_num+1, "XNOR 0xFF^0xFF=0xFF");
    apply_chk_res(8'h00,8'h00, 0,1,0, 2'b11, 4'd5, {8'h00,8'hFF}, tc_num+1, "XNOR 0x00^0x00=0xFF");

    // ----- CMD 6 : NOT_A (~OPA) -----
    $display("-- CMD6: NOT_A --");
    apply_chk_res(8'hAA,8'h00, 0,1,0, 2'b11, 4'd6, {8'h00,8'h55}, tc_num+1, "NOT_A ~0xAA=0x55 (INP_VALID=3)");
    apply_chk_res(8'h00,8'h00, 0,1,0, 2'b01, 4'd6, {8'h00,8'hFF}, tc_num+1, "NOT_A ~0x00=0xFF (INP_VALID=1)");
    apply_chk_res(8'hFF,8'h00, 0,1,0, 2'b11, 4'd6, {8'h00,8'h00}, tc_num+1, "NOT_A ~0xFF=0x00");
    apply_chk_res(8'h55,8'h00, 0,1,0, 2'b11, 4'd6, {8'h00,8'hAA}, tc_num+1, "NOT_A ~0x55=0xAA");

    // ----- CMD 7 : NOT_B (~OPB) -----
    $display("-- CMD7: NOT_B --");
    apply_chk_res(8'h00,8'hAA, 0,1,0, 2'b11, 4'd7, {8'h00,8'h55}, tc_num+1, "NOT_B ~0xAA=0x55 (INP_VALID=3)");
    apply_chk_res(8'h00,8'hAA, 0,1,0, 2'b10, 4'd7, {8'h00,8'h55}, tc_num+1, "NOT_B ~0xAA=0x55 (INP_VALID=2)");
    apply_chk_res(8'h00,8'hFF, 0,1,0, 2'b11, 4'd7, {8'h00,8'h00}, tc_num+1, "NOT_B ~0xFF=0x00");

    // ----- CMD 8 : SHL_A (OPA << 1) -----
    $display("-- CMD8: SHL_A --");
    apply_chk_res(8'h01,8'h00, 0,1,0, 2'b11, 4'd8, {8'h00,8'h02}, tc_num+1, "SHL_A 0x01<<1=0x02");
    apply_chk_res(8'hAA,8'h00, 0,1,0, 2'b01, 4'd8, {8'h00,8'h54}, tc_num+1, "SHL_A 0xAA<<1=0x54 (INP_VALID=1)");
    apply_chk_res(8'hFF,8'h00, 0,1,0, 2'b11, 4'd8, {8'h00,8'hFE}, tc_num+1, "SHL_A 0xFF<<1=0xFE");
    apply_chk_res(8'h80,8'h00, 0,1,0, 2'b11, 4'd8, {8'h00,8'h00}, tc_num+1, "SHL_A 0x80<<1=0x00 (MSB lost)");

    // ----- CMD 9 : SHR_A (OPA >> 1) -----
    $display("-- CMD9: SHR_A --");
    apply_chk_res(8'h02,8'h00, 0,1,0, 2'b11, 4'd9, {8'h00,8'h01}, tc_num+1, "SHR_A 0x02>>1=0x01");
    apply_chk_res(8'hAA,8'h00, 0,1,0, 2'b01, 4'd9, {8'h00,8'h55}, tc_num+1, "SHR_A 0xAA>>1=0x55 (INP_VALID=1)");
    apply_chk_res(8'hFF,8'h00, 0,1,0, 2'b11, 4'd9, {8'h00,8'h7F}, tc_num+1, "SHR_A 0xFF>>1=0x7F");
    apply_chk_res(8'h01,8'h00, 0,1,0, 2'b11, 4'd9, {8'h00,8'h00}, tc_num+1, "SHR_A 0x01>>1=0x00 (LSB lost)");

    // ----- CMD 10 : SHL_B (OPB << 1) -----
    $display("-- CMD10: SHL_B --");
    apply_chk_res(8'h00,8'h01, 0,1,0, 2'b11, 4'd10, {8'h00,8'h02}, tc_num+1, "SHL_B 0x01<<1=0x02");
    apply_chk_res(8'h00,8'hAA, 0,1,0, 2'b10, 4'd10, {8'h00,8'h54}, tc_num+1, "SHL_B 0xAA<<1=0x54 (INP_VALID=2)");
    apply_chk_res(8'h00,8'hFF, 0,1,0, 2'b11, 4'd10, {8'h00,8'hFE}, tc_num+1, "SHL_B 0xFF<<1=0xFE");

    // ----- CMD 11 : SHR_B (OPB >> 1) -----
    $display("-- CMD11: SHR_B --");
    apply_chk_res(8'h00,8'hAA, 0,1,0, 2'b11, 4'd11, {8'h00,8'h55}, tc_num+1, "SHR_B 0xAA>>1=0x55");
    apply_chk_res(8'h00,8'hFF, 0,1,0, 2'b10, 4'd11, {8'h00,8'h7F}, tc_num+1, "SHR_B 0xFF>>1=0x7F (INP_VALID=2)");
    apply_chk_res(8'h00,8'h01, 0,1,0, 2'b11, 4'd11, {8'h00,8'h00}, tc_num+1, "SHR_B 0x01>>1=0x00");

    // ----- CMD 12 : Rotate Right OPA by OPB[2:0] -----
    $display("-- CMD12: ROTR --");
    // Rotate by 0 (no change)
    set_inp(8'hF0,8'h00, 0,1,0, 2'b11, 4'd12); tick;
    chk_res({8'h00,8'hF0}, tc_num+1, "ROTR 0xF0 by 0 = 0xF0");
    chk_err(1'b0,          tc_num+1, "ROTR by 0: ERR=0");

    // Rotate by 1:  0xF0=11110000 -> 01111000=0x78
    set_inp(8'hF0,8'h01, 0,1,0, 2'b11, 4'd12); tick;
    chk_res({8'h00,8'h78}, tc_num+1, "ROTR 0xF0 by 1 = 0x78");
    chk_err(1'b0,          tc_num+1, "ROTR by 1: ERR=0");

    // Rotate by 2:  0xF0=11110000 -> 00111100=0x3C
    set_inp(8'hF0,8'h02, 0,1,0, 2'b11, 4'd12); tick;
    chk_res({8'h00,8'h3C}, tc_num+1, "ROTR 0xF0 by 2 = 0x3C");

    // Rotate by 4:  0xF0 -> 0x0F
    set_inp(8'hF0,8'h04, 0,1,0, 2'b11, 4'd12); tick;
    chk_res({8'h00,8'h0F}, tc_num+1, "ROTR 0xF0 by 4 = 0x0F");
    chk_err(1'b0,          tc_num+1, "ROTR by 4: ERR=0");

    // Rotate by 7:  0xF0 -> 0xE1
    set_inp(8'hF0,8'h07, 0,1,0, 2'b11, 4'd12); tick;
    chk_res({8'h00,8'hE1}, tc_num+1, "ROTR 0xF0 by 7 = 0xE1");

    // LSB wraps to MSB
    set_inp(8'h01,8'h01, 0,1,0, 2'b11, 4'd12); tick;
    chk_res({8'h00,8'h80}, tc_num+1, "ROTR 0x01 by 1 = 0x80");

    // ERR: OPB[7:4] != 0
    set_inp(8'hF0,8'h10, 0,1,0, 2'b11, 4'd12); tick;
    chk_err(1'b1,          tc_num+1, "ROTR OPB=0x10: OPB[7:4]!=0 -> ERR=1");

    // ERR: OPB[3]=1, OPB[7:4]=0  (BUG-10: RTL will give ERR=0, should be ERR=1)
    set_inp(8'hF0,8'h08, 0,1,0, 2'b11, 4'd12); tick;
    chk_err(1'b1,          tc_num+1, "ROTR OPB=0x08: OPB[3]=1 -> ERR=1 (BUG-10)");

    // INP_VALID=1 also valid for CMD12
    set_inp(8'hAA,8'h02, 0,1,0, 2'b01, 4'd12); tick;
    chk_res({8'h00,8'hA2 /* 10100010 */}, tc_num+1, "ROTR 0xAA by 2 (INP_VALID=1)");

    // ----- CMD 13 : Rotate Left OPA by OPB[2:0] -----
    $display("-- CMD13: ROTL --");
    // Rotate by 0 (no change)
    set_inp(8'h0F,8'h00, 0,1,0, 2'b11, 4'd13); tick;
    chk_res({8'h00,8'h0F}, tc_num+1, "ROTL 0x0F by 0 = 0x0F");
    chk_err(1'b0,          tc_num+1, "ROTL by 0: ERR=0");

    // Rotate by 1:  0x0F=00001111 -> 00011110=0x1E
    set_inp(8'h0F,8'h01, 0,1,0, 2'b11, 4'd13); tick;
    chk_res({8'h00,8'h1E}, tc_num+1, "ROTL 0x0F by 1 = 0x1E");

    // Rotate by 4:  0x0F -> 0xF0
    set_inp(8'h0F,8'h04, 0,1,0, 2'b11, 4'd13); tick;
    chk_res({8'h00,8'hF0}, tc_num+1, "ROTL 0x0F by 4 = 0xF0");
    chk_err(1'b0,          tc_num+1, "ROTL by 4: ERR=0");

    // MSB wraps to LSB
    set_inp(8'h80,8'h01, 0,1,0, 2'b11, 4'd13); tick;
    chk_res({8'h00,8'h01}, tc_num+1, "ROTL 0x80 by 1 = 0x01");

    // Rotate by 7:  0x0F -> 0x87 (same as ROTR by 1)
    set_inp(8'h0F,8'h07, 0,1,0, 2'b11, 4'd13); tick;
    chk_res({8'h00,8'h87}, tc_num+1, "ROTL 0x0F by 7 = 0x87");

    // Rotate by 3:  0xAA=10101010 -> 01010101|1 -> 01010101 wait
    // 0xAA rotl 3: {OPA[4:0],OPA[7:5]} = {10101,010} = 10101010... let me recalculate
    // 0xAA = 10101010, rotl 3 = take top 3 bits (101) append to bottom, rest shift up
    // new bits 7:3 = OPA[4:0] = 01010, new bits 2:0 = OPA[7:5] = 101
    // Result = 01010101 = 0x55
    set_inp(8'hAA,8'h03, 0,1,0, 2'b11, 4'd13); tick;
    chk_res({8'h00,8'h55}, tc_num+1, "ROTL 0xAA by 3 = 0x55");

    // ERR: OPB[7:4] != 0
    set_inp(8'h0F,8'h10, 0,1,0, 2'b11, 4'd13); tick;
    chk_err(1'b1,          tc_num+1, "ROTL OPB=0x10: OPB[7:4]!=0 -> ERR=1");

    // ERR: OPB[3]=1  (BUG-10)
    set_inp(8'h0F,8'h08, 0,1,0, 2'b11, 4'd13); tick;
    chk_err(1'b1,          tc_num+1, "ROTL OPB=0x08: OPB[3]=1 -> ERR=1 (BUG-10)");

    // INP_VALID=1 also valid for CMD13
    set_inp(8'h80,8'h04, 0,1,0, 2'b01, 4'd13); tick;
    chk_res({8'h00,8'h08}, tc_num+1, "ROTL 0x80 by 4 = 0x08 (INP_VALID=1)");

    // ============================================================
    $display("\n=== SECTION 4: Boundary / Corner Cases ===");
    // ============================================================

    // All zeros
    apply_chk_res(8'h00,8'h00, 0,1,0, 2'b11, 4'd4, {8'h00,8'hFF}, tc_num+1, "CORNER: AND all-0 inputs");
    apply_chk_res(8'hFF,8'hFF, 0,1,0, 2'b11, 4'd2, {8'h00,8'hFF}, tc_num+1, "CORNER: OR all-1 inputs");

    // Mode switch: arithmetic -> logic -> arithmetic
    set_inp(8'h0A,8'h05, 0,1,1, 2'b11, 4'd0); tick;
    chk_res(16'h000F, tc_num+1, "SWITCH: MODE1 ADD 10+5=15");
    set_inp(8'h0A,8'h05, 0,1,0, 2'b11, 4'd0); tick;
    chk_res({8'h00,8'h00}, tc_num+1, "SWITCH: MODE0 AND 10&5=0");
    set_inp(8'h0A,8'h05, 0,1,1, 2'b11, 4'd0); tick;
    chk_res(16'h000F, tc_num+1, "SWITCH: back to MODE1 ADD 10+5=15");

    // RST during operation
    set_inp(8'hFF,8'hFF, 0,1,1, 2'b11, 4'd0);
    tick;  // perform ADD
    RST=1; @(posedge CLK); #1;
    tc_num=tc_num+1;
    if (RES!==ZZ) begin
        $display("[FAIL] TC%0d RST mid-op: RES should be z, got=%04h", tc_num, RES);
        fail_cnt=fail_cnt+1;
    end else begin
        $display("[PASS] TC%0d RST mid-op clears outputs", tc_num);
        pass_cnt=pass_cnt+1;
    end
    RST=0; @(posedge CLK); #1;

    // CE toggling
    set_inp(8'h03,8'h04, 0,1,1, 2'b11, 4'd0); tick;  // ADD -> 7
    chk_res(16'h0007, tc_num+1, "CE_TOG: CE=1 ADD 3+4=7");
    set_inp(8'h03,8'h04, 0,0,1, 2'b11, 4'd0); tick;  // CE=0
    chk_res(ZZ, tc_num+1, "CE_TOG: CE=0 -> z");
    set_inp(8'h03,8'h04, 0,1,1, 2'b11, 4'd0); tick;  // CE=1 again
    chk_res(16'h0007, tc_num+1, "CE_TOG: CE=1 ADD 3+4=7 again");

    // ============================================================
    $display("\n==============================================");
    $display(" RESULTS: %0d PASSED  |  %0d FAILED  |  %0d TOTAL",
             pass_cnt, fail_cnt, tc_num);
    $display("==============================================\n");

    if (fail_cnt == 0)
        $display("*** ALL TESTS PASSED ***\n");
    else begin
        $display("*** %0d TEST(s) FAILED — see above for details ***", fail_cnt);
        $display("    Failures annotated with (BUG-N) match the bug review.\n");
    end

    $finish;
end

endmodule
