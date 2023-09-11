module SME(clk,reset,chardata,isstring,ispattern,valid,match,match_index);
input clk;
input reset;
input [7:0] chardata;
input isstring;
input ispattern;
output match;
output [4:0] match_index;
output valid;
reg match;
reg [4:0] match_index;
reg valid;

reg [1:0] next_state, curt_state;
localparam idle_st = 0, reads_st = 1, readp_st = 2, comp_st = 3;

localparam spec_begin = 8'h5E;
localparam spec_end = 8'h24;
localparam spec_any = 8'h2E;
localparam spec_space = 8'h20;

reg [7:0] str [0:33];
reg [7:0] pat [0:7];
reg [4:0] str_pos; //str begin position
reg [3:0] pat_pos; //pat begin position

integer i;

reg [5:0] str_rpos; //str recent position when compare
reg [3:0] pat_rpos; //pat recent position when compare
reg pat_flag;
wire [5:0] str_min_1 = str_pos - 1;
wire [3:0] pat_min_1 = pat_pos - 1;
wire [7:0] str_val = str[str_rpos];
wire [7:0] pat_val = pat[pat_rpos];
wire [5:0] str_radd_1 = str_rpos + 1;
wire [3:0] pat_radd_1 = pat_rpos + 1;

wire val_eq = (pat_val == str_val) || ((str_val != spec_begin) && (str_val != spec_end) && (pat_val == spec_any)) || (((pat_val == spec_begin)||(pat_val == spec_end)) && str_val==spec_space);
wire str_end = (str_rpos == 6'd33);
wire pat_end = (pat_rpos == 4'd7);
reg [5:0] idx;
wire char_b = (chardata == spec_begin);
wire [5:0] idx_add_1 = idx + 1;
wire [5:0] strrpos_add_1 = str_rpos + 1;

	always@(posedge clk or posedge reset)begin
		curt_state <= (reset)?idle_st:next_state;
	end
	
	always@(*)begin
		next_state = curt_state;
		case(curt_state)
			idle_st : begin
				if(isstring) next_state = reads_st;
				else if(ispattern) next_state = readp_st;
			end
			reads_st : begin
				if(!isstring) next_state = readp_st;
			end
			readp_st : begin
				if(!ispattern) next_state = comp_st;
			end
			comp_st : begin
				if(str_end) next_state = idle_st;
				else if(pat_end && val_eq) next_state = idle_st;
				else next_state = comp_st;
			end
			default : begin
				next_state = idle_st;
			end
		endcase
	end

	always@(posedge clk or posedge reset)begin
		if(reset)begin
			str_pos <= 31;
			pat_pos <= 7;
			match <= 0;
			match_index <= 4'd0;
			valid <= 0;
			for(i = 0; i < 33; i = i + 1) str[i] <= 0; 
			for(i = 0; i < 8; i = i + 1) pat[i] <= 0;
		end else begin
			valid <= 0;
			match <= 0;
			match_index <= 0;
			case(curt_state)
				idle_st : begin
					case({isstring, ispattern})
						2'b10:begin
							str[31] <= spec_begin;
							str[32] <= chardata;
							str[33] <= spec_end;
							str_pos <= 6'd31;
						end
						2'b01:begin
							pat[7] <= chardata;
							pat_pos <= 3'd7;
							if(char_b) pat_flag <= 1'b0;
							else pat_flag <= 1'b1;
						end
						default : begin
							
						end
					endcase
				end
				reads_st : begin
					if(isstring)begin
						for(i=0; i<32; i=i+1) str[i] <= str[i+1];
						str[32] <= chardata;
						str_pos <= str_min_1;
					end
					if(ispattern)begin
						pat[7] <= chardata;
						pat_pos <= 3'd7;
						if(char_b) pat_flag <= 1'b0;
						else pat_flag <= 1'b1;
					end
				end
				readp_st : begin
					if(ispattern)begin
						for(i=0; i<7; i=i+1) pat[i] <= pat[i+1];
						pat[7] <= chardata;
						pat_pos <= pat_min_1;
					end
					pat_rpos <= pat_pos;
					str_rpos <= str_pos;
					idx <= str_pos;
				end
				comp_st : begin
					if(val_eq)begin
						if(pat_end)begin
							valid <= 1;
							match <= 1;
							match_index <= idx - str_pos - pat_flag;
						end
						pat_rpos <= pat_radd_1;
						str_rpos <= strrpos_add_1;
					end else begin
						if(str_end)begin
							valid <= 1;
						end
						pat_rpos <= pat_pos;
						str_rpos <= idx_add_1;
						idx <= idx_add_1;
					end
					
				end
			endcase
		end
	end

endmodule
