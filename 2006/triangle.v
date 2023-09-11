module triangle (clk, reset, nt, xi, yi, busy, po, xo, yo);
  input clk, reset, nt;
  input [2:0] xi, yi;
  output reg busy, po;
  output reg [2:0] xo, yo;
  
  reg [2:0] curt_state, next_state;  
  reg [7:0] lside;
  reg [2:0] x1, x2, x3;
  reg [2:0] y1, y2, y3;
  reg [2:0] xc, yc;

  parameter read_st0 = 0, read_st1 = 1, read_st2 = 2,
		mv_r = 3, mv_u = 4, stop = 5;

	always@(posedge clk)begin
		if(reset)begin
			curt_state <= read_st0;
		end
		else begin
			curt_state <= next_state;
		end
	end
	
	always@(*)begin
		case(curt_state)
			read_st0 : begin
				if(nt)begin
					next_state = read_st1;
				end
				else begin
					next_state = read_st0;
				end
			end
			read_st1 : begin
				next_state = read_st2;
			end
			read_st2 : begin
				next_state = mv_r;
			end
			mv_r : begin
				if(lside[7])begin
					next_state = mv_u;
				end
				else begin
					next_state = mv_r;
				end
			end
			mv_u : begin
				if(yc == y3)begin
					next_state = stop;
				end
				else if(lside[7]) begin
					next_state = mv_u;
				end
				else begin
					next_state = mv_r;
				end
			end
			stop : begin
				next_state = read_st0;
			end
			default : begin
				next_state = read_st0;
			end
		endcase
	end
	
	always@(posedge clk) begin
		if(reset)begin
			busy <= 1'd0;
			po <= 1'd0;
			xo <= 3'd0;
			yo <= 3'd0;
			x1 <= 3'd0;
			x2 <= 3'd0;
			x3 <= 3'd0;
			y1 <= 3'd0;
			y2 <= 3'd0;
			y3 <= 3'd0;
			xc <= 3'd0;
			yc <= 3'd0;
			//lside <= 8'd0;
		end
		else begin
			case(curt_state)
 				read_st0 : begin
					x1 <= xi;
					y1 <= yi;
				end
				read_st1 : begin
					busy <= 1'b1;
					x2 <= xi;
					y2 <= yi;
				end
				read_st2 : begin
					x3 <= xi;
					y3 <= yi;
					xc <= x1;
					yc <= y1;
				end
				mv_r : begin
					xo <= xc;
					yo <= yc;
					po <= 1;
					xc <= xc + 1;
					//lside <= (x2-xc)*(y3-y2)-(yc-y2)*(x2-x3);
					if(lside[7])begin
						xc <= x1;
						yc <= yc + 1;
					end
				end
				mv_u : begin
					xo <= xc;
					yo <= yc;
					xc <= xc + 1;
					//lside <= (x2-xc)*(y3-y2)-(yc-y2)*(x2-x3);
					if(lside[7])begin
						xc <= x1;
						yc <= yc+1;
					end
				end
				stop : begin
					busy <= 0;
					po <= 0;
					xo <= 0;
					yo <= 0;
				end
			endcase
		end
	end
	always@(*)begin
		lside <= (x2-xc-1)*(y3-y2)-(yc-y2)*(x2-x3);
	end                


endmodule
