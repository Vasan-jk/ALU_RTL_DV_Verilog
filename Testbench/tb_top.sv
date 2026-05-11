
module tb_top;

    localparam WIDTH     = 8;
    localparam CMD_WIDTH = 4;

    reg [WIDTH-1:0] OPA, OPB;
    reg             CLK, RST, CE, MODE, CIN;
    reg [3:0]       CMD;
    reg [1:0]       INP_VALID;

    wire [2*WIDTH-1:0] RES_dut;
    wire               COUT_dut, OFLOW_dut, G_dut, E_dut, L_dut, ERR_dut;

    wire [2*WIDTH-1:0] RES_ref;
    wire               COUT_ref, OFLOW_ref, G_ref, E_ref, L_ref, ERR_ref;

    integer pass_count = 0;
    integer fail_count = 0;
    integer test_count = 0;

    Eight_bit_ALU_rtl_design #(.WIDTH(WIDTH)) dut (
        .OPA       (OPA),
        .OPB       (OPB),
        .CIN       (CIN),
        .CLK       (CLK),
        .RST       (RST),
        .CMD       (CMD),
        .INP_VALID (INP_VALID),
        .CE        (CE),
        .MODE      (MODE),
        .COUT      (COUT_dut),
        .OFLOW     (OFLOW_dut),
        .RES       (RES_dut),
        .G         (G_dut),
        .E         (E_dut),
        .L         (L_dut),
        .ERR       (ERR_dut)
    );

    reference_mod #(.width(WIDTH), .cmd_width(CMD_WIDTH)) ref_model (
        .OPA       (OPA),
        .OPB       (OPB),
        .CIN       (CIN),
        .CLK       (CLK),
        .RST       (RST),
        .CMD       (CMD),
        .INP_VALID (INP_VALID),
        .CE        (CE),
        .MODE      (MODE),
        .COUT      (COUT_ref),
        .OFLOW     (OFLOW_ref),
        .RES       (RES_ref),
        .G         (G_ref),
        .E         (E_ref),
        .L         (L_ref),
        .ERR       (ERR_ref)
    );

    initial CLK = 0;
    always  #5 CLK = ~CLK;

    initial begin
        RST = 1; CE = 1; CIN = 0;
        OPA = 0; OPB = 0; MODE = 0; CMD = 0; INP_VALID = 2'b11;
        repeat(2) @(posedge CLK); #1;
	
        RST = 0; CE = 0; CIN = 0;
        OPA = 0; OPB = 0; MODE = 0; CMD = 0; INP_VALID = 2'b11;
        repeat(2) @(posedge CLK); #1;
        
	RST = 1; CE = 1; CIN = 0;
        OPA = 0; OPB = 0; MODE = 0; CMD = 0; INP_VALID = 2'b11;
        repeat(2) @(posedge CLK); #1;
        
	RST = 0;
        @(posedge CLK); #1;

        $display("\n=== Arithmetic Operations (MODE=1) ===");
        MODE = 1;
        test_arithmetic();

        $display("\n=== Logical Operations (MODE=0) ===");
        MODE = 0;
        test_logical();

        $display("\n==========================================");
        $display("  Total : %0d", test_count);
        $display("  PASS  : %0d", pass_count);
        $display("  FAIL  : %0d", fail_count);
        $display("==========================================");
        if (fail_count == 0)
            $display("  *** ALL TESTS PASSED ***");
        else
            $display("  *** %0d TEST(S) FAILED ***", fail_count);
        $display("==========================================\n");

        #50; $finish;
    end

    task apply_test (
        input [WIDTH-1:0] a,
        input [WIDTH-1:0] b,
        input [3:0]       cmd_in,
        input [1:0]       iv,
        input             cin_in,
        input [80*8:1]    tname
    );
        begin
            @(negedge CLK);
            OPA       = a;
            OPB       = b;
            CMD       = cmd_in;
            INP_VALID = iv;
            CIN       = cin_in;

            repeat(2)@(posedge CLK); #2;

            check_and_report(tname, a, b, cmd_in, iv);
        end
    endtask

    task apply_test_mul (
        input [WIDTH-1:0] a,
        input [WIDTH-1:0] b,
        input [3:0]       cmd_in,
        input [1:0]       iv,
        input             cin_in,
        input [80*8:1]    tname
    );
        reg [2*WIDTH-1:0] ref_res_captured;
        reg               ref_err_captured;
        begin
            @(negedge CLK);
            OPA       = a;
            OPB       = b;
            CMD       = cmd_in;
            INP_VALID = iv;
            CIN       = cin_in;

            #1;
            ref_res_captured = RES_ref;
            ref_err_captured = ERR_ref;

            repeat(4) @(posedge CLK); #2;

            test_count = test_count + 1;

            if (RES_dut === ref_res_captured && ERR_dut === ref_err_captured) begin
                $display("[PASS] %-32s OPA=%02h OPB=%02h CMD=%04b IV=%02b",
                         tname, a, b, cmd_in, iv);
                pass_count = pass_count + 1;
            end else begin
                $display("[FAIL] %-32s OPA=%02h OPB=%02h CMD=%04b IV=%02b",
                         tname, a, b, cmd_in, iv);
                $display("  DUT: RES=%0h ERR=%b", RES_dut, ERR_dut);
                $display("  REF: RES=%0h ERR=%b", ref_res_captured, ref_err_captured);
                fail_count = fail_count + 1;
            end
        end
    endtask

    task check_and_report (
        input [80*8:1]    tname,
        input [WIDTH-1:0] a,
        input [WIDTH-1:0] b,
        input [3:0]       cmd_in,
        input [1:0]       iv
    );
        begin
            test_count = test_count + 1;

            if (compare_all()) begin
                $display("[PASS] %-32s OPA=%02h OPB=%02h CMD=%04b IV=%02b",
                         tname, a, b, cmd_in, iv);
                pass_count = pass_count + 1;
            end else begin
                $display("[FAIL] %-32s OPA=%02h OPB=%02h CMD=%04b IV=%02b",
                         tname, a, b, cmd_in, iv);
                display_mismatch();
                fail_count = fail_count + 1;
            end
        end
    endtask

    function compare_all;
        begin
            compare_all = 1;
            if (RES_dut   !== RES_ref)   compare_all = 0;
            if (COUT_dut  !== COUT_ref)  compare_all = 0;
            if (OFLOW_dut !== OFLOW_ref) compare_all = 0;
            if (G_dut     !== G_ref)     compare_all = 0;
            if (E_dut     !== E_ref)     compare_all = 0;
            if (L_dut     !== L_ref)     compare_all = 0;
            if (ERR_dut   !== ERR_ref)   compare_all = 0;
        end
    endfunction

    task display_mismatch;
        begin
            $display("  DUT: RES=%0h COUT=%b OFLOW=%b G=%b E=%b L=%b ERR=%b",
                     RES_dut,  COUT_dut,  OFLOW_dut,
                     G_dut,  E_dut,  L_dut,  ERR_dut);
            $display("  REF: RES=%0h COUT=%b OFLOW=%b G=%b E=%b L=%b ERR=%b",
                     RES_ref,  COUT_ref,  OFLOW_ref,
                     G_ref,  E_ref,  L_ref,  ERR_ref);
        end
    endtask
    task test_arithmetic;
        begin
            apply_test(8'h0F, 8'h11, 4'd0,  2'b11, 0, "addition");
            apply_test(8'hFF, 8'hFF, 4'd0,  2'b11, 0, "addition_max");
            apply_test(8'h00, 8'h00, 4'd0,  2'b11, 0, "addition_zero");
            apply_test(8'hAB, 8'h00, 4'd0,  2'b01, 0, "addition_invalid");
            apply_test(8'hAB, 8'h00, 4'd0,  2'b00, 0, "addition_invalid");
            apply_test(8'hAB, 8'h00, 4'd0,  2'b10, 0, "addition_invalid");

            apply_test(8'h20, 8'h10, 4'd1,  2'b11, 0, "subtraction");
            apply_test(8'h10, 8'h10, 4'd1,  2'b11, 0, "subtraction_same");
            apply_test(8'h10, 8'h30, 4'd1,  2'b11, 0, "subtraction_OPA_less");
            apply_test(8'h10, 8'h00, 4'd1,  2'b11, 0, "subtraction_OPA_0");
            apply_test(8'h00, 8'h30, 4'd1,  2'b11, 0, "subtraction_OPB_0");
            apply_test(8'hAB, 8'h00, 4'd1,  2'b10, 0, "subtraction_invalid");
            apply_test(8'hAB, 8'h00, 4'd1,  2'b00, 0, "subtraction_invalid");
            apply_test(8'hAB, 8'h00, 4'd1,  2'b01, 0, "subtraction_invalid");

            apply_test(8'h10, 8'h20, 4'd2,  2'b11, 1, "addition_cin");
            apply_test(8'h00, 8'h00, 4'd2,  2'b11, 1, "addition_cin_zero");
            apply_test(8'hFF, 8'hFF, 4'd2,  2'b11, 1, "addition_cin_max");
            apply_test(8'h10, 8'h20, 4'd2,  2'b11, 0, "addition_with_cin_zero");
            apply_test(8'h10, 8'h20, 4'd2,  2'b01, 0, "addition_cin_invalid");
            apply_test(8'h10, 8'h20, 4'd2,  2'b00, 0, "addition_cin_invalid");
            apply_test(8'h10, 8'h20, 4'd2,  2'b10, 0, "addition_cin_invalid");
		

            apply_test(8'h10, 8'h10, 4'd3,  2'b11, 1, "subraction_cin_same");
            apply_test(8'h10, 8'h20, 4'd3,  2'b11, 1, "subtraction_cin_OPA_less");
            apply_test(8'h10, 8'h11, 4'd3,  2'b11, 1, "subtraction_cin_OPB_less_by_1");
            apply_test(8'h15, 8'h11, 4'd3,  2'b11, 1, "subtraction_cin");
            apply_test(8'h15, 8'h00, 4'd3,  2'b11, 1, "subtraction_cin_OPB_0");
            apply_test(8'h00, 8'h23, 4'd3,  2'b11, 1, "subtraction_cin_OPA_0");
            apply_test(8'h00, 8'h23, 4'd3,  2'b00, 1, "subtraction_cin_invalid");
            apply_test(8'h00, 8'h23, 4'd3,  2'b01, 1, "subtraction_cin_invalid");
            apply_test(8'h00, 8'h23, 4'd3,  2'b10, 1, "subtraction_cin_invalid");

            apply_test(8'h0A, 8'h00, 4'd4,  2'b01, 0, "increase_OPA");
            apply_test(8'hFF, 8'h00, 4'd4,  2'b01, 0, "increase_OPA_max");
            apply_test(8'h00, 8'h00, 4'd4,  2'b01, 0, "increase_OPA_min");
            apply_test(8'h0A, 8'h00, 4'd4,  2'b11, 0, "increase_OPA_inp_11");
            apply_test(8'h0A, 8'h00, 4'd4,  2'b10, 0, "increase_OPA_invalid");
            apply_test(8'h0A, 8'h00, 4'd4,  2'b00, 0, "increase_OPA_invalid");

            apply_test(8'h0A, 8'h00, 4'd5,  2'b01, 0, "decreases_OPA");
            apply_test(8'hFF, 8'h00, 4'd5,  2'b01, 0, "decreases_OPA_max");
            apply_test(8'h00, 8'h00, 4'd5,  2'b01, 0, "decreases_OPA_min");
            apply_test(8'h0A, 8'h00, 4'd5,  2'b11, 0, "decreases_OPA_inp_11");
            apply_test(8'h0A, 8'h00, 4'd5,  2'b00, 0, "decreases_OPA_invalid");
            apply_test(8'h0A, 8'h00, 4'd5,  2'b10, 0, "decreases_OPA_invalid");

            apply_test(8'h00, 8'h05, 4'd6,  2'b10, 0, "increase_OPB");
            apply_test(8'h00, 8'hFF, 4'd6,  2'b10, 0, "increase_OPB_max");
            apply_test(8'h00, 8'h00, 4'd6,  2'b10, 0, "increase_OPB_min");
            apply_test(8'h00, 8'h05, 4'd6,  2'b11, 0, "increase_OPB_inp_11");
            apply_test(8'h00, 8'h05, 4'd6,  2'b01, 0, "increase_OPB_invalid");
            apply_test(8'h00, 8'h05, 4'd6,  2'b00, 0, "increase_OPB_invalid");

            apply_test(8'h00, 8'h05, 4'd7,  2'b10, 0, "decrease_OPB");
            apply_test(8'h00, 8'h00, 4'd7,  2'b10, 0, "decrease_OPB_min");
            apply_test(8'h00, 8'hFF, 4'd7,  2'b10, 0, "decrease_OPB_max");
            apply_test(8'h00, 8'h05, 4'd7,  2'b11, 0, "decrease_OPB_inp_11");
            apply_test(8'h00, 8'h05, 4'd7,  2'b00, 0, "decrease_OPB_invalid");
            apply_test(8'h00, 8'h05, 4'd7,  2'b01, 0, "decrease_OPB_invalid");

            apply_test(8'h10, 8'h10, 4'd8,  2'b11, 0, "compare_equal");
            apply_test(8'h20, 8'h10, 4'd8,  2'b11, 0, "compare_greater");
            apply_test(8'h10, 8'h20, 4'd8,  2'b11, 0, "compare_lesser");
            apply_test(8'h00, 8'hFF, 4'd8,  2'b11, 0, "compare_min_max");
            apply_test(8'h10, 8'h10, 4'd8,  2'b01, 0, "compare_invalid");

            apply_test_mul(8'h03, 8'h04, 4'd9,  2'b11, 0, "increase_nd_multiply");
            apply_test_mul(8'h00, 8'h00, 4'd9,  2'b11, 0, "increase_nd_multiply_min");
            apply_test_mul(8'hFF, 8'hFF, 4'd9,  2'b11, 0, "increase_nd_multiply_max");
            apply_test_mul(8'h23, 8'h00, 4'd9,  2'b11, 0, "increase_nd_multiply_OPB_0");
            apply_test_mul(8'h00, 8'hFF, 4'd9,  2'b11, 0, "increase_nd_multiply_OPA_0");
            apply_test_mul(8'h0F, 8'h0F, 4'd9,  2'b11, 0, "increase_nd_multiply");
            apply_test_mul(8'h03, 8'h04, 4'd9,  2'b10, 0, "increase_nd_multiply_invalid");
            apply_test_mul(8'h03, 8'h04, 4'd9,  2'b01, 0, "increase_nd_multiply_invalid");
            apply_test_mul(8'h03, 8'h04, 4'd9,  2'b00, 0, "increase_nd_multiply_invalid");

            apply_test_mul(8'h02, 8'h05, 4'd10, 2'b11, 0, "shift_nd_multiply");
            apply_test_mul(8'h00, 8'h05, 4'd10, 2'b11, 0, "shift_nd_multiply_OPA_0");
            apply_test_mul(8'h45, 8'h00, 4'd10, 2'b11, 0, "shift_nd_multiply_OPB_0");
            apply_test_mul(8'h80, 8'h23, 4'd10, 2'b11, 0, "shift_nd_multiply_OPA_MSB");
            apply_test_mul(8'h02, 8'h05, 4'd10, 2'b01, 0, "shift_nd_multiply_invalid");
            apply_test_mul(8'h02, 8'h05, 4'd10, 2'b10, 0, "shift_nd_multiply_invalid");
            apply_test_mul(8'h02, 8'h05, 4'd10, 2'b00, 0, "shift_nd_multiply_invalid");

            apply_test(8'h7F, 8'h01, 4'd11, 2'b11, 0, "signed_add");
            apply_test(8'h2F, 8'h51, 4'd11, 2'b11, 0, "signed_add");
            apply_test(8'h7F, 8'h7F, 4'd11, 2'b11, 0, "signed_add_pos_oflow");
            apply_test(8'h80, 8'h80, 4'd11, 2'b11, 0, "signed_add_neg_oflow");
            apply_test(8'h10, 8'hF0, 4'd11, 2'b11, 0, "signed_add_pos_neg");
            apply_test(8'h7F, 8'h01, 4'd11, 2'b10, 0, "signed_add_invalid");
            apply_test(8'h7F, 8'h01, 4'd11, 2'b00, 0, "signed_add_invalid");
            apply_test(8'h7F, 8'h01, 4'd11, 2'b01, 0, "signed_add_invalid");

            apply_test(8'h7F, 8'hFF, 4'd12, 2'b11, 0, "signed_sub_pos_oflow");
            apply_test(8'h80, 8'h01, 4'd12, 2'b11, 0, "signed_sub_neg_oflow");
            apply_test(8'h20, 8'h10, 4'd12, 2'b11, 0, "signed_sub");
            apply_test(8'h10, 8'h10, 4'd12, 2'b11, 0, "signed_sub_equal");
            apply_test(8'h10, 8'h20, 4'd12, 2'b11, 0, "signed_sub_neg_res");
            apply_test(8'h7F, 8'hFF, 4'd12, 2'b00, 0, "signed_sub_invalid");
            apply_test(8'h7F, 8'hFF, 4'd12, 2'b01, 0, "signed_sub_invalid");
            apply_test(8'h7F, 8'hFF, 4'd12, 2'b10, 0, "signed_sub_invalid");

            apply_test(8'hAA, 8'hBB, 4'd13, 2'b11, 0, "default_err");
            apply_test(8'hAA, 8'hBB, 4'd15, 2'b11, 0, "default_err");
        end
    endtask

    task test_logical;
        begin
            apply_test(8'hF0, 8'h0F, 4'd0,  2'b11, 0, "and_op");
            apply_test(8'hFF, 8'hFF, 4'd0,  2'b11, 0, "and_all_ones");
            apply_test(8'h00, 8'hFF, 4'd0,  2'b11, 0, "and_all_zeros");
            apply_test(8'hF0, 8'h0F, 4'd0,  2'b01, 0, "and_op_invalid");
            apply_test(8'hF0, 8'h0F, 4'd0,  2'b10, 0, "and_op_invalid");
            apply_test(8'hF0, 8'h0F, 4'd0,  2'b00, 0, "and_op_invalid");

            apply_test(8'hF0, 8'h0F, 4'd1,  2'b11, 0, "nand_op");
            apply_test(8'hFF, 8'hFF, 4'd1,  2'b11, 0, "nand_all_ones");
            apply_test(8'hF0, 8'h0F, 4'd1,  2'b10, 0, "nand_op_invalid");
            apply_test(8'hF0, 8'h0F, 4'd1,  2'b01, 0, "nand_op_invalid");
            apply_test(8'hF0, 8'h0F, 4'd1,  2'b00, 0, "nand_op_invalid");

            apply_test(8'hF0, 8'h0F, 4'd2,  2'b11, 0, "or_op");
            apply_test(8'h00, 8'h00, 4'd2,  2'b11, 0, "or_op_all_zero");
            apply_test(8'hF0, 8'h0F, 4'd2,  2'b00, 0, "or_op_invalid");
            apply_test(8'hF0, 8'h0F, 4'd2,  2'b01, 0, "or_op_invalid");
            apply_test(8'hF0, 8'h0F, 4'd2,  2'b10, 0, "or_op_invalid");

            apply_test(8'hF0, 8'h0F, 4'd3,  2'b11, 0, "nor_op");
            apply_test(8'h00, 8'h00, 4'd3,  2'b11, 0, "nor_op_all_zero");
            apply_test(8'hF0, 8'h0F, 4'd3,  2'b01, 0, "nor_op_invalid");
            apply_test(8'hF0, 8'h0F, 4'd3,  2'b00, 0, "nor_op_invalid");
            apply_test(8'hF0, 8'h0F, 4'd3,  2'b10, 0, "nor_op_invalid");

            apply_test(8'hAA, 8'h55, 4'd4,  2'b11, 0, "xor_op");
            apply_test(8'hFF, 8'hFF, 4'd4,  2'b11, 0, "xor_op_all_zero");
            apply_test(8'hAA, 8'h55, 4'd4,  2'b10, 0, "xor_op_invalid");
            apply_test(8'hAA, 8'h55, 4'd4,  2'b00, 0, "xor_op_invalid");
            apply_test(8'hAA, 8'h55, 4'd4,  2'b01, 0, "xor_op_invalid");

            apply_test(8'hAA, 8'h55, 4'd5,  2'b11, 0, "xnor_op");
            apply_test(8'hFF, 8'hFF, 4'd5,  2'b11, 0, "xnor_op_all_ones");
            apply_test(8'hAA, 8'h55, 4'd5,  2'b00, 0, "xnor_op_invalid");
            apply_test(8'hAA, 8'h55, 4'd5,  2'b01, 0, "xnor_op_invalid");
            apply_test(8'hAA, 8'h55, 4'd5,  2'b10, 0, "xnor_op_invalid");

            apply_test(8'hF0, 8'h00, 4'd6,  2'b01, 0, "not_a_op");
            apply_test(8'hF0, 8'h00, 4'd6,  2'b11, 0, "not_a_inp_11");
            apply_test(8'h00, 8'h00, 4'd6,  2'b01, 0, "not_a_all_zeros");
            apply_test(8'hF0, 8'h00, 4'd6,  2'b10, 0, "not_a_invalid");

            apply_test(8'h00, 8'hF0, 4'd7,  2'b10, 0, "not_b_op");
            apply_test(8'h00, 8'hF0, 4'd7,  2'b11, 0, "not_b_inp_11");
            apply_test(8'h00, 8'h00, 4'd7,  2'b10, 0, "not_b_all_zeros");
            apply_test(8'h00, 8'hF0, 4'd7,  2'b01, 0, "not_b_invalid");

            apply_test(8'hAA, 8'h00, 4'd8,  2'b01, 0, "shr1_a");
            apply_test(8'hAA, 8'h00, 4'd8,  2'b11, 0, "shr1_a_inp_11");
            apply_test(8'h01, 8'h00, 4'd8,  2'b01, 0, "shr1_a_lsb");
            apply_test(8'hAA, 8'h00, 4'd8,  2'b10, 0, "shr1_a_invalid");
            apply_test(8'hAA, 8'h00, 4'd8,  2'b01, 0, "shr1_a_invalid");
            apply_test(8'hAA, 8'h00, 4'd8,  2'b00, 0, "shr1_a_invalid");

            apply_test(8'h55, 8'h00, 4'd9,  2'b01, 0, "shl1_a");
            apply_test(8'h55, 8'h00, 4'd9,  2'b11, 0, "shl1_a_inp_11");
            apply_test(8'h80, 8'h00, 4'd9,  2'b01, 0, "shl1_a_msb");
            apply_test(8'h55, 8'h00, 4'd9,  2'b00, 0, "shl1_a_invalid");

            apply_test(8'h00, 8'hAA, 4'd10, 2'b10, 0, "shr1_b");
            apply_test(8'h00, 8'hAA, 4'd10, 2'b11, 0, "shr1_b_inp_11");
            apply_test(8'h00, 8'h01, 4'd10, 2'b10, 0, "shr1_b_lsb");
            apply_test(8'h00, 8'hAA, 4'd10, 2'b01, 0, "shr1_b_invalid");

            apply_test(8'h00, 8'h55, 4'd11, 2'b10, 0, "shl1_b");
            apply_test(8'h00, 8'h55, 4'd11, 2'b11, 0, "shl1_b_inp_11");
            apply_test(8'h00, 8'h80, 4'd11, 2'b10, 0, "shl1_b_msb");
            apply_test(8'h00, 8'h55, 4'd11, 2'b00, 0, "shl1_b_invalid");


            apply_test(8'hAA, 8'h00, 4'd13, 2'b11, 0, "ror_0");
            apply_test(8'hAA, 8'h01, 4'd13, 2'b11, 0, "ror_1");
            apply_test(8'hAA, 8'h02, 4'd13, 2'b11, 0, "ror_2");
            apply_test(8'hAA, 8'h03, 4'd13, 2'b11, 0, "ror_3");
            apply_test(8'hAA, 8'h04, 4'd13, 2'b11, 0, "ror_4");
            apply_test(8'hAA, 8'h05, 4'd13, 2'b11, 0, "ror_5");
            apply_test(8'hAA, 8'h07, 4'd13, 2'b11, 0, "ror_6");
            apply_test(8'hAA, 8'h07, 4'd13, 2'b11, 0, "ror_7");
            apply_test(8'hAA, 8'h08, 4'd13, 2'b11, 0, "ror_err");
            apply_test(8'hAA, 8'h16, 4'd13, 2'b11, 0, "ror_err");
            apply_test(8'hAA, 8'h35, 4'd13, 2'b11, 0, "ror_err");
            apply_test(8'hAA, 8'h73, 4'd13, 2'b11, 0, "ror_err");
            apply_test(8'hAA, 8'ha5, 4'd13, 2'b11, 0, "ror_err"); 
            apply_test(8'hAA, 8'h02, 4'd13, 2'b01, 0, "ror_invalid");
            apply_test(8'hAA, 8'h02, 4'd13, 2'b10, 0, "ror_invalid");
            apply_test(8'hAA, 8'h02, 4'd13, 2'b00, 0, "ror_invalid");

            apply_test(8'hAA, 8'h00, 4'd12, 2'b11, 0, "rol_0");
            apply_test(8'hAA, 8'h01, 4'd12, 2'b11, 0, "rol_1");
            apply_test(8'hAA, 8'h02, 4'd12, 2'b11, 0, "rol_2");
            apply_test(8'hAA, 8'h03, 4'd12, 2'b11, 0, "rol_3");
            apply_test(8'hAA, 8'h04, 4'd12, 2'b11, 0, "rol_4");
            apply_test(8'hAA, 8'h05, 4'd12, 2'b11, 0, "rol_5");
            apply_test(8'hAA, 8'h07, 4'd12, 2'b11, 0, "rol_6");
            apply_test(8'hAA, 8'h07, 4'd12, 2'b11, 0, "rol_7");
            apply_test(8'hAA, 8'h08, 4'd12, 2'b11, 0, "rol_err");
            apply_test(8'hAA, 8'h16, 4'd12, 2'b11, 0, "rol_err");
            apply_test(8'hAA, 8'h35, 4'd12, 2'b11, 0, "rol_err");
            apply_test(8'hAA, 8'h73, 4'd12, 2'b11, 0, "rol_err");
            apply_test(8'hAA, 8'ha5, 4'd12, 2'b11, 0, "rol_err"); 
            apply_test(8'hAA, 8'h02, 4'd12, 2'b01, 0, "rol_invalid");
            apply_test(8'hAA, 8'h02, 4'd12, 2'b10, 0, "rol_invalid");
            apply_test(8'hAA, 8'h02, 4'd12, 2'b00, 0, "rol_invalid");

            apply_test(8'hAA, 8'hBB, 4'd14, 2'b11, 0, "default_err");
            apply_test(8'hAA, 8'hBB, 4'd15, 2'b11, 0, "default_err");
        end
    endtask

    initial begin
        $dumpfile("alu_test.vcd");
        $dumpvars(0, tb_top);
    end

endmodule
