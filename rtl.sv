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
reg signed [2*width:0] TMP_OP;
reg [1:0] cnt = 0;
reg [width-1:0] opa,opb;
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
							RES <= OPA + OPB;
							COUT <= RES[width] ? 1:0;
							OFLOW <= 'b0;
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
					'd1: begin
						if(INP_VALID == 'd3) begin
							RES <= OPA - OPB;
							OFLOW <= (OPA < OPB) ? 1:0;
							COUT <= 'b0;
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
					'd2: begin
						if(INP_VALID == 'd3) begin
							RES <= OPA + OPB + CIN;
							COUT <= RES[width] ? 1:0;
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
					'd3: begin
						if(INP_VALID == 'd3) begin
							RES <= OPA - OPB - CIN;
							OFLOW <= (OPA < OPB) ? 1:0;
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
					'd4: begin
						if(INP_VALID == 'd3 || INP_VALID == 'd1) begin
							RES <= OPA + 1;
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
					'd5: begin
						if(INP_VALID == 'd3 || INP_VALID == 'd1) begin
							RES <= OPA - 1;
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
					'd6: begin
						if(INP_VALID == 'd3 || INP_VALID == 'd2) begin
							RES <= OPB + 1;
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
					'd7: begin
						if(INP_VALID == 'd3 || INP_VALID == 'd2) begin
							RES <= OPB - 1;
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
					'd8: begin
						RES = 'bz;
						if(INP_VALID == 'd3) begin
							if(OPA==OPB) begin
               							E<= 1'b1;
               							G<=1'bz;
               							L<=1'bz;
             						end
            						else if(OPA>OPB) begin
               							E<=1'bz;
               							G<=1'b1;
               							L<=1'bz;
             						end
            						else if(OPA < OPB)begin
               							E<=1'bz;
               							G<=1'bz;
               							L<=1'b1;
             						end
							else begin
								E <= 1'bz;
								G <= 1'bz;
								L <= 1'bz;
							end	
	
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
					'd9: begin
						if(INP_VALID == 'd3) begin
							if(cnt == 'b0) begin
								opa <= OPA;
								opb <= OPB;
							end
							else if(cnt < 2) begin 	
								RES <= 'b0;
								cnt <= cnt + 1;
							end
							else if(cnt >= 2) begin
								RES <= ((opa+1) * (opb+1));
								cnt <= 0;
							end
							else
								cnt <= 0;
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
					'd10: begin
						if(INP_VALID == 'd3) begin
							if(cnt == 'b0) begin
								opa <= OPA;
								opb <= OPB;
							end
							else if(cnt < 2) begin 	
								cnt <= cnt + 1;
								RES <= 'b0;
							end
							else if(cnt >= 2) begin
								RES <= (opa<<1) * (opb);
								cnt <= 0;
							end 
							else
								cnt <= 0;
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
					'd11: begin
						if(INP_VALID == 'd3) begin
						TMP_OP <= IA + IB;
						COUT <= 'b0;
						OFLOW <= (~(IA[width-1]^IB[width-1])) & (TMP_OP[width-1]^IA[width-1]);
						RES <= TMP_OP;
						
							if(IA==IB) begin
               							E<=1'b1;
               							G<=1'bz;
               							L<=1'bz;
             						end
            						else if(IA>IB) begin
               							E<=1'bz;
               							G<=1'b1;
               							L<=1'bz;
             						end
            						else if(IA < IB)begin
               							E<=1'bz;
               							G<=1'bz;
               							L<=1'b1;
             						end
							else begin
								E <= 1'bz;
								G <= 1'bz;
								L <= 1'bz;
							end	
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
					'd12: begin
						if(INP_VALID == 'd3) begin
						TMP_OP <= IA - IB;
						COUT <= 'b0;
						OFLOW <= (~(IA[width-1]^IB[width-1])) & (TMP_OP[width-1]^IA[width-1]);
						RES <= TMP_OP;
						
							if(IA==IB) begin
               							E<=1'b1;
               							G<=1'bz;
               							L<=1'bz;
             						end
            						else if(IA>IB) begin
               							E<=1'bz;
               							G<=1'b1;
               							L<=1'bz;
             						end
            						else if(IA < IB)begin
               							E<=1'bz;
               							G<=1'bz;
               							L<=1'b1;
             						end
							else begin
								E <= 1'bz;
								G <= 1'bz;
								L <= 1'bz;
							end	
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
					default: begin
						 	 RES <= 'bz;
                                                         COUT <= 1'bz;
                                                         OFLOW <= 1'bz;
                                                         G <= 1'bz;
                                                         E <= 1'bz;
                                                         L <= 1'bz;
                                                         ERR <= 1'bz;
					end	
				endcase
			
			end
			else if(!MODE)
				case(CMD)
					'd0: begin
						if(INP_VALID == 'd3) begin
							RES <= {{width{1'b0}},(OPA & OPB)};
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
					'd1: begin
						if(INP_VALID == 'd3) begin
							RES <= {{width{1'b0}},~(OPA & OPB)};
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
					'd2: begin
						if(INP_VALID == 'd3) begin
							RES <= {{width{1'b0}},(OPA | OPB)};
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
					'd3: begin
						if(INP_VALID == 'd3) begin
							RES <= {{width{1'b0}},~(OPA | OPB)};
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
					'd4: begin
						if(INP_VALID == 'd3) begin
							RES <= {{width{1'b0}},(OPA ^ OPB)};
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
					'd5: begin
						if(INP_VALID == 'd3) begin
							RES <= {{width{1'b0}},~(OPA ^ OPB)};
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
					'd6: begin
						if(INP_VALID == 'd3 || INP_VALID == 'd1) begin
							RES <= {{width{1'b0}},~(OPA)};
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
					'd7: begin
						if(INP_VALID == 'd3 || INP_VALID == 'd2) begin
							RES <= {{width{1'b0}},~(OPB)};
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
					'd8: begin
						if(INP_VALID == 'd3 || INP_VALID == 'd1) begin
							RES <= {{width{1'b0}},(OPA<<1)};
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
					'd9: begin
						if(INP_VALID == 'd3 || INP_VALID == 'd1) begin
							RES <= {{width{1'b0}},(OPA>>1)};
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
					'd10: begin
						if(INP_VALID == 'd3 || INP_VALID == 'd2) begin
							RES <= {{width{1'b0}},(OPB<<1)};
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
					'd11: begin
						if(INP_VALID == 'd3 || INP_VALID == 'd2) begin
							RES <= {{width{1'b0}},(OPB>>1)};
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
					'd12: begin
						if(INP_VALID == 'd3 || INP_VALID == 'd1) begin
							case(OPB[2:0])
								'd0: RES <= {{width{1'b0}},OPA[7:0]};
								'd1: RES <= {{width{1'b0}},{OPA[0],OPA[7:1]}};
								'd2: RES <= {{width{1'b0}},{OPA[1:0],OPA[7:2]}};
								'd3: RES <= {{width{1'b0}},{OPA[2:0],OPA[7:3]}};
								'd4: RES <= {{width{1'b0}},{OPA[3:0],OPA[7:4]}};
								'd5: RES <= {{width{1'b0}},{OPA[4:0],OPA[7:5]}};
								'd6: RES <= {{width{1'b0}},{OPA[5:0],OPA[7:6]}};
								'd7: RES <= {{width{1'b0}},{OPA[6:0],OPA[7]}};
							endcase	 
							if(|OPB[7:4])
								ERR <= 'b1;
							else
								ERR <= 'b0;
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
					'd13: begin
						if(INP_VALID == 'd3 || INP_VALID == 'd1) begin
							case(OPB[2:0])
								'd0: RES <= {{width{1'b0}},OPA[7:0]};
								'd1: RES <= {{width{1'b0}},{OPA[6:0],OPA[7]}};
								'd2: RES <= {{width{1'b0}},{OPA[5:0],OPA[7:6]}};
								'd3: RES <= {{width{1'b0}},{OPA[4:0],OPA[7:5]}};
								'd4: RES <= {{width{1'b0}},{OPA[3:0],OPA[7:4]}};
								'd5: RES <= {{width{1'b0}},{OPA[2:0],OPA[7:3]}};
								'd6: RES <= {{width{1'b0}},{OPA[1:0],OPA[7:2]}};
								'd7: RES <= {{width{1'b0}},{OPA[0],OPA[7:1]}};
							endcase	 
							if(|OPB[7:4])
								ERR <= 'b1;
							else
								ERR <= 'b0;
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
					default: begin
                                                         RES <= 'bz;
                                                         COUT <= 1'bz;
                                                         OFLOW <= 1'bz;
                                                         G <= 1'bz;
                                                         E <= 1'bz;
                                                         L <= 1'bz;
                                                         ERR <= 1'bz;
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
