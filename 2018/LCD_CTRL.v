module LCD_CTRL(clk, reset, cmd, cmd_valid, IROM_Q, IROM_rd, IROM_A, IRAM_valid, IRAM_D, IRAM_A, busy, done);
input clk;
input reset;
input [3:0] cmd;
input cmd_valid;
input [7:0] IROM_Q;
output reg IROM_rd;
output reg [5:0] IROM_A;
output reg IRAM_valid;
output reg [7:0] IRAM_D;
output reg [5:0] IRAM_A;
output reg busy;
output reg done;
reg [1:0] curt_state, next_state;
reg [7:0] data_buff [0:63];
reg [3:0] cmd_reg;
reg [2:0] row, col;

wire [5:0] pos0; //up left 
wire [5:0] pos1; //up right
wire [5:0] pos2; //down left
wire [5:0] pos3; //down right
wire [7:0] max1, max2, min1, min2;

parameter read_st = 0, waitcmd_st = 1, process_st = 2;
parameter write = 4'd0,
		shift_up = 4'd1,
		shift_down = 4'd2,
		shift_left = 4'd3,
		shift_right = 4'd4,
		max = 4'd5,
		min = 4'd6,
		average = 4'd7,
		counter_rotate = 4'd8,
		clockwise_rotate = 4'd9,
		mirrorx = 4'd10,
		mirrory = 4'd11;

	//next state register
	always@(posedge clk)begin
		if(reset) curt_state <= read_st;
		else curt_state <= next_state;
	end
	//next state logic
	always@(*)begin
		case(curt_state)
			read_st : begin
				if(IROM_A == 6'd63)next_state = waitcmd_st;
				else next_state = read_st;
			end
			waitcmd_st : begin
				if(cmd_valid) next_state = process_st;
				else next_state = waitcmd_st;
			end
			process_st : begin
				if(cmd_reg == 4'd0) next_state = process_st;
				else next_state = waitcmd_st;
			end
			default : begin
				next_state = read_st;
			end
		endcase
	end
	//datapath
	always@(posedge clk) begin
		if(reset)begin
			IROM_rd <= 1'b1;
			IROM_A <= 6'd0;
			IRAM_valid <= 1'b0;
			IRAM_D <= 8'd0;
			IRAM_A <= -1;
			busy <= 1'b1;
			done <= 0;
			row <= 3'd4;
			col <= 3'd4;
		end
		else begin
			case(curt_state)
				read_st : begin
					data_buff[IROM_A] <= IROM_Q;
					if(IROM_A == 6'd63) IROM_A <= 6'd0;
					else IROM_A <= IROM_A + 6'd1;
					if(IROM_A == 6'd63) begin
						IROM_rd <= 1'b0;
						busy <= 1'b0;
					end
				end
				waitcmd_st : begin
					busy <= 1'b0;
					if(cmd_valid) begin
						busy <= 1'b1;
						cmd_reg <= cmd;
					end
				end
				process_st : begin
					case(cmd_reg)
						write : begin		//0
							IRAM_valid <= 1'b1;
							IRAM_D <= data_buff[IRAM_A + 6'd1];
							
							if(IRAM_A == 6'd63) IRAM_A <= 0;
							else if (IRAM_A == 6'd63 && IRAM_valid == 1) IRAM_A <= IRAM_A;
							else IRAM_A <= IRAM_A + 6'd1;
							
							if(IRAM_A == 6'd63 && IRAM_valid == 1) done <= 1'b1;
						end
						shift_up : begin		//1
							if(row <= 1) row <= row;
							else row <= row - 3'd1; 
						end
						shift_down : begin	//2
							if(row >= 7) row <= row;
							else row <= row + 3'd1;
						end
						shift_left : begin	//3
							if(col <= 1) col <= col;
							else col <= col - 3'd1;
						end
						shift_right : begin	//4
							if(col >= 7) col <= col;
							else col <= col + 3'd1;
						end
						max : begin			//5
							if(max1 > max2)begin
								data_buff[pos0] <= max1;
								data_buff[pos1] <= max1;
								data_buff[pos2] <= max1;
								data_buff[pos3] <= max1;	
							end 
							else begin
								data_buff[pos0] <= max2;
								data_buff[pos1] <= max2;
								data_buff[pos2] <= max2;
								data_buff[pos3] <= max2; 	
							end
						end
						min : begin			//6
							if(min1 < min2)begin
								data_buff[pos0] <= min1;
								data_buff[pos1] <= min1;
								data_buff[pos2] <= min1;
								data_buff[pos3] <= min1;	
							end 
							else begin
								data_buff[pos0] <= min2;
								data_buff[pos1] <= min2;
								data_buff[pos2] <= min2;
								data_buff[pos3] <= min2; 	
							end
						end
						average : begin		//7
							data_buff[pos0] <= ({1'b0, ({1'b0,max1}+{1'b0,max2})} + {1'b0,({1'b0,min1}+{1'b0,min2})}) >>> 2;
							data_buff[pos1] <= ({1'b0, ({1'b0,max1}+{1'b0,max2})} + {1'b0,({1'b0,min1}+{1'b0,min2})}) >>> 2;
							data_buff[pos2] <= ({1'b0, ({1'b0,max1}+{1'b0,max2})} + {1'b0,({1'b0,min1}+{1'b0,min2})}) >>> 2;
							data_buff[pos3] <= ({1'b0, ({1'b0,max1}+{1'b0,max2})} + {1'b0,({1'b0,min1}+{1'b0,min2})}) >>> 2;
						end
						counter_rotate : begin	//8
							data_buff[pos0] <= data_buff[pos1];
							data_buff[pos1] <= data_buff[pos3];
							data_buff[pos2] <= data_buff[pos0];
							data_buff[pos3] <= data_buff[pos2];
						end
						clockwise_rotate : begin //9
							data_buff[pos0] <= data_buff[pos2];
							data_buff[pos1] <= data_buff[pos0];
							data_buff[pos2] <= data_buff[pos3];
							data_buff[pos3] <= data_buff[pos1];
						end
						mirrorx : begin		//10
							data_buff[pos0] <= data_buff[pos2];
							data_buff[pos2] <= data_buff[pos0];
							data_buff[pos1] <= data_buff[pos3];
							data_buff[pos3] <= data_buff[pos1];
						end
						mirrory : begin		//11
							data_buff[pos0] <= data_buff[pos1];
							data_buff[pos1] <= data_buff[pos0];
							data_buff[pos2] <= data_buff[pos3];
							data_buff[pos3] <= data_buff[pos2];
						end
					endcase
				end
			endcase
		end
	end

	assign pos0 = ((row-3'd1)<<3) + (col-3'd1);
	assign pos1 = ((row-3'd1)<<3) + col;
	assign pos2 = (row<<3) + (col-3'd1);
	assign pos3= (row<<3) + col;
	assign max1 = (data_buff[pos0] > data_buff[pos1]) ? data_buff[pos0] : data_buff[pos1];
	assign max2 = (data_buff[pos2] > data_buff[pos3]) ? data_buff[pos2] : data_buff[pos3];
	assign min1 = (data_buff[pos0] < data_buff[pos1]) ? data_buff[pos0] : data_buff[pos1];
	assign min2 = (data_buff[pos2] < data_buff[pos3]) ? data_buff[pos2] : data_buff[pos3];

endmodule



