module LCD_CTRL(clk, reset, IROM_Q, cmd, cmd_valid, IROM_EN, IROM_A, IRB_RW, IRB_D, IRB_A, busy, done);
input clk;
input reset;
input [7:0] IROM_Q;
input [2:0] cmd;
input cmd_valid;
output reg IROM_EN;
output reg [5:0] IROM_A;
output reg IRB_RW;
output reg [7:0] IRB_D;
output reg [5:0] IRB_A;
output reg busy;
output reg done;

integer i, j;

reg [7:0] aver;
reg [7:0] data_buff [7:0][7:0]; 
reg [2:0] x, y, opx, opy, wrx, wry;
reg [1:0] curt_state, next_state;
parameter read_st = 0, cmd_st = 1, process_st = 2, write_st = 3; 

	//state register
	always@(posedge clk)begin
		if(reset)begin
			curt_state <= read_st;
		end
		else begin
			curt_state <= next_state;
		end
	end
	//next state logic
	always@(*)begin
		case(curt_state)
			read_st : begin
				if(IROM_EN == 1'd1)
					next_state = cmd_st;
				else
					next_state = read_st;
			end
			cmd_st : begin
				if(cmd_valid)
					next_state = process_st;
				else
					next_state = cmd_st;
			end
			process_st : begin
				if(cmd == 3'd0)
					next_state = process_st;
				else
					next_state = cmd_st;
			end
			write_st : begin
				next_state = write_st;
			end
			default : begin
				next_state = read_st;
			end
		endcase
	end

	always@(posedge clk)begin
		if(reset)begin
			IROM_EN <= 1'd0;
			IROM_A <= 0;
			busy <= 1'd1;
			done <= 1'd0;
			IRB_A <= 6'd0;
			IRB_D <= 8'd0;
			IRB_RW <= 1'd1;
			opx <= 3'd3;
			opy <= 3'd3;
			for(i=0;i<8;i=i+1)
				for(j=0;j<8;j=j+1)
					data_buff[i][j] <= 0;
		end
		else begin
			case(curt_state)
				read_st : begin
					if(IROM_A == 6'd63)
						IROM_EN <= 1'd1;
					data_buff[y][x] <= IROM_Q;
					if(IROM_A == 6'd63)
						IROM_A <= 6'd0;
					else
						IROM_A <= IROM_A + 6'd1;
				end
				cmd_st : begin
					if(cmd_valid)
						busy <= 1'd1;
					else
						busy <= 1'd0;
					if(cmd == 3'd0)
						IRB_RW <= 1'd0;
					else
						IRB_RW <= 1'd1;	
					if(cmd == 3'd0)
						IRB_D <= data_buff[0][0];
					
				end
				process_st : begin
					case(cmd)
						3'd0:begin
							if(IRB_A == 6'd63)begin
								IRB_A <= 0;
							end
							else begin
								IRB_A <= IRB_A + 1;
							end
							if(IRB_A == 6'd63)begin
								done <= 1'd1;
							end
							else begin
								done <= 1'd0;
							end
							IRB_D <= data_buff[wry][wrx];
						end
						3'd1:begin
							if(opy <= 0)
								opy <= opy;
							else							
								opy <= opy - 1;
						end
						3'd2:begin
							if(opy >= 6)
								opy <= opy;
							else
								opy <= opy + 1;
						end
						3'd3:begin
							if(opx <= 0)
								opx <= opx;
							else
								opx <= opx - 1;
						end	
						3'd4:begin
							if(opx >= 6)
								opx <= opx;	
							else
								opx <= opx + 1;
						end
						3'd5:begin
							data_buff[opy][opx] <= aver;
							data_buff[opy][opx+1] <= aver;
							data_buff[opy+1][opx] <= aver;
							data_buff[opy+1][opx+1] <= aver;
						end
						3'd6:begin
							data_buff[opy][opx] <= data_buff[opy+1][opx];
							data_buff[opy][opx+1] <= data_buff[opy+1][opx+1];
							data_buff[opy+1][opx] <= data_buff[opy][opx];
							data_buff[opy+1][opx+1] <= data_buff[opy][opx+1];
						end
						3'd7:begin
							data_buff[opy][opx]     <= data_buff[opy][opx+1];
							data_buff[opy][opx+1]	<= data_buff[opy][opx];
							data_buff[opy+1][opx]	<= data_buff[opy+1][opx+1];
							data_buff[opy+1][opx+1] <= data_buff[opy+1][opx];
						end
					endcase
				end
			endcase
		end
	end

	always@(*)begin
		x = IROM_A[2:0] - 3'd1;
		y = (IROM_A - 3'd1) >> 3;
		aver = ({2'd00,data_buff[opy][opx]} + {2'd0,data_buff[opy][opx+1]} + {2'd0,data_buff[opy+1][opx]} + {2'd0,data_buff[opy+1][opx+1]}) >>> 2;
		wrx = IRB_A[2:0] + 1;
		wry = (IRB_A + 1) >> 3;
	end

endmodule

