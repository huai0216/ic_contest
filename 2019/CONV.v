
`timescale 1ns/10ps

module  CONV(
	input		clk,
	input		reset,
	output reg busy,	
	input		ready,	
			
	output reg [11:0] iaddr,
	input	[19:0]	idata,	
	
	output reg cwr,
	output reg [11:0] caddr_wr,
	output reg [19:0] cdata_wr,
	
	output reg crd,
	output reg [11:0] caddr_rd,
	input	[19:0] 	cdata_rd,
	
	output reg [2:0] csel
	);

//=================================================
reg [19:0] mem [8:0];
reg [3:0] count;
reg [3:0] curt_state, next_state;
localparam idle_st = 0, L0_ul_st = 1, L0_ur_st = 2, 
		L0_dl_st = 3, L0_dr_st = 4, L0_u_st = 5, 
		L0_d_st = 6, L0_l_st = 7, L0_r_st = 8, L0_mid_st = 9,
		conv_st = 10, relu_st = 11, write_L0_st = 12,
		L1_st = 13, done_st = 14;


wire [39:0] conv0 = $signed(mem[0]) * $signed(20'h0A89E);
wire [39:0] conv1 = $signed(mem[1]) * $signed(20'h092D5);
wire [39:0] conv2 = $signed(mem[2]) * $signed(20'h06D43);
wire [39:0] conv3 = $signed(mem[3]) * $signed(20'h01004);
wire [39:0] conv4 = $signed(mem[4]) * $signed(20'hF8F71);
wire [39:0] conv5 = $signed(mem[5]) * $signed(20'hF6E54);
wire [39:0] conv6 = $signed(mem[6]) * $signed(20'hFA6D7);
wire [39:0] conv7 = $signed(mem[7]) * $signed(20'hFC834);
wire [39:0] conv8 = $signed(mem[8]) * $signed(20'hFAC19);
wire [39:0] conv_sum1 = $signed(conv0)+$signed(conv1)+$signed(conv2)+$signed(conv3)+$signed(conv4)+$signed(conv5)+$signed(conv6)+$signed(conv7)+$signed(conv8)+{{4{1'd0}},20'h01310,16'h0000};
wire [19:0] conv_ans = (conv_sum1[15:0] > 16'h8000)?conv_sum1[35:16]+1:conv_sum1[35:16];
wire ch_fl = (caddr_wr == 63);
reg [5:0] l0_col, l0_row;

	//state register
	always@(posedge clk or posedge reset)begin
		if(reset) curt_state <= idle_st;
		else curt_state <= next_state;
	end
	//next state logic
	always@(*)begin
		case(curt_state)
			idle_st : begin
				case(busy)
					0 : next_state = idle_st;
					1 : next_state = L0_ul_st;
				endcase
			end
			L0_ul_st : begin
				case(count)
					3 : next_state = conv_st;
					default : next_state = L0_ul_st;
				endcase
			end
			L0_u_st : begin
				case(count)
					2 : next_state = conv_st;
					default : next_state = L0_u_st;
				endcase
			end
			L0_ur_st : begin
				case(count)
					2 : next_state = conv_st;
					default : next_state = L0_ur_st;
				endcase
			end
			L0_l_st : begin
				case(count)
					5 : next_state = conv_st;
					default : next_state = L0_l_st;
				endcase
			end
			L0_mid_st : begin
				case(count)
					3 : next_state = conv_st;
					default : next_state = L0_mid_st;
				endcase
			end
			L0_r_st : begin
				case(count)
					3 : next_state = conv_st;
					default : next_state = L0_r_st;
				endcase
			end
			L0_dl_st : begin
				case(count)
					3 : next_state = conv_st;
					default : next_state = L0_dl_st;
				endcase
			end
			L0_d_st : begin
				case(count)
					2 : next_state = conv_st;
					default : next_state = L0_d_st;
				endcase
			end
			L0_dr_st : begin
				case(count)
					2 : next_state = conv_st;
					default : next_state = L0_dr_st;
				endcase
			end
			conv_st : begin
				next_state = relu_st;
			end
			relu_st : begin
				next_state = write_L0_st;
			end
			write_L0_st : begin
				case(l0_row)
					0 : begin
						case(l0_col)
							0 : next_state = L1_st;
							63 : next_state = L0_ur_st;
							default : next_state = L0_u_st;
						endcase
					end
					63 : begin
						case(l0_col)
							0 : next_state = L0_dl_st;
							63 : next_state = L0_dr_st;
							default : next_state = L0_d_st;
						endcase
					end
					default : begin
						case(l0_col)	
							0 : next_state = L0_l_st;
							63 : next_state = L0_r_st;
							default : next_state = L0_mid_st;	
						endcase
					end
				endcase
			end
			L1_st : begin
				case(caddr_wr)
					1024 : next_state = done_st;
					default : next_state = L1_st;
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

	always@(posedge clk or posedge reset)begin
		if(reset)begin
			busy <= 1'd0;
			iaddr <= 12'd0;
			cwr <= 1'd0;
			caddr_wr <= 12'd0;
			cdata_wr <= 20'd0;
			crd <= 1'd0;
			caddr_rd <= 12'd0;
			csel <= 3'd0;
			count <= 4'd0;
			l0_col <= 5'd0;
			l0_row <= 5'd0;
		end
		else begin
			case(curt_state)
				idle_st : begin		//0
					if(ready) busy <= 1;
					
				end
				L0_ul_st : begin	//1
					count <= count + 1;
					case(count)
						0 : begin
							iaddr <= 1;	
							mem[0] <= 0;
							mem[1] <= 0;
							mem[4] <= idata;
						end
						1 : begin
							iaddr <= 64;
							mem[2] <= 0;
							mem[5] <= idata;
						end
						2 : begin
							iaddr <= 65;
							mem[3] <= 0;
							mem[7] <= idata;
						end
						3 : begin
							iaddr <= 2;
							mem[6] <= 0;
							mem[8] <= idata;
						end	
					endcase
				end
				L0_u_st : begin		//5
					count <= count + 1;
					mem[0] <= 20'd0;
					mem[1] <= 20'd0;
					mem[2] <= 20'd0;
					
					case(count)
						0 : iaddr <= iaddr + 64;
						1 : iaddr <= iaddr - 63;
						default : iaddr <= iaddr;
					endcase
					case(count)
						0 : begin
							mem[5] <= idata;
							mem[3] <= mem[4];
							mem[4] <= mem[5];
							mem[6] <= mem[7];	
						end
						1 : mem[8] <= idata;
					endcase					
				end
				L0_ur_st : begin	//2
					count <= count + 1;
					case(count)
						0 : begin
							mem[3] <= mem[4];
							mem[6] <= mem[7];
							mem[4] <= mem[5];
							mem[7] <= mem[8];
						end
						1 : begin
							mem[0] <= 0;
							mem[1] <= 0;
							mem[2] <= 0;
							mem[5] <= 0;
							mem[8] <= 0;
							iaddr <= 0;
						end
					endcase
				end
				L0_l_st : begin		//7
					count <= count + 1;
					case(count)
						0 : begin
							mem[0] <= 0;
							mem[1] <= idata;
							iaddr <= iaddr + 1; 
						end
						1 : begin
							mem[2] <= idata;
							iaddr <= iaddr + 63;
						end
						2 : begin
							mem[3] <= 0;
							mem[4] <= idata;
							iaddr <= iaddr + 1;	
						end
						3 : begin
							mem[5] <= idata;
							iaddr <= iaddr + 63;
						end
						4 : begin
							mem[6] <= 0;
							mem[7] <= idata;
							iaddr <= iaddr + 1;
						end
						5 : begin
							mem[8] <= idata;
							iaddr <= iaddr - 127;
						end
					endcase
				end
				L0_mid_st : begin
					count <= count + 1;
					case(count)
						0 : begin
							mem[0] <= mem[1];
							mem[1] <= mem[2];
							mem[2] <= idata;
							iaddr <= iaddr + 64;
						end
						1 : begin
							mem[3] <= mem[4];
							mem[4] <= mem[5];
							mem[5] <= idata;
							iaddr <= iaddr + 64;
						end
						2 : begin
							mem[6] <= mem[7];
							mem[7] <= mem[8];
							mem[8] <= idata;
							iaddr <= iaddr -127;
						end
					endcase	
				end
				L0_r_st : begin		//8
					count <= count + 1;
					case(count)
						0 : begin
							mem[0] <= mem[1];
							mem[3] <= mem[4];
							mem[6] <= mem[7];
						end
						1 : begin
							mem[1] <= mem[2];
							mem[4] <= mem[5];
							mem[7] <= mem[8];
						end
						2 : begin
							mem[2] <= 0;
							mem[5] <= 0;
							mem[8] <= 0;
						end
					endcase
				end
				L0_dl_st : begin 	//3
					count <= count + 1;
					case(count)
						0 : begin
							mem[0] <= 0;
							mem[1] <= idata;
							iaddr <= iaddr + 1;
						end
						1 : begin
							mem[2] <= idata;
							mem[3] <= 0;
							iaddr <= iaddr + 63;
						end
						2 : begin
							mem[4] <= idata;
							mem[6] <= 0;
							mem[7] <= 0;
							iaddr <= iaddr + 1;
						end
						3 : begin
							mem[5] <= idata;
							mem[8] <= 0;
							iaddr <= iaddr - 63;
						end
					endcase
				end	
				L0_d_st : begin
					count <= count + 1;
					case(count)
						0 : begin
							mem[0] <= mem[1];
							mem[1] <= mem[2];
							mem[2] <= idata;
							iaddr <= iaddr + 64;
						end
						1 : begin
							mem[3] <= mem[4];
							mem[4] <= mem[5];
							mem[5] <= idata;
							iaddr <= iaddr - 63;
						end	
						2 : begin
							mem[6] <= 0;
							mem[7] <= 0;
							mem[8] <= 0;
						end
					endcase	
				end
				L0_dr_st : begin
					count <= count + 1;
					case(count)
						0 : begin
							mem[0] <= mem[1];
							mem[3] <= mem[4];
							mem[6] <= mem[7];
						end	
						1 : begin
							mem[1] <= mem[2];
							mem[4] <= mem[5];
							mem[7] <= mem[8];
						end
						2 : begin
							mem[2] <= 0;
							mem[5] <= 0;
							mem[8] <= 0;
						end
					endcase	
				end
				conv_st : begin		//10
					count <= 0;
					cdata_wr <= conv_ans;	
				end
				relu_st : begin		//11
					cdata_wr <= ($signed(cdata_wr)>0)?cdata_wr:0;
					cwr <= 1;
					csel <= 3'd1;
					case(l0_col)	
						63 : begin 
							l0_row <= l0_row + 1;
							l0_col <= 0;
						end	
						default : l0_col <= l0_col + 1;
					endcase	
				end
				write_L0_st : begin	//12	
					caddr_wr <= {l0_row, l0_col};
					cwr <= 0;
				end
				L1_st : begin
					case(count)
						5 : count <= 0;
						default : count <= count + 1;	
					endcase
					case(count)
						0 : begin
							cdata_wr <= 0;
							cwr <= 0;
							crd <= 1;
							csel <= 3'b001;
						end	
						1 : begin
							caddr_rd <= caddr_rd + 1;
							cdata_wr <= cdata_rd;
						end
						2 : begin
							caddr_rd <= caddr_rd + 63;
							cdata_wr <= ($signed(cdata_wr) > $signed(cdata_rd))?cdata_wr : cdata_rd;
						end
						3 : begin
							caddr_rd <= caddr_rd + 1;
							cdata_wr <= ($signed(cdata_wr) > $signed(cdata_rd))?cdata_wr : cdata_rd;
						end
						4 : begin
							case(caddr_rd[6:0])
								127 : caddr_rd <= caddr_rd + 1;	
								default : caddr_rd <= caddr_rd - 63;
							endcase
							cdata_wr <= ($signed(cdata_wr) > $signed(cdata_rd))?cdata_wr : cdata_rd;
							cwr <= 1;
							crd <= 0;
							csel <= 3'b011;
						end
						5 : begin
							cwr <= 1;
							crd <= 0;
							csel <= 3'b011;
							caddr_wr <= caddr_wr + 1;	
						end	
					endcase
				end
				done_st : begin
					busy <= 0;
				end
			endcase
		end
	end

endmodule




