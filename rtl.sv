module alu_rtl #(parameter width = 8, parameter cmd_width = 4)(CLK, RST, INP_VALID, MODE, CMD, CE, OPA, OPB, CIN, ERR, RES, OFLOW, COUT, G, L, E);

input [width-1:0] OPA, OPB;
input CLK, RST, CIN, CE, MODE;
input [1:0] INP_VALID;
input [cmd_width-1:0] CMD;

output reg [2*width-1:0] RES = 'bz;
output reg OFLOW = 'bz;
output reg COUT = 'bz;
output reg G = 'bz;
output reg L = 'bz;
output reg E = 'bz;
output reg ERR = 'bz;

reg signed [width-1:0] IA, IB;
reg signed [2*width-1:0] TMP_OP;
reg [1:0] cnt = 0;
reg [width-1:0] opa,opb;
reg cout, oflow, err, g, l, e;
assign IA = $signed(OPA);
assign IB = $signed(OPB);

always@(posedge CLK or posedge RST) begin
	if(RST)begin
		RES <= 'bz;
        	COUT <= 1'bz;
        	OFLOW <= 1'bz;
        	G <= 1'bz;
        	E <= 1'bz;
        	L <= 1'bz;
        	ERR <= 1'bz;
	end
	else begin
		if(CE) begin
			if(MODE) begin
				case(CMD)
					'd0: begin
						if(INP_VALID == 'd3) begin
							TMP_OP <= OPA + OPB;
							cout  <= (({1'b0, OPA} + {1'b0, OPB}) >> width) & 1'b1;
							oflow <= 'b0;
							RES <= TMP_OP;
							COUT <= cout;
							OFLOW <= oflow;
						end
						else begin
                					err <= 1'b1;
							ERR <= err;
						end			
					end	
					'd1: begin
						if(INP_VALID == 'd3) begin
							TMP_OP <= OPA - OPB;
							oflow <= (OPA < OPB) ? 1:0;
							cout <= 'b0;
							RES <= TMP_OP;
							OFLOW <= oflow;
							COUT <= cout;
						end
						else begin
                					err <= 1'b1;
							ERR <= err;
						end				
					end
					'd2: begin
						if(INP_VALID == 'd3) begin
							TMP_OP <= OPA + OPB + CIN;
							cout  <= (({1'b0, OPA} + {1'b0, OPB}) >> width) & 1'b1;
							RES <= TMP_OP;
							COUT <= cout;
						end
						else begin
                					err <= 1'b1;
							ERR <= err;
						end				
					end
					'd3: begin
						if(INP_VALID == 'd3) begin
							TMP_OP <= OPA - OPB - CIN;
							oflow <= (OPA <= OPB) ? 1:0;
							RES <= TMP_OP;
							OFLOW <= oflow;
						end
						else begin
                					err <= 1'b1;
							ERR <= err;
						end				
					end
					'd4: begin
						if(INP_VALID == 'd3 || INP_VALID == 'd1) begin
							TMP_OP <= OPA + 1;
							RES <= TMP_OP;
						end
						else begin
                					err <= 1'b1;
							ERR <= err;
						end				
					end
					'd5: begin
						if(INP_VALID == 'd3 || INP_VALID == 'd1) begin
							TMP_OP <= OPA - 1;
							RES <= TMP_OP;
						end
						else begin
                					err <= 1'b1;
							ERR <= err;
						end				
					end
					'd6: begin
						if(INP_VALID == 'd3 || INP_VALID == 'd2) begin
							TMP_OP <= OPB + 1;
							RES <= TMP_OP;
						end
						else begin
                					err <= 1'b1;
							ERR <= err; 
						end				
					end
					'd7: begin
						if(INP_VALID == 'd3 || INP_VALID == 'd2) begin
							TMP_OP <= OPB - 1;
							RES <= TMP_OP;
						end
						else begin
                					err <= 1'b1;
							ERR <= err;
						end				
					end
					'd8: begin
						RES = 'bz;
						if(INP_VALID == 'd3) begin
							if(OPA==OPB) begin
               							e<= 1'b1;
               							g<=1'bz;
               							l<=1'bz;
             						end
            						else if(OPA>OPB) begin
               							e<=1'bz;
               							g<=1'b1;
               							l<=1'bz;
             						end
            						else if(OPA < OPB)begin
               							e<=1'bz;
               							g<=1'bz;
               							l<=1'b1;
             						end
							else begin
								e <= 1'bz;
								g <= 1'bz;
								l <= 1'bz;
							end	
						E <= e;
						G <= g;
						L <= L;
						end
						else begin
                					err <= 1'b1;
							ERR <= err;
						end				
					end
					'd9: begin
						if(INP_VALID == 'd3) begin
							if(cnt == 'b0) begin
								opa = OPA + 1;
								opb = OPB + 1;
								cnt <= cnt+1;
								TMP_OP <= opa * opb;
							end
							else if(cnt < 2) begin 	
								RES <= 'b0;
								cnt <= cnt + 1;
							end
							else if(cnt >= 2) begin
								cnt <= 0;
								RES <= TMP_OP;
							end
							else
								cnt <= 0;
						end
						else begin
							if(cnt < 2) begin 	
								cnt <= cnt + 1;
								ERR <= 'b0;	
							end
							else if(cnt >= 2) begin
								cnt <= 'b0;
								ERR <= 'b1;
							end
							else
								cnt <= 0;
                					 
						end				
					end
					'd10: begin
						if(INP_VALID == 'd3) begin
							if(cnt == 'b0) begin
								opa = OPA<<1;
								opb = OPB;
								cnt <= cnt + 1;
								TMP_OP <= opa*opb;
							end
							else if(cnt < 2) begin 	
								cnt <= cnt + 1;
								RES <= 'b0;
							end
							else if(cnt >= 2) begin
								cnt <= 0;
								RES <= TMP_OP;
							end 
							else
								cnt <= 0;
						end
						else begin
							if(cnt < 2) begin 	
								cnt <= cnt + 1;
								ERR <= 'b0;	
							end
							else if(cnt >= 2) begin
								cnt <= 'b0;
								ERR <= 'b1;
							end
							else
								cnt <= 0;
						end				
					end
					'd11: begin
						if(INP_VALID == 'd3) begin
						COUT <= 'b0;
						TMP_OP <= IA + IB;
						oflow <= (~(IA[width-1] ^ IB[width-1])) & (TMP_OP[width-1] ^ IA[width-1]);
						RES <= TMP_OP;
						OFLOW <= oflow;
							if(IA==IB) begin
               							e<=1'b1;
               							g<=1'bz;
               							l<=1'bz;
             						end
            						else if(IA>IB) begin
               							e<=1'bz;
               							g<=1'b1;
               							l<=1'bz;
             						end
            						else if(IA < IB)begin
               							e<=1'bz;
               							g<=1'bz;
               							l<=1'b1;
             						end
							else begin
								e <= 1'bz;
								g <= 1'bz;
								l <= 1'bz;
							end	
						E <= e;
						G <= G;
						L <= L;
						end
						else begin
                					err <= 1'b1;
							ERR <= err;
						end				
					end
					'd12: begin
						if(INP_VALID == 'd3) begin
						cout <= 'b0;
						COUT <= cout;
						TMP_OP <= IA - IB;
						oflow <= (IA[width-1]^IB[width-1]) & (TMP_OP[width-1]^IA[width-1]);
						OFLOW <= oflow;
						RES <= TMP_OP;
						
							if(IA==IB) begin
               							e<=1'b1;
               							g<=1'bz;
               							l<=1'bz;
             						end
            						else if(IA>IB) begin
               							e<=1'bz;
               							g<=1'b1;
               							l<=1'bz;
             						end
            						else if(IA < IB)begin
               							e<=1'bz;
               							g<=1'bz;
               							l<=1'b1;
             						end
							else begin
								e <= 1'bz;
								g <= 1'bz;
								l <= 1'bz;
							end	
						E <= e;
						G <= G;
						L <= l;
						end
						else begin
                					err <= 1'b1;
							ERR <= err;
							
						end				
					end
					default: begin
						 	 TMP_OP <= 'b0;  RES <= TMP_OP;
                                                         cout <= 1'bz;	COUT <= cout;
                                                         oflow <= 1'bz;	OFLOW <= oflow;
                                                         g <= 1'bz;	G <= g;
                                                         e <= 1'bz;	E <= e;
                                                         l <= 1'bz;	L <= l;
                                                         err <= 1'b0;	ERR <= err;
					end	
				endcase
			
			end
			else if(!MODE)
				COUT <= cout;
				OFLOW <= oflow;
				G <= g;
				E <= e;
				L <= l;
				ERR <= err;
				case(CMD)
					'd0: begin
						if(INP_VALID == 'd3) begin
							TMP_OP <= {{width{1'b0}},(OPA & OPB)};
							RES <= TMP_OP;
						end
						else begin
                                                         err <= 1'b1;
						end
					end
					'd1: begin
						if(INP_VALID == 'd3) begin
							TMP_OP <= {{width{1'b0}},~(OPA & OPB)};
							RES <= TMP_OP;
						end
						else begin
                                                         err <= 1'b1;
						end
					end
					'd2: begin
						if(INP_VALID == 'd3) begin
							TMP_OP <= {{width{1'b0}},(OPA | OPB)};
							RES <= TMP_OP;
						end
						else begin
                                                         err <= 1'b1;
						end
					end
					'd3: begin
						if(INP_VALID == 'd3) begin
							TMP_OP <= {{width{1'b0}},~(OPA | OPB)};
							RES <= TMP_OP;
						end
						else begin
                                                         err <= 1'b1;
						end
					end
					'd4: begin
						if(INP_VALID == 'd3) begin
							TMP_OP <= {{width{1'b0}},(OPA ^ OPB)};
							RES <= TMP_OP;
						end
						else begin
                                                         err <= 1'b1;
						end
					end
					'd5: begin
						if(INP_VALID == 'd3) begin
							TMP_OP <= {{width{1'b0}},~(OPA ^ OPB)};
							RES <= TMP_OP;
						end
						else begin
                                                         err <= 1'b1;
						end
					end
					'd6: begin
						if(INP_VALID == 'd3 || INP_VALID == 'd1) begin
							TMP_OP <= {{width{1'b0}},~(OPA)};
							RES <= TMP_OP;
						end
						else begin
                                                         err <= 1'b1;
						end
					end
					'd7: begin
						if(INP_VALID == 'd3 || INP_VALID == 'd2) begin
							TMP_OP <= {{width{1'b0}},~(OPB)};
							RES <= TMP_OP;
						end
						else begin
                                                         err <= 1'b1;
						end
					end
					'd8: begin
						if(INP_VALID == 'd3 || INP_VALID == 'd1) begin
							TMP_OP <= {{width{1'b0}},(OPA<<1)};
							RES <= TMP_OP;
						end
						else begin
                                                         err <= 1'b1;
						end
					end
					'd9: begin
						if(INP_VALID == 'd3 || INP_VALID == 'd1) begin
							TMP_OP <= {{width{1'b0}},(OPA>>1)};
							RES <= TMP_OP;
						end
						else begin
                                                         err <= 1'b1;
						end
					end
					'd10: begin
						if(INP_VALID == 'd3 || INP_VALID == 'd2) begin
							TMP_OP <= {{width{1'b0}},(OPB<<1)};
							RES <= TMP_OP;
						end
						else begin
                                                         err <= 1'b1;
						end
					end
					'd11: begin
						if(INP_VALID == 'd3 || INP_VALID == 'd2) begin
							TMP_OP <= {{width{1'b0}},(OPB>>1)};
							RES <= TMP_OP;
						end
						else begin
                                                         err <= 1'b1;
						end
					end
					'd12: begin
						if(INP_VALID == 'd3 || INP_VALID == 'd1) begin
							case(OPB[2:0])
								'd0: TMP_OP <= {{width{1'b0}},OPA[7:0]};
								'd1: TMP_OP <= {{width{1'b0}},{OPA[0],OPA[7:1]}};
								'd2: TMP_OP <= {{width{1'b0}},{OPA[1:0],OPA[7:2]}};
								'd3: TMP_OP <= {{width{1'b0}},{OPA[2:0],OPA[7:3]}};
								'd4: TMP_OP <= {{width{1'b0}},{OPA[3:0],OPA[7:4]}};
								'd5: TMP_OP <= {{width{1'b0}},{OPA[4:0],OPA[7:5]}};
								'd6: TMP_OP <= {{width{1'b0}},{OPA[5:0],OPA[7:6]}};
								'd7: TMP_OP <= {{width{1'b0}},{OPA[6:0],OPA[7]}};
							endcase	 
							RES <= TMP_OP;
							if(|OPB[7:4])
								err <= 'b1;
							else
								err <= 'b0;
						end
						else begin
                                                         err <= 1'b1;
						end
					end
					'd13: begin
						if(INP_VALID == 'd3 || INP_VALID == 'd1) begin
							case(OPB[2:0])
								'd0: TMP_OP <= {{width{1'b0}},OPA[7:0]};
								'd1: TMP_OP <= {{width{1'b0}},{OPA[6:0],OPA[7]}};
								'd2: TMP_OP <= {{width{1'b0}},{OPA[5:0],OPA[7:6]}};
								'd3: TMP_OP <= {{width{1'b0}},{OPA[4:0],OPA[7:5]}};
								'd4: TMP_OP <= {{width{1'b0}},{OPA[3:0],OPA[7:4]}};
								'd5: TMP_OP <= {{width{1'b0}},{OPA[2:0],OPA[7:3]}};
								'd6: TMP_OP <= {{width{1'b0}},{OPA[1:0],OPA[7:2]}};
								'd7: TMP_OP <= {{width{1'b0}},{OPA[0],OPA[7:1]}};
							endcase	 
							RES <= TMP_OP;
							if(|OPB[7:4])
								err <= 'b1;
							else
								err <= 'b0;
						end
						else begin
                                                         err <= 1'b1;
						end
					end
					default: begin
                                                         ers <= 'bz;
                                                         cout <= 1'bz;
                                                         oflow <= 1'bz;
                                                         g <= 1'bz;
                                                         e <= 1'bz;
                                                         l <= 1'bz;
                                                         err <= 1'bz;
                                                end
					endcase
		end
		else begin
			RES <= 'bz;
                	COUT <= 1'bz;
                	OFLOW <= 1'bz;
                	G <= 1'bz;
                	E <= 1'bz;
                	L <= 1'bz;
                	ERR <= 1'bz;
		end
	end

end
endmodule
