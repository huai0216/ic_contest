module STI_DAC(clk ,reset, load, pi_data, pi_length, pi_fill, pi_msb, pi_low, pi_end,
	       so_data, so_valid,
	       pixel_finish, pixel_dataout, pixel_addr,
	       pixel_wr);

input		clk, reset;
input		load, pi_msb, pi_low, pi_end; 
input	[15:0]	pi_data;
input	[1:0]	pi_length;
input		pi_fill;
output reg		so_data, so_valid;

output reg  pixel_finish, pixel_wr;
output reg [7:0] pixel_addr;
output reg [7:0] pixel_dataout;

//==============================================================================
reg [4:0] counter, addr;
reg [31:0] data_buff;
reg [2:0] curt_state, next_state;
parameter read_st = 0, bit8_st = 1, bit16_st = 2, bit24_st = 3, bit32_st = 4, done_st = 5;


	always@(posedge clk or posedge reset)begin
		if(reset) curt_state <= read_st;
		else curt_state <= next_state;
	end

	always@(*)begin
		case(curt_state)
			read_st : begin
				if(load)begin
					case(pi_length)
						2'b00 : next_state = bit8_st;
						2'b01 : next_state = bit16_st;
						2'b10 : next_state = bit24_st;
						2'b11 : next_state = bit32_st;
					endcase
				end
				else begin
					next_state = read_st;
				end
			end
			bit8_st : begin
				next_state = (counter == addr) ? read_st : bit8_st;
			end
			bit16_st : begin
				next_state = (counter == addr) ? read_st : bit16_st;
			end
			bit24_st : begin
				next_state = (counter == addr) ? read_st : bit24_st;
			end
		endcase
	end

	always@(posedge clk or posedge reset)begin
		if(reset)begin
			so_data <= 1'd0;
			so_valid <= 1'd0;
			pixel_finish <= 1'd0;
			pixel_wr <= 1'd0;
			pixel_addr <= -1;
			pixel_data_out <= 8'd0;
			data_buff <= 32'd0;
			counter <= 5'd0;
			addr <= 5'd0;
		end
		else begin
			case(curt_state)
				read_st : begin
					case(pi_length)
						2'b00 : begin 
							addr <= 5'd7;
							case(pi_low)	
								0 : data_buff <= {24'd0, pi_data[7:0]};
								1 : data_buff <= {24'd0, pi_data[15:8]};
							endcase
						end
						2'b01 : begin
							addr <= 5'd15;
							data_buff <= {16'd0, pi_data};
						end
						2'b10 : begin
							addr <= 5'd23;
							case(pi_fill)
								0 : data_buff <= {8'd0, pi_data};
								1 : data_buff <= {pi_data, 8'd0};
							endcase
						end
						2'b11 : begin
							addr <= 5'd31;
							case(pi_fill)
								0 : data_buff <= {16'd0, pi_data};
								1 : data_buff <= {pi_data, 16'd0};
							endcase
						end
					endcase	
				end
				bit8_st : begin
					counter <= counter + 1;
					so_valid <= 1;
					so_data <= (pi_msb == 1)?data_buff[addr-counter]:data_buff[counter];
					pixel_addr <= pixel_addr + 1;
					pixel_data <= (counter[2:0] == 3'd0)?data_buff[7:0]
				end
			endcase
		end
	end


endmodule
