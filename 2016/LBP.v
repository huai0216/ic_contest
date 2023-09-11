
`timescale 1ns/10ps
module LBP ( clk, reset, gray_addr, gray_req, gray_ready, gray_data, lbp_addr, lbp_valid, lbp_data, finish);
input   	clk;
input   	reset;
output  [13:0] 	gray_addr;
output         	gray_req;
input   	gray_ready;
input   [7:0] 	gray_data;
output  [13:0] 	lbp_addr;
output  	lbp_valid;
output  [7:0] 	lbp_data;
output  	finish;


//====================================================================
reg  [13:0] gray_addr;
reg     gray_req;
reg  [13:0] lbp_addr;
reg  	lbp_valid;
reg  [7:0] 	lbp_data;
reg  	finish;
reg [2:0] curt_state, next_state;
reg [3:0] col_count;
reg [7:0] data [7:0];

localparam idle_st = 0, read_col_st = 1, read_mv_st = 2, proc_left_st = 3, proc_mid_st = 4, proc_right_st = 5, out_st = 6, finish_st = 7;

wire [13:0] lbp_inc = lbp_addr + 1;
wire [13:0] gray_down = gray_addr + 128;
wire [13:0] gray_next = gray_addr - 255;
wire fin = (lbp_addr == 16254)?1:0;
wire mv = (col_count == 3 || col_count == 4)?1:0;
wire [3:0] col_ch = col_count + 27;

	always@(posedge clk or posedge reset)begin
		if(reset)begin
			curt_state <= idle_st;
		end
		else begin
			curt_state <= next_state;
		end
	end

	always@(*)begin
		case(curt_state)
			idle_st : begin
				case(gray_ready)
					0 : next_state = idle_st;
					1 : next_state = read_col_st;
				endcase
			end
			read_col_st : begin
				case(mv)
					1 : next_state = read_mv_st;
					default : next_state = read_col_st;
				endcase	
			end
			read_mv_st : begin	
				case(col_count)
					6 : next_state = read_col_st;
					7 : next_state = proc_left_st;
					default : next_state = read_mv_st;
				endcase
			end
			proc_left_st : begin
				next_state = proc_mid_st;
			end
			proc_mid_st : begin
				next_state = proc_right_st;
			end
			proc_right_st : begin
				next_state = out_st;
			end
			out_st : begin
				case(fin)
					1 : next_state = finish_st;
					default : next_state = proc_left_st;
				endcase			
			end
			finish_st : begin
				next_state = finish_st;
			end
		endcase
	end
	
	always@(posedge clk or posedge reset)begin
		if(reset)begin
			gray_addr <= 14'd0;
			gray_req <= 1'd0;
			lbp_addr <= 14'd0;
			lbp_valid <= 1'd0;
			lbp_data <= 8'd0;
			finish <= 1'd0;	
		end
		else begin
			case(curt_state)
				idle_st : begin	//0
					gray_req <= 1'd1;
					lbp_addr <= 128;
					col_count <= 0;
				end
				read_col_st : begin	//1
					gray_addr <= gray_down;
					data[col_count] <= gray_data;
					col_count <= col_count + 3;
				end
				read_mv_st : begin	//2
					gray_addr <= gray_next;	
					data[col_count] <= gray_data;
					col_count <= col_ch;
				end
				proc_left_st : begin	//3
					gray_addr <= gray_down;	
					data[2] <= gray_data;
					lbp_data[0] <= (data[0] < data[4]) ? 0 : 1;
					lbp_data[3] <= (data[3] < data[4]) ? 0 : 1;
					lbp_data[5] <= (data[6] < data[4]) ? 0 : 1;	
				end
				proc_mid_st : begin	//4
					gray_addr <= gray_down;
					data[5] <= gray_data;
					lbp_data[1] <= (data[1] < data[4]) ? 0 : 1;
					lbp_data[6] <= (data[7] < data[4]) ? 0 : 1;
					//data[0] <= data[1];
					//data[3] <= data[4];
					data[6] <= data[7];
				end	
				proc_right_st : begin	//5
					gray_addr <= gray_next;
					lbp_data[2] <= (data[2] < data[4]) ? 0 : 1;
					lbp_data[4] <= (data[5] < data[4]) ? 0 : 1;
					lbp_data[7] <= (gray_data < data[4]) ? 0 : 1;
					data[7] <= gray_data;
					lbp_addr <= lbp_inc;
					lbp_valid <= (lbp_addr[6:1] == 6'b111111) ? 0 : 1;
					gray_req <= 0;
				end
				out_st : begin		//6
					lbp_valid <= 0;
					gray_req <= 1;
					data[0] <= data[1];
					data[3] <= data[4];
					data[1] <= data[2];
					data[4] <= data[5];	
				end
				finish_st : begin
					finish <= 1;
				end
			endcase
		end
	end

//====================================================================
endmodule
