module SET ( clk , rst, en, central, radius, mode, busy, valid, candidate );

input clk, rst;
input en;
input [23:0] central;
input [11:0] radius;
input [1:0] mode;
output reg busy;
output reg valid;
output reg [7:0] candidate;
reg [1:0] curt_state, next_state;	
reg [3:0] x1, x2, y1, y2, r1, r2, xc, yc;
reg [1:0] mode_reg;
reg [6:0] x1s, y1s, r1s, x2s, y2s, r2s;
reg [7:0] h1, h2;

parameter idle_st = 0, process_st = 1, out_st = 2;
	
	//state register
	always@(posedge clk)begin
		if(rst)begin
			curt_state <= idle_st;
		end
		else begin
			curt_state <= next_state;
		end
	end
	
	//next state logic
	always@(*)begin
		case(curt_state)
			idle_st:begin
				if(en)begin
					next_state = process_st;
				end
				else begin
					next_state = idle_st;
				end
			end
			process_st : begin
				if(yc == 4'd8 && xc == 4'd8)begin
					next_state = out_st;
				end
				else begin
					next_state = process_st;
				end
			end
			out_st : begin
				if(valid) next_state = idle_st;
				else next_state = out_st;
			end
			default : begin
				next_state = idle_st;
			end
		endcase
	end

	//datapath
	always@(posedge clk)begin
		if(rst)begin
			busy <= 0;
			valid <= 0;
			candidate <= 0;
			mode_reg <= 0;
			x1 <= 0;
			x2 <= 0;
			y1 <= 0;
			y2 <= 0;
			r1 <= 0;
			r2 <= 0;
			xc <= 1;
			yc <= 1;
		end
		else begin
			case(curt_state)
				idle_st:begin
					busy <= 0;
					valid <= 0;
					candidate <= 0;
					xc <= 1;
					yc <= 1;
					mode_reg <= mode;
					x1 <= central[23:20];
					x2 <= central[15:12];
					y1 <= central[19:16];
					y2 <= central[11:8];
					r1 <= radius[11:8];
					r2 <= radius[7:4];
				end
				process_st : begin
					busy <= 1;
					case(mode_reg)
						2'b00 : begin	//set in a
							if(xc >= 8)begin
								xc <= 1;
								yc <= yc + 1;
							end
							else begin
								xc <= xc + 1;
								yc <= yc;
							end
							if(h1 <= r1s)begin
								candidate <= candidate + 1;
							end
							else begin
								candidate <= candidate;
							end
						end
						2'b01 : begin	//set in a & b
							if(xc >= 8)begin
								xc <= 1;
								yc <= yc + 1;
							end
							else begin
								xc <= xc + 1;
								yc <= yc;
							end
							if(h1 <= r1s && h2 <= r2s)begin
								candidate <= candidate + 1;
							end
							else begin
								candidate <= candidate;
							end
						end
						2'b10 : begin	//set in a | b - a & b
							if(xc >= 8)begin
								xc <= 1;
								yc <= yc + 1;
							end
							else begin
								xc <= xc + 1;
								yc <= yc;
							end
							if(h1 <= r1s && h2 > r2s)begin
								candidate <= candidate + 1;
							end
							else if(h1 >r1s && h2 <= r2s) begin
								candidate <= candidate + 1;
							end
							else begin
								candidate <= candidate;
							end
						end
					endcase
				end
				out_st : begin
					valid <= 1;
				end
			endcase
		end
	end
	
	always@(*)begin
		x1s = (xc-x1) * (xc-x1);
		y1s = (yc-y1) * (yc-y1);
		r1s = r1 * r1;
		h1 = x1s + y1s;
		x2s = (xc-x2) * (xc-x2);
		y2s = (yc-y2) * (yc-y2);
		r2s = r2 * r2;
		h2 = x2s + y2s;
	end

endmodule
