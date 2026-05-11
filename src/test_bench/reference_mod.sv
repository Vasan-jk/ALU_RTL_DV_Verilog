module reference_mod #(
    parameter width     = 8,
    parameter cmd_width = 4
)(
    CLK, RST, INP_VALID, MODE, CMD, CE,
    OPA, OPB, CIN,
    ERR, RES, OFLOW, COUT, G, L, E
);
    input  [width-1:0]     OPA, OPB;
    input                  CLK, RST, CIN, CE, MODE;
    input  [1:0]           INP_VALID;
    input  [cmd_width-1:0] CMD;
    output reg [2*width-1:0] RES;
    output reg               OFLOW;
    output reg               COUT;
    output reg               G;
    output reg               L;
    output reg               E;
    output reg               ERR;
    wire signed [width-1:0] IA = OPA;
    wire signed [width-1:0] IB = OPB;
    reg signed [2*width-1:0] sres;
    always @(*) begin
        if (RST) begin
            RES   = 'b0;
            OFLOW = 1'b0;
            COUT  = 1'b0;
            G     = 1'b0;
            L     = 1'b0;
            E     = 1'b0;
            ERR   = 1'b0;
        end
        else begin
            RES   = 'b0;
            OFLOW = 1'b0;
            COUT  = 1'b0;
            G     = 1'b0;
            L     = 1'b0;
            E     = 1'b0;
            ERR   = 1'b0;
            sres  = 'b0;
            if (CE) begin
                if (MODE) begin
                    case (CMD)
                        4'd0: begin
                            if (INP_VALID == 2'b11) begin
                               	RES = {1'b0, OPA} + {1'b0, OPB};
				COUT = RES[8]? 1: 0;
                            end
                            else begin
                                RES = 'b0; ERR = 1'b1;
                            end
                        end
                        4'd1: begin
                            if (INP_VALID == 2'b11) begin
                                RES = OPA - OPB;
                                OFLOW          = (OPA < OPB);
                            end
                            else begin
                                RES = 'b0; ERR = 1'b1;
                            end
                        end
                        4'd2: begin
                            if (INP_VALID == 2'b11) begin
                                RES = {1'b0, OPA} + {1'b0, OPB} + {1'b0, CIN};
				COUT = RES[8] ? 1: 0;
                            end
                            else begin
                                RES = 'b0; ERR = 1'b1;
                            end
                        end
                        4'd3: begin
                            if (INP_VALID == 2'b11) begin
                                RES = OPA - OPB - CIN;
                                OFLOW = (OPA < (OPB + CIN));
                            end
                            else begin
                                RES = 'b0; ERR = 1'b1;
                            end
                        end
                        4'd4: begin
                            if (INP_VALID == 2'b01 || INP_VALID == 2'b11)
                                RES = OPA + 1;
                            else begin
                                RES = 'b0; ERR = 1'b1;
                            end
                        end
                        4'd5: begin
                            if (INP_VALID == 2'b01 || INP_VALID == 2'b11)
                                RES = OPA - 1;
                            else begin
                                RES = 'b0; ERR = 1'b1;
                            end
                        end
                        4'd6: begin
                            if (INP_VALID == 2'b10 || INP_VALID == 2'b11)
                                RES = OPB + 1;
                            else begin
                                RES = 'b0; ERR = 1'b1;
                            end
                        end
                        4'd7: begin
                            if (INP_VALID == 2'b10 || INP_VALID == 2'b11)
                                RES = OPB - 1;
                            else begin
                                RES = 'b0; ERR = 1'b1;
                            end
                        end
                        4'd8: begin
                            if (INP_VALID == 2'b11) begin
                                G = (OPA >  OPB);
                                L = (OPA <  OPB);
                                E = (OPA == OPB);
                            end
                            else begin
                                RES = 'b0; ERR = 1'b1;
                            end
                        end
                        4'd9: begin
                            if (INP_VALID == 2'b11)
                                RES = (OPA + 1) * (OPB + 1);
                            else begin
                                RES = 'b0; ERR = 1'b1;
                            end
                        end
                        4'd10: begin
                            if (INP_VALID == 2'b11)
                                RES = (OPA << 1) * OPB;
                            else begin
                                RES = 'b0; ERR = 1'b1;
                            end
                        end
                        4'd11: begin
                            if (INP_VALID == 2'b11) begin
                                sres           = {{width{IA[width-1]}}, IA}
                                               + {{width{IB[width-1]}}, IB};
                                RES[width-1:0] = sres[width-1:0];
                                OFLOW          = (IA[width-1] == IB[width-1]) &&
                                                 (IA[width-1] != sres[width-1]);
                                G = (IA >  IB);
                                L = (IA <  IB);
                                E = (IA == IB);
                            end
                            else begin
                                RES = 'b0; ERR = 1'b1;
                            end
                        end
                        4'd12: begin
                            if (INP_VALID == 2'b11) begin
                                sres           = {{width{IA[width-1]}}, IA}
                                               - {{width{IB[width-1]}}, IB};
                                RES[width-1:0] = sres[width-1:0];
                                OFLOW          = (IA[width-1] != IB[width-1]) &&
                                                 (IA[width-1] != sres[width-1]);
                                G = (IA >  IB);
                                L = (IA <  IB);
                                E = (IA == IB);
                            end
                            else begin
                                RES = 'b0; ERR = 1'b1;
                            end
                        end
                        default: begin
                            RES   = 'b0;
                            COUT  = 1'b0;
                            OFLOW = 1'b0;
                            G     = 1'b0;
                            E     = 1'b0;
                            L     = 1'b0;
                            ERR   = 1'b1;
                        end
                    endcase
                end 
                else begin
                    case (CMD)
                        4'd0: begin
                            if (INP_VALID == 2'b11)
                                RES[width-1:0] = OPA & OPB;
                            else begin
                                RES = 'b0; ERR = 1'b1;
                            end
                        end
                        4'd1: begin
                            if (INP_VALID == 2'b11)
                                RES[width-1:0] = ~(OPA & OPB);
                            else begin
                                RES = 'b0; ERR = 1'b1;
                            end
                        end
                        4'd2: begin
                            if (INP_VALID == 2'b11)
                                RES[width-1:0] = OPA | OPB;
                            else begin
                                RES = 'b0; ERR = 1'b1;
                            end
                        end
                        4'd3: begin
                            if (INP_VALID == 2'b11)
                                RES[width-1:0] = ~(OPA | OPB);
                            else begin
                                RES = 'b0; ERR = 1'b1;
                            end
                        end
                        4'd4: begin
                            if (INP_VALID == 2'b11)
                                RES[width-1:0] = OPA ^ OPB;
                            else begin
                                RES = 'b0; ERR = 1'b1;
                            end
                        end
                        4'd5: begin
                            if (INP_VALID == 2'b11)
                                RES[width-1:0] = ~(OPA ^ OPB);
                            else begin
                                RES = 'b0; ERR = 1'b1;
                            end
                        end
                        4'd6: begin
                            if (INP_VALID == 2'b01 || INP_VALID == 2'b11)
                                RES[width-1:0] = ~OPA;
                            else begin
                                RES = 'b0; ERR = 1'b1;
                            end
                        end
                        4'd7: begin
                            if (INP_VALID == 2'b10 || INP_VALID == 2'b11)
                                RES[width-1:0] = ~OPB;
                            else begin
                                RES = 'b0; ERR = 1'b1;
                            end
                        end
                        4'd8: begin
                            if (INP_VALID == 2'b01 || INP_VALID == 2'b11)
                                RES[width-1:0] = OPA >> 1;
                            else begin
                                RES = 'b0; ERR = 1'b1;
                            end
                        end
                        4'd9: begin
                            if (INP_VALID == 2'b01 || INP_VALID == 2'b11)
                                RES[width-1:0] = OPA << 1;
                            else begin
                                RES = 'b0; ERR = 1'b1;
                            end
                        end
                        4'd10: begin
                            if (INP_VALID == 2'b10 || INP_VALID == 2'b11)
                                RES[width-1:0] = OPB >> 1;
                            else begin
                                RES = 'b0; ERR = 1'b1;
                            end
                        end
                        4'd11: begin
                            if (INP_VALID == 2'b10 || INP_VALID == 2'b11)
                                RES[width-1:0] = OPB << 1;
                            else begin
                                RES = 'b0; ERR = 1'b1;
                            end
                        end
                        4'd12: begin
                            if (INP_VALID == 2'b11) begin
                                RES[width-1:0] = (OPA << OPB[$clog2(width)-1:0])
                                               | (OPA >> (width - OPB[$clog2(width)-1:0]));
                                ERR = |OPB[width-1:$clog2(width)];
                            end
                            else begin
                                RES = 'b0; ERR = 1'b1;
                            end
                        end
                        4'd13: begin
                            if (INP_VALID == 2'b11) begin
                                RES[width-1:0] = (OPA >> OPB[$clog2(width)-1:0])
                                               | (OPA << (width - OPB[$clog2(width)-1:0]));
                                ERR = |OPB[width-1:$clog2(width)];
                            end
                            else begin
                                RES = 'b0; ERR = 1'b1;
                            end
                        end
                        default: begin
                            RES   = 'b0;
                            ERR   = 1'b1;
                            COUT  = 1'b0;
                            OFLOW = 1'b0;
                            G     = 1'b0;
                            E     = 1'b0;
                            L     = 1'b0;
                        end
                    endcase
                end 
            end
        end 
    end 
endmodule
