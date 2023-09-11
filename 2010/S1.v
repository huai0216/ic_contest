module S1(clk,
	  rst,
	  RB1_RW,
	  RB1_A,
	  RB1_D,
	  RB1_Q,
	  sen,
	  sd);

  input clk, rst;
  output RB1_RW;      // control signal for RB1: Read/Write
  output [4:0] RB1_A; // control signal for RB1: address
  output [7:0] RB1_D; // data path for RB1: input port
  input [7:0] RB1_Q;  // data path for RB1: output port
  output sen, sd;
  
//====================================================================
  wire RB1_RW = 1;
  wire [7:0] RB1_D = 0;
  reg [4:0] RB1_A;
  reg sen, sd;
  reg sen_pos, sd_pos;
  reg [4:0] count;
  reg [2:0] addr_count;
  reg [2:0] curt_state, next_state;

  localparam idle = 0, addr_st = 1, data_st = 2, nxtpack_st = 3, nxtp_st = 4;


	always@(posedge clk or posedge rst)begin
		if(rst) curt_state <= idle;
		else curt_state <= next_state;
	end

	always@(*)begin
		case(curt_state)
			idle:begin
				next_state = addr_st;
			end
			addr_st : begin
				case(count)
					0 : next_state = data_st;
					default : next_state = addr_st;
				endcase
			end
			data_st : begin
				case(count)
					0 : next_state = nxtp_st;
					default : next_state = data_st;
				endcase
			end
			nxtp_st : begin
				next_state = addr_st;
			end
			default : begin
				next_state = idle;
			end
		endcase
	end
	
	always@(posedge clk or posedge rst)begin
		if(rst)begin
			RB1_A <= 5'd0;
			addr_count <= 0;
			count <= 0;
		end
		else begin
			case(curt_state)
				idle : begin
					sen_pos <= 1;
					addr_count <= 3'd7;
					count <= 2;
				end
				addr_st : begin
					if(count == 0)begin
						count <= 17;
						RB1_A <= RB1_A - 1;
					end
					else begin
						count <= count - 1;
						RB1_A <= 17;
					end
					sen_pos <= 0;
					sd_pos <= ~addr_count[count];
				end
				data_st : begin
					count <= count - 1; 
					RB1_A <= count - 2;
					sd_pos <= RB1_Q[addr_count];
				end
				nxtp_st : begin
					addr_count <= addr_count - 1;
					count <= 17;
					count <= 2;
					sen_pos <= 1;
				end
			endcase
		end
	end

	always@(negedge clk or posedge rst)begin
		if(rst)begin
			sen <= 1;
			sd <= 0;
		end
		else begin
			sen <= sen_pos;
			sd <= sd_pos;
		end
	end

endmodule

