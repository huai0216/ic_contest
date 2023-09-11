module lcd_ctrl(clk, reset, datain, cmd, cmd_valid, dataout, output_valid, busy);
input           clk;
input           reset;
input   [7:0]   datain;
input   [2:0]   cmd;
input           cmd_valid;
output reg [7:0]   dataout;
output reg         output_valid;
output reg         busy;



parameter waitcmd = 0, decode =1;
parameter reflash = 3'd0, load_data = 3'd1, shift_right = 3'd2, shift_left = 3'd3, shift_up = 3'd4, shift_down = 3'd5;

wire [2:0] row_t, col_t;
wire [5:0] img_pos;
reg [5:0] img_counter;
reg [2:0] row, col;
reg next_state, curt_state;
reg [2:0] cmd_reg;
reg [7:0] data_buff [0:35];

	//state register
	always@(posedge clk)begin
		if(reset) curt_state <= next_state;
		else curt_state <= next_state;
	end
	//next state logic
	always@(*)begin
		case(curt_state)
			waitcmd : begin
				if(cmd_valid) next_state = decode;
				else next_state = waitcmd;
			end
			decode : begin
				if(cmd_reg == reflash && img_counter[2:0] == 3'd2 && img_counter[5:3] == 3'd2)		
					next_state = waitcmd;
				else
					next_state = decode;
			end
			default : begin
				next_state = waitcmd;
			end
		endcase
	end
	//datapath
	always@(posedge clk)begin
		if(reset)begin
			busy <= 1'b0;
			dataout <= 8'd0;
			output_valid <= 1'd0;
			img_counter <= 6'd0;
			row <= 3'd2;
			col <= 3'd2;
		end
		else begin
			case(curt_state)
				waitcmd : begin
					output_valid <= 1'd0;
					img_counter <= 6'd0;
					if(cmd_valid)begin
						busy <= 1'b1;
						cmd_reg <= cmd;
					end 
				end
				decode : begin
					case(cmd_reg)
						reflash : begin
							output_valid <= 1'b1;
							dataout <= data_buff[img_pos];
							if(img_counter[2:0] == 3'd2)begin
								img_counter[2:0] <= 3'd0;
								img_counter[5:3] <= img_counter[5:3] + 3'd1;				
							end
							else img_counter <= img_counter + 6'd1;
							if(img_counter[2:0] == 3'd2 && img_counter[5:3] == 3'd2)
								busy <= 1'b0;
														
						end
						load_data : begin
							data_buff[img_counter] <= datain;
							row <= 2;
							col <= 2;
							if(img_counter == 6'd35)begin
								img_counter <= 6'd0;
								cmd_reg <= reflash;
							end
							else img_counter <= img_counter + 6'd1;
						end
						shift_right : begin
							if(col >= 3) col <= col;
							else col <= col + 1;
							cmd_reg <= reflash;
						end
						shift_left : begin
							if(col <= 0) col <= col;
							else col <= col - 1;
							cmd_reg <= reflash;
						end
						shift_up : begin
							if(row <= 0) row <= row;
							else row <= row - 1;
							cmd_reg <= reflash;
						end
						shift_down : begin
							if(row >= 3) row <= row;
							else row <= row + 1;
							cmd_reg <= reflash;
						end
					endcase
				end
			endcase
		end
	end

	assign row_t = row + img_counter[5:3];
	assign col_t = col + img_counter[2:0];
	assign img_pos = (row_t<<2) + (row_t<<1) + col_t;
	
                                                                                     
endmodule
