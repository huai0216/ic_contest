module LCD_CTRL(clk, reset, datain, cmd, cmd_valid, dataout, output_valid, busy);
input clk;
input reset;
input [7:0] datain;
input [2:0] cmd;
input cmd_valid;
output reg [7:0] dataout;
output reg  output_valid;
output reg busy;

wire [6:0] fit_pos, in_pos;
reg [3:0] col, row;
reg [6:0] img_counter;
reg [2:0] cmd_reg;
reg [1:0]curt_state, next_state;
reg [7:0] data_buff [0:107];

wire [3:0] in_row_t, in_col_t;
wire [3:0] fit_row_t, fit_col_t;


parameter init_st = 0, zoom_fit_st = 1, zoom_in_st = 2;
parameter load_data = 3'd0, 
		zoom_in = 3'd1, 
		zoom_fit = 3'd2, 
		shift_right = 3'd3,
		shift_left = 3'd4,
		shift_up = 3'd5,
		shift_down = 3'd6;


	// state register
	always@(posedge clk)begin
		if(reset)begin
			curt_state <= init_st;	
		end
		else begin
			curt_state <= next_state;
		end
	end
	
	always@(*)begin
		case(curt_state)
			init_st : begin
				if(cmd_valid)
					next_state = zoom_fit_st;
				else
					next_state = init_st;
			end
			zoom_fit_st : begin
				if((cmd_valid == 1) && (cmd == zoom_in))
					next_state = zoom_in_st;
				else
					next_state = zoom_fit_st;
			end
			zoom_in_st : begin
				if((cmd_valid == 1) && ((cmd == zoom_fit)||(cmd == load_data)))
					next_state = zoom_fit_st;				
				else
					next_state = zoom_in_st;
			end
			default : begin
				next_state = init_st;
			end	
		endcase
	end
	
	always@(posedge clk)begin
		if(reset)begin
			dataout <= 8'd0;
			output_valid <= 1'b0;
			busy <= 1'b0;
			cmd_reg <= zoom_fit;
			img_counter <= 6'd0;
			col <= 3'd6;
			row <= 3'd5;
		end
		else begin
			case(curt_state)
				init_st : begin
					img_counter <= 6'd0;
					busy <= 1'b0;
					if(cmd_valid==1 && cmd == load_data)begin
						busy <= 1'b1;
						cmd_reg <= cmd;
					end
					else begin
						cmd_reg <= zoom_fit;
					end
				end
				zoom_fit_st : begin
					case(cmd_reg)
						load_data : begin
							data_buff[img_counter] <= datain;
							col <= 3'd6;
							row <= 3'd5;
							if(img_counter == 7'd107)begin
								img_counter <= 6'd0;
								//img_counter <= img_counter + 7'd1;
								cmd_reg <= zoom_fit;
							end
							else begin
								img_counter <= img_counter + 7'd1;
							end
						end
						zoom_fit : begin
							output_valid <= 1'b1;
							dataout <= data_buff[fit_pos];
							if(img_counter[2:0]==3'd3)begin
								img_counter[5:3] <= img_counter[5:3] + 3'd1;
								img_counter[2:0] <= 3'd0;
							end
							else begin
								img_counter <= img_counter + 6'd1;
							end
							if(img_counter[5:3] == 3'd3 && img_counter[2:0] == 3'd3)begin
								cmd_reg <= zoom_in;
								busy <= 1'b0;
								img_counter <= 6'd0;
							end
							
						end
						zoom_in : begin
							output_valid <= 1'b0;
							if(cmd_valid==1)begin
								busy <= 1'b1;
								cmd_reg <= cmd;
							end
							else begin
								busy <= 1'b0;
								cmd_reg <= zoom_in;
							end
						end
						shift_right, shift_left, shift_up, shift_down : begin
							output_valid <= 1'b0;
							cmd_reg <= zoom_fit;
						end
					endcase
				end
				zoom_in_st : begin
					case(cmd_reg)
						load_data : begin
							data_buff[img_counter] <= datain;
							col <= 3'd6;
							row <= 3'd5;
							if(img_counter == 7'd107)begin
								img_counter <= 6'd0;
								//img_counter <= img_counter + 7'd1;
								cmd_reg <= zoom_fit;
							end
							else begin
								img_counter <= img_counter + 7'd1;
							end
						end
						zoom_in : begin
							output_valid <= 1'b1;
							dataout <= data_buff[in_pos];
							if(img_counter[2:0]==3'd3)begin
								img_counter[5:3] <= img_counter[5:3] + 3'd1;
								img_counter[2:0] <= 3'd0;
							end
							else begin
								img_counter <= img_counter + 7'd1;
							end
							if(img_counter[5:3] == 3'd3 && img_counter[2:0] == 3'd3)begin
								cmd_reg <= zoom_fit;
								busy <= 1'b0;
								img_counter <= 6'd0;
							end
						end
						zoom_fit : begin
							output_valid <= 1'b0;
							if(cmd_valid == 1 && cmd==zoom_fit)begin
								col <= 3'd6;
								row <= 3'd5;
								busy <= 1'b1;
								cmd_reg <= cmd;
							end
							else if (cmd_valid) begin
								busy <= 1'b1;
								cmd_reg <= cmd;
							end
							else begin
								busy <= 1'b0;
								cmd_reg <= zoom_fit;
							end
						end
						shift_right : begin
							if(col >= 4'd10) col <= col;
							else col <= col + 4'd1;
							cmd_reg <= zoom_in;
						end
						shift_left : begin
							if(col <= 4'd2) col <= col;
							else col <= col - 4'd1;
							cmd_reg <= zoom_in;
						end
						shift_up : begin
							if(row <= 4'd2) row <= row;
							else row <= row - 4'd1;
							cmd_reg <= zoom_in;
						end
						shift_down : begin
							if(row >= 4'd10) row <= row;
							else row <= row + 4'd1;
							cmd_reg <= zoom_in;
						end
					endcase
				end
			endcase
		end
	end
	//(col-5) + (img_counter[2:0])<<1 + img_counter[2:0]
	assign fit_row_t = (row-4) + (img_counter[5:3]<<1);
	assign fit_col_t =  (col-5) + (img_counter[2:0] << 1) + img_counter[2:0];
	assign fit_pos = (fit_row_t<<3) + (fit_row_t<<2) + fit_col_t; 
	assign in_row_t = (row-2) + img_counter[5:3];
	assign in_col_t = (col-2) + img_counter[2:0];
	assign in_pos = (in_row_t<<3) + (in_row_t<<2) + in_col_t;

endmodule


