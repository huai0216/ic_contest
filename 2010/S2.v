module S2(clk,
	  rst,
	  S2_done,
	  RB2_RW,
	  RB2_A,
	  RB2_D,
	  RB2_Q,
	  sen,
	  sd);

input clk, rst;
output S2_done, RB2_RW;
output [2:0] RB2_A;
output [17:0] RB2_D;
input [17:0] RB2_Q;
input sen, sd;

//====================================================
reg S2_done , RB2_RW;
reg [2:0] RB2_A;
reg [17:0] RB2_D;
reg [4:0] count;
reg [3:0] addr_count;
reg [2:0] curt_state, next_state;


localparam idle_st = 0, addr_st = 1, data_st = 2, done_st = 4;

	always@(posedge clk or posedge rst)begin
		if(rst) curt_state <= idle_st;
		else curt_state <= next_state;
	end

	always@(*)begin
		case(curt_state)
			idle_st : begin
				next_state = addr_st;
			end
			addr_st : begin
				case(count)
					0 : next_state = data_st;
					default : next_state = addr_st;
				endcase
			end
			data_st : begin
				case(count)
					0 : begin
						case(addr_count)
							0 : next_state = done_st;
							default : next_state = addr_st;
						endcase
					end
					default : next_state = data_st;
				endcase
			end
			done_st : begin
				next_state = done_st;
			end
			default : begin
				next_state = idle_st;
			end	
		endcase
	end

	always@(posedge clk or posedge rst)begin
		if(rst)begin
			S2_done <= 1'd0;
			RB2_RW <= 1'd1;
			count <= 5'd0;
			RB2_A <= 3'd0;
			RB2_D <= 18'd0;
			addr_count <= 3'd0;
		end
		else begin
			case(curt_state)
				idle_st : begin
					count <= 5'd2;
					addr_count <= 4'd0;
				end
				addr_st : begin
					case(sen)
						0 : begin
							RB2_A[count] <= sd;
							RB2_RW <= 1;
							case(count)
								0 : count <= 17;
								default : count <= count-1;
							endcase
						end
						default : begin
							RB2_A <= ~addr_count;
							RB2_RW <= 0;
							addr_count <= addr_count - 1;
						end
					endcase
				end
				data_st : begin
					case(sen)
						0 : begin
							RB2_RW <= 1;
							RB2_D[count] <= sd;
							RB2_A <= RB2_A;
							case(count)
								0 : count <= 2;
								default: count <= count - 1;
							endcase
						end
						default : begin
							
						end
					endcase
				end
				done_st : begin
					S2_done <= 1;
				end
			endcase
		end
	end

endmodule
