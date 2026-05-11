module Eight_bit_ALU_rtl_design #(parameter WIDTH=4)
(OPA,OPB,CIN,CLK,RST,CMD,INP_VALID,CE,MODE,COUT,OFLOW,RES,G,E,L,ERR);

  input [WIDTH-1:0] OPA,OPB;
  input CLK,RST,CE,MODE,CIN;
  input [3:0] CMD;
  input [1:0] INP_VALID;

  output reg [2*WIDTH-1:0] RES = {(2*WIDTH){1'b0}};
  output reg COUT = 1'b0;
  output reg OFLOW = 1'b0;
  output reg G = 1'b0;
  output reg E = 1'b0;
  output reg L = 1'b0;
  output reg ERR = 1'b0;

localparam SHIFT = $clog2(WIDTH);

  reg [WIDTH-1:0] OPA_m, OPB_m;
  reg [1:0] count=2'b00;
  reg signed [WIDTH:0] temp;

  reg [WIDTH-1:0] OPA_r, OPB_r;
  reg [3:0] CMD_r;
  reg MODE_r, CIN_r;
  reg [1:0] INP_VALID_r;

always@(posedge CLK or posedge RST)
begin
    if(RST)
    begin
        RES <= {(2*WIDTH){1'b0}};
        COUT<=1'b0;
        OFLOW<=1'b0;
        G<=1'b0;
        E<=1'b0;
        L<=1'b0;
        ERR<=1'b0;
    end

    else if (CE)
    begin

        OPA_r       <= OPA;
        OPB_r       <= OPB;
        CMD_r       <= CMD;
        MODE_r      <= MODE;
        CIN_r       <= CIN;
        INP_VALID_r <= INP_VALID;

        if(MODE)
        begin

            COUT<=1'b0;
            OFLOW<=1'b0;
            G<=1'b0;
            E<=1'b0;
            L<=1'b0;
            ERR<=1'b0;

            case(CMD_r)

            4'b0000:
            begin
                if (INP_VALID_r==2'b11)
                begin
                    RES<=OPA_r+OPB_r;
                    {COUT, RES[WIDTH-1:0]} <= {1'b0, OPA_r} + {1'b0, OPB_r};
                end
                else
                    ERR<=1'b1;
            end

            4'b0001:
            begin
                if (INP_VALID_r==2'b11)
                begin
                    OFLOW<=(OPA_r<OPB_r)?1:0;
                    RES<=OPA_r-OPB_r;
                end
                else
                    ERR<=1'b1;
            end

            4'b0010:
            begin
                if (INP_VALID_r==2'b11)
                begin
                    RES<= OPA_r+OPB_r+CIN_r;
                    {COUT, RES[WIDTH-1:0]} <= OPA_r + OPB_r + CIN_r;
                end
                else
                    ERR<=1'b1;
            end

            4'b0011:
            begin
                if (INP_VALID_r==2'b11)
                begin
                    OFLOW<=(OPA_r<OPB_r)?1:0;
                    RES<=OPA_r-OPB_r-CIN_r;
                end
                else
                    ERR<=1'b1;
            end

            4'b0100:
            begin
                if(INP_VALID_r ==2'b01 || INP_VALID_r==2'b11)
                begin
                    RES<=OPA_r+1;
                end
                else
                    ERR<=1'b1;
            end

            4'b0101:
            begin
                if(INP_VALID_r ==2'b01 || INP_VALID_r==2'b11)
                begin
                    RES<=OPA_r-1;
                end
                else
                    ERR<=1'b1;
            end

            4'b0110:
            begin
                if(INP_VALID_r ==2'b10 || INP_VALID_r==2'b11)
                begin
                    RES<=OPB_r+1;
                end
                else
                    ERR<=1'b1;
            end

            4'b0111:
            begin
                if(INP_VALID_r ==2'b10 || INP_VALID_r==2'b11)
                begin
                    RES<=OPB_r-1;
                end
                else
                    ERR<=1'b1;
            end

            4'b1000:
            begin
                if(INP_VALID_r ==2'b11)
                begin
                    if(OPA_r==OPB_r)
                    begin
                        E<=1'b1;
                        G<=1'b0;
                        L<=1'b0;
                    end

                    else if(OPA_r>OPB_r)
                    begin
                        E<=1'b0;
                        G<=1'b1;
                        L<=1'b0;
                    end

                    else
                    begin
                        E<=1'b0;
                        G<=1'b0;
                        L<=1'b1;
                    end
                end

                else
                    ERR<=1'b1;
            end

            4'b1001:
            begin
                if (INP_VALID_r == 2'b11)
                begin
                    case(count)

                    2'd0:
                    begin
                        OPA_m <= OPA_r + 1;
                        OPB_m <= OPB_r + 1;
                        count <= 2'd1;
                    end

                    2'd1:
                    begin
                        RES   <= {2*WIDTH{1'bx}};
                        count <= 2'd2;
                    end

                    2'd2:
                    begin
                        RES   <= OPA_m* OPB_m;
                        count <= 2'd0;
                    end

                    endcase
                end

                else
                begin
                    ERR   <= 1'b1;
                    count <= 0;
                end
            end

            4'b1010:
            begin
                if (INP_VALID_r == 2'd3)
                begin
                    case(count)

                    2'd0:
                    begin
                        OPA_m <= OPA_r << 1;
                        OPB_m <= OPB_r;
                        count <= 2'd1;
                    end

                    2'd1:
                    begin
                        RES   <= {2*WIDTH{1'bx}};
                        count <= 2'd2;
                    end

                    2'd2:
                    begin
                        RES   <= OPA_m * OPB_m;
                        count <= 2'd0;
                    end

                    endcase
                end

                else
                begin
                    ERR   <= 1'b1;
                    count <= 0;
                end
            end

            4'b1011:
            begin
                if (INP_VALID_r == 2'b11)
                begin
                    temp = $signed(OPA_r) + $signed(OPB_r);

                    RES <= temp;

                    OFLOW <= (OPA_r[WIDTH-1] == OPB_r[WIDTH-1]) &&
                              (temp[WIDTH-1] != OPA_r[WIDTH-1]);

                    if ($signed(OPA_r) == $signed(OPB_r))
                    begin
                        E <= 1;
                        G <= 0;
                        L <= 0;
                    end

                    else if ($signed(OPA_r) > $signed(OPB_r))
                    begin
                        E <= 0;
                        G <= 1;
                        L <= 0;
                    end

                    else
                    begin
                        E <= 0;
                        G <= 0;
                        L <= 1;
                    end
                end

                else
                    ERR <= 1;
            end

            4'b1100:
            begin
                if (INP_VALID_r == 2'b11)
                begin
                    temp = $signed(OPA_r) - $signed(OPB_r);

                    RES <= temp;

                    OFLOW <= (OPA_r[WIDTH-1] != OPB_r[WIDTH-1]) &&
                              (temp[WIDTH-1] != OPA_r[WIDTH-1]);

                    if ($signed(OPA_r) == $signed(OPB_r))
                    begin
                        E <= 1;
                        G <= 0;
                        L <= 0;
                    end

                    else if ($signed(OPA_r) > $signed(OPB_r))
                    begin
                        E <= 0;
                        G <= 1;
                        L <= 0;
                    end

                    else
                    begin
                        E <= 0;
                        G <= 0;
                        L <= 1;
                    end
                end

                else
                    ERR <= 1;
            end

            default:
            begin
                RES <= {(2*WIDTH){1'b0}};
                COUT<=1'b0;
                OFLOW<=1'b0;
                G<=1'b0;
                E<=1'b0;
                L<=1'b0;
                ERR<=1'b0;
            end

            endcase
        end

        else
        begin

            RES<='b0;
            COUT<=1'b0;
            OFLOW<=1'b0;
            G<=1'b0;
            E<=1'b0;
            L<=1'b0;
            ERR<=1'b0;

            case(CMD_r)

            4'b0000:
            begin
                if(INP_VALID_r==2'b11)
                    RES <= {{(WIDTH){1'b0}}, (OPA_r & OPB_r)};
                else
                    ERR<=1'b1;
            end

            4'b0001:
            begin
                if(INP_VALID_r==2'b11)
                    RES<={{(WIDTH){1'b0}},~(OPA_r&OPB_r)};
                else
                    ERR<=1'b1;
            end

            4'b0010:
            begin
                if(INP_VALID_r==2'b11)
                    RES<={{(WIDTH){1'b0}},OPA_r|OPB_r};
                else
                    ERR<=1'b1;
            end

            4'b0011:
            begin
                if(INP_VALID_r==2'b11)
                    RES<={{(WIDTH){1'b0}},~(OPA_r|OPB_r)};
                else
                    ERR<=1'b1;
            end

            4'b0100:
            begin
                if(INP_VALID_r==2'b11)
                    RES<={{(WIDTH){1'b0}},OPA_r^OPB_r};
                else
                    ERR<=1'b1;
            end

            4'b0101:
            begin
                if(INP_VALID_r==2'b11)
                    RES<={{(WIDTH){1'b0}},~(OPA_r^OPB_r)};
                else
                    ERR<=1'b1;
            end

            4'b0110:
            begin
                if(INP_VALID_r==2'b01 || INP_VALID_r==2'b11)
                    RES<={{(WIDTH){1'b0}},~OPA_r};
                else
                    ERR<=1'b1;
            end

            4'b0111:
            begin
                if(INP_VALID_r==2'b10 || INP_VALID_r==2'b11)
                    RES<={{(WIDTH){1'b0}},~OPB_r};
                else
                    ERR<=1'b1;
            end

            4'b1000:
            begin
                if(INP_VALID_r==2'b01 || INP_VALID_r==2'b11)
                    RES<={{(WIDTH){1'b0}},OPA_r>>1};
                else
                    ERR<=1'b1;
            end

            4'b1001:
            begin
                if(INP_VALID_r==2'b01 || INP_VALID_r==2'b11)
                    RES<={{(WIDTH){1'b0}},OPA_r<<1};
                else
                    ERR<=1'b1;
            end

            4'b1010:
            begin
                if(INP_VALID_r==2'b10 || INP_VALID_r==2'b11)
                    RES<={{(WIDTH){1'b0}},OPB_r>>1};
                else
                    ERR<=1'b1;
            end

            4'b1011:
            begin
                if(INP_VALID_r==2'b10 || INP_VALID_r==2'b11)
                    RES<={{(WIDTH){1'b0}},OPB_r<<1};
                else
                    ERR<=1'b1;
            end

            4'b1100:
            begin
                if (INP_VALID_r == 2'b11)
                begin
                    if (|OPB_r[WIDTH-1:SHIFT])
                    begin
                        ERR<= 1'b1;
                    end

                    else
                    begin
                        RES <= {{(WIDTH){1'b0}},
                        (OPA_r << OPB_r[SHIFT-1:0]) |
                        (OPA_r >> (WIDTH - OPB_r[SHIFT-1:0]))};
                    end
                end

                else
                begin
                    ERR <= 1'b1;
                end
            end

            4'b1101:
            begin
                if (INP_VALID_r == 2'b11)
                begin
                    if (|OPB_r[WIDTH-1:SHIFT])
                    begin
                        ERR <= 1'b1;
                    end

                    else
                    begin
                        RES <= {{(WIDTH){1'b0}},
                        (OPA_r >> OPB_r[SHIFT-1:0]) |
                        (OPA_r << (WIDTH - OPB_r[SHIFT-1:0]))};
                    end
                end

                else
                begin
                    ERR <= 1'b1;
                end
            end

            default:
            begin
                RES <= {(2*WIDTH){1'b0}};
                COUT<=1'b0;
                OFLOW<=1'b0;
                G<=1'b0;
                E<=1'b0;
                L<=1'b0;
                ERR<=1'b0;
            end

            endcase
        end
    end
end

endmodule

