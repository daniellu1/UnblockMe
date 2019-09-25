module Project (input [9:0] SW, input [3:0] KEY, input CLOCK_50,
					 output VGA_CLK, VGA_HS, VGA_VS, VGA_BLANK_N, VGA_SYNC_N, 
					 output [7:0] VGA_R, VGA_G, VGA_B, 
					 output [6:0] HEX0, HEX1, HEX2, 
					 inout PS2_CLK, PS2_DAT); 
	
	wire clk50m = CLOCK_50; 						// 50MHz clock
	
	wire [4:0] blockAddress_toSet; 				// select address of block to pass into moveBlockFSM
	wire [4:0] blockAddress; 						// select address of block to read from/write to memory
	wire [4:0] blockAddressDraw; 					// same as above
	wire [4:0] blockAddressState; 				// same as above
	wire [4:0] blockAddressCheckLegal; 			// same as above
	
	wire [9:0] difficulty = SW[9:0]; 			// select difficulty level (go to line 813 to set difficulty initial board)
	
	wire [5:0] rowData_read; 						// to read row data from memory
	wire [5:0] rowData_write; 						// to write row data into memory
	wire boardStateWren, boardStateWren2; 
	
	wire reset 			= ~KEY[0]; 					// reset 
	wire confirmBlock = ~KEY[1];					// confirm selection of block 
	wire leftDown 		= ~KEY[2]; 					// move block left/down
	wire rightUp 		= ~KEY[3]; 					// move block right/up
		
	wire wren, draw_wren, state_wren; 			// write enable
	
	wire plot, 											// VGA draws when plot = 1
		  drawRead, 									// 1 = drawFSM is accessing memoryStore 
		  stateRead; 									// 1 = boardStateFSM is accessing memoryStore
	
	wire [7:0] x_write, x_read, X, 				// x value we want to read from memory, x value we want to write to memory, X we want to draw
				  x_read_draw, x_read_state; 
	
	wire [6:0] y_write, y_read, Y, 				// y value we want to read from memory, y value we want to write to memory, Y we want to draw
				  y_read_draw, y_read_state; 
	
	wire orientation_read, orientation_write,	// orientation of block (0 = horizontal, 1 = vertical) 
		  orientation_read_draw, orientation_read_state;  
	
	wire [2:0] colour_write, colour_read, COLOUR, //colour we want to read from/write to memory, colour we want to draw	
				  colour_read_draw, colour_read_state; 
				  
	wire doneWrite, doneDraw;						// doneWrite tells drawFSM to start drawing,
															// doneDraw tells boardStateFSM to recopy the data
	
	wire win; 											// the player has won; the game is over until reset is hit
	
	reg [25:0] count;
	reg [7:0] minutes, seconds; 
	hex_decoder h0(seconds[3:0], HEX0);
	hex_decoder h1(seconds[7:4], HEX1);
	hex_decoder h2(minutes[3:0], HEX2);
	always @(posedge clk50m) begin
		if (reset) begin
			count <= 26'd0; 
			minutes <= 8'd0; 
			seconds <= 8'd0; 
		end
		if (!win) begin
			if (count == 26'd49999999) begin
				count <= 26'd0; 
				if (seconds == {4'd5, 4'd9}) begin
					minutes <= minutes + 1'b1; 
					seconds <= 8'd0; 
				end
				else if (seconds[3:0] == 4'd9) begin
					seconds[7:4] <= seconds[7:4] + 1'b1; 
					seconds[3:0] <= 4'b0; 
				end
				else 
					seconds <= seconds + 1'b1; 
			end
			else 
				count <= count + 1'b1; 
		end
	end
	
	vga_adapter VGA(
			.resetn(~reset),
			.clock(CLOCK_50),
			.colour(COLOUR),
			.x(X),
			.y(Y),
			.plot(plot),
			/* Signals for the DAC to drive the monitor. */
			.VGA_R(VGA_R),
			.VGA_G(VGA_G),
			.VGA_B(VGA_B),
			.VGA_HS(VGA_HS),
			.VGA_VS(VGA_VS),
			.VGA_BLANK(VGA_BLANK_N),
			.VGA_SYNC(VGA_SYNC_N),
			.VGA_CLK(VGA_CLK));
		defparam VGA.RESOLUTION = "160x120";
		defparam VGA.MONOCHROME = "FALSE";
		defparam VGA.BITS_PER_COLOUR_CHANNEL = 1;
		defparam VGA.BACKGROUND_IMAGE = "image.colour.mif";
	
	// will (1) read block data from memory, (2) modify the data, (3) write modified data to memory
	moveBlockFSM M1(.blockSelection(blockAddress_toSet), .clk50m(clk50m), .doneWrite(doneWrite), .addressState(blockAddressCheckLegal),
						 .reset(reset), .confirmBlock(confirmBlock), .leftDown(leftDown), .rightUp(rightUp), .difficulty(difficulty), 
						 .x_read(x_read), .y_read(y_read), .colour_read(colour_read), .orientation_read(orientation_read), 
						 .wren(wren), .address(blockAddress), .win(win), .rowData_read(rowData_read), .boardStateWren(boardStateWren2), 
						 .x_write(x_write), .y_write(y_write), .colour_write(colour_write), .orientation_write(orientation_write)); 
	
	// will (1) read block data from memory, (2) output the X, Y, colour, and plot values to be drawn
	drawFSM D1(.reset(reset), .clk50m(clk50m), .leftDown(leftDown), .rightUp(rightUp), .drawRead(drawRead), .doneWrite(doneWrite), 
				  .x_read(x_read_draw), .y_read(y_read_draw), .orientation_read(orientation_read_draw), .colour_read(colour_read_draw), 
				  .x_toDraw(X), .y_toDraw(Y), .colour_toDraw(COLOUR), .current_block(blockAddress_toSet), .win(win), 
				  .address(blockAddressDraw), .plot_out(plot), .wren(draw_wren), .doneDraw(doneDraw)); 
	
	// will store the pixel colour of each tile on the 6 x 6 board (stored in boardStateMemory)
	boardStateFSM S1(.clk50m(clk50m), .reset(reset), .x_read(x_read_state), .y_read(y_read_state), 
						  .colour_read(colour_read_state), .orientation_read(orientation_read_state), 
						  .doneDraw(doneDraw), .stateRead(stateRead), .boardStateWren(boardStateWren), .state_wren(state_wren), 
						  .rowData_write(rowData_write), .rowData_read(rowData_read), .blockAddress(blockAddressState)); 
	
	// memory module where the information about all the blocks will be stored
	memoryStore M0(.reset(reset), .clk(clk50m), 
						.x_in(x_write), .y_in(y_write), .orientation_in(orientation_write), .colour_in(colour_write), 
						.wren(wren), .address(blockAddress),  .x_out(x_read), .y_out(y_read), .orientation_out(orientation_read), .colour_out(colour_read),
						.drawRead(drawRead), .draw_wren(draw_wren), .addressDraw(blockAddressDraw), 
						.x_out_draw(x_read_draw), .y_out_draw(y_read_draw), .orientation_out_draw(orientation_read_draw), .colour_out_draw(colour_read_draw), 
						.stateRead(stateRead), .state_wren(state_wren), .addressState(blockAddressState), 
						.x_out_state(x_read_state), .y_out_state(y_read_state), .orientation_out_state(orientation_read_state), .colour_out_state(colour_read_state));
	
	// memory module where the colour of every space on the board will be stored
	boardStateMemoryHelper B0(.address1(blockAddressState), .address2(blockAddressCheckLegal), .clk50m(clk50m), 
									  .boardStateWren(boardStateWren), .boardStateWren2(boardStateWren2), .stateRead(stateRead), 
									  .rowData_write(rowData_write), .rowData_read(rowData_read));
	
	//KEYBOARD CONTROL BELOW
	wire [7:0] ps2_key_data;
	wire ps2_key_pressed;
	
	PS2_Controller PS2(.CLOCK_50(clk50m), .reset(reset), .PS2_CLK(PS2_CLK), .PS2_DAT(PS2_DAT),
	.received_data(ps2_key_data), .received_data_en	(ps2_key_pressed));
	
	keyboardFSM K1(.clk50m(clk50m), .reset(reset), .ps2_key_pressed(ps2_key_pressed), .ps2_key_data(ps2_key_data), 
						.blockAddress_toSet(blockAddress_toSet)); 
	
endmodule

//*****************************************************
//*****************************************************
//*****************************************************
//*****************************************************
//****************** KEYBOARD FSM *********************
//*****************************************************
//*****************************************************
//*****************************************************
//*****************************************************

module keyboardFSM(clk50m, reset, ps2_key_pressed, ps2_key_data, blockAddress_toSet); 

	input clk50m, reset, ps2_key_pressed; 
	input [7:0] ps2_key_data; 
	
	output reg [4:0] blockAddress_toSet; 
	
	always @(*) 
	begin: state_table
		case (ps2_key_data)
			8'h16: blockAddress_toSet = 5'd1; 
			8'h1E: blockAddress_toSet = 5'd2;
			8'h26: blockAddress_toSet = 5'd3;
			8'h25: blockAddress_toSet = 5'd4;
			8'h2E: blockAddress_toSet = 5'd5;
			8'h36: blockAddress_toSet = 5'd6;
			8'h3D: blockAddress_toSet = 5'd7;
			8'h3E: blockAddress_toSet = 5'd8;
			8'h46: blockAddress_toSet = 5'd9;
			default: ;
		endcase
	end
	
endmodule 

//*****************************************************
//*****************************************************
//*****************************************************
//*****************************************************
//****************** BOARDSTATE FSM *******************
//*****************************************************
//*****************************************************
//*****************************************************
//*****************************************************

module boardStateFSM(clk50m, reset, x_read, y_read, colour_read, orientation_read, 
							doneDraw, stateRead, boardStateWren, state_wren, blockAddress,
							rowData_write, rowData_read); 

	input clk50m, reset; 
	
	input [7:0] x_read; 
	input [6:0] y_read; 
	input [2:0] colour_read; 
	input [5:0] rowData_read;
	input orientation_read;
	input doneDraw; 
	
	output stateRead, boardStateWren, state_wren; 
	output [4:0] blockAddress; 
	output [5:0] rowData_write; 
	
	wire [4:0] copyNum; 
	wire load_copies, extract, resetMem;
	
	boardStateFSM_control BC1(.clk50m(clk50m), .reset(reset), .doneDraw(doneDraw), .resetMem(resetMem), 
									  .copyNum(copyNum), .stateRead(stateRead), .boardStateWren(boardStateWren), 
									  .state_wren(state_wren), .load_copies(load_copies), .extract(extract)); 
	
	boardStateFSM_datapath BD1(.reset(reset), .clk50m(clk50m), .resetMem(resetMem), 
										.x_read(x_read), .y_read(y_read), .colour_read(colour_read), 
										.rowData_read(rowData_read), .orientation_read(orientation_read), 
										.load_copies(load_copies), .copyNum(copyNum), .extract(extract), 
										.address(blockAddress), .rowData_write(rowData_write));

endmodule

//*****************************************************

module boardStateFSM_control(clk50m, reset, doneDraw, 
									  copyNum, stateRead, boardStateWren, state_wren, load_copies, extract, resetMem); 

	input clk50m, reset; 
	input doneDraw; 
	
	output reg [4:0] copyNum; 
	output reg stateRead, boardStateWren, state_wren, load_copies, extract, resetMem;
	
	reg [4:0] current_state, next_state; 
	reg [5:0] count; 
	
	localparam RESET		= 5'd19,
				  WAIT 		= 5'd0,
				  EXTRACT 	= 5'd18, 
				  COPY1 		= 5'd1, 
				  COPY2 		= 5'd2, 
				  COPY3 		= 5'd3, 
				  COPY4 		= 5'd4, 
				  COPY5 		= 5'd5, 
				  COPY6 		= 5'd6, 
				  COPY7 		= 5'd7, 
				  COPY8 		= 5'd8, 
				  COPY9 		= 5'd9, 
				  COPY10 	= 5'd10, 
				  COPY11 	= 5'd11, 
				  COPY12 	= 5'd12, 
				  COPY13 	= 5'd13, 
				  COPY14 	= 5'd14, 
				  COPY15 	= 5'd15, 
				  COPY16 	= 5'd16, 
				  LOAD_COPIES = 5'd17;
	
	always @(*) 
	begin: state_table
		case (current_state) 
			RESET: 		next_state = EXTRACT; 
			WAIT: 		next_state = doneDraw ? RESET : WAIT; 
			EXTRACT: 	next_state = COPY1; 
			COPY1: 		next_state = COPY2;
			COPY2: 		next_state = COPY3;
			COPY3: 		next_state = COPY4;
			COPY4: 		next_state = COPY5;
			COPY5: 		next_state = COPY6;
			COPY6: 		next_state = COPY7;
			COPY7: 		next_state = COPY8;
			COPY8: 		next_state = COPY9;
			COPY9: 		next_state = COPY10;
			COPY10: 		next_state = COPY11;
			COPY11: 		next_state = COPY12;
			COPY12: 		next_state = COPY13;
			COPY13: 		next_state = COPY14;
			COPY14: 		next_state = COPY15;
			COPY15: 		next_state = COPY16;
			COPY16: 		next_state = LOAD_COPIES;
			LOAD_COPIES: next_state = WAIT; 
			default: 	next_state = WAIT; 
		endcase
	end 
	
	always @(*)
	begin: enable_signals
		copyNum 		= 5'b0;
		state_wren	= 1'b0; 
		stateRead 	= 1'b1;  
		resetMem 	= 1'b0; 
		boardStateWren = 1'b0; 
		load_copies = 1'b0;
		extract = 1'b1; 
		
		case(current_state) 
			 RESET: begin
				resetMem = 1'b1; 
				boardStateWren = 1'b1; 
				stateRead = 1'b0; 
				extract = 1'b0; 
			 end
			 COPY1: copyNum = 5'd1; 
			 COPY2: copyNum = 5'd2; 
			 COPY3: copyNum = 5'd3; 
			 COPY4: copyNum = 5'd4; 
			 COPY5: copyNum = 5'd5; 
			 COPY6: copyNum = 5'd6; 
			 COPY7: copyNum = 5'd7; 
			 COPY8: copyNum = 5'd8; 
			 COPY9: copyNum = 5'd9; 
			 COPY10: copyNum = 5'd10; 
			 COPY11: copyNum = 5'd11; 
			 COPY12: copyNum = 5'd12; 
			 COPY13: copyNum = 5'd13; 
			 COPY14: copyNum = 5'd14; 
			 COPY15: copyNum = 5'd15; 
			 COPY16: copyNum = 5'd16; 
			 WAIT: begin
				stateRead = 1'b0;
			 end
			 LOAD_COPIES: begin 
				load_copies = 1'b1; 
				boardStateWren = 1'b1;
				extract = 1'b0; 
			 end
		endcase
	end
	
	always @(posedge clk50m) 
	begin: state_FFs 
		if (reset) begin
			current_state <= RESET; 
			count <= 6'd0; 
		end
		else if (count == 6'd54) begin
			current_state <= next_state; 
			count <= 6'd0; 
		end
		else begin
			current_state <= current_state; 
			count <= count + 1'b1; 
		end
	end
	
endmodule

//*****************************************************

module boardStateFSM_datapath(reset, clk50m, resetMem,
										x_read, y_read, colour_read, rowData_read, orientation_read, 
										load_copies, copyNum, extract, 
										address, rowData_write); 

	input reset, clk50m; 
	
	input [7:0] x_read; 
	input [6:0] y_read; 
	input [2:0] colour_read; 
	input [5:0] rowData_read;
	input orientation_read;
	
	input load_copies, extract, resetMem; 
	input [4:0] copyNum; 
	 
	output reg [4:0] address; 
	output reg [5:0] rowData_write;
	
	reg [5:0] row1, row2, row3, row4, row5, row6;  
	reg [2:0] count, countreset; 
	
	reg [2:0] xToLoad; 
	
	always @(posedge clk50m) begin
		
		if (reset) begin
			row1 <= 6'b0; 
			row2 <= 6'b0; 
			row3 <= 6'b0; 
			row4 <= 6'b0; 
			row5 <= 6'b0; 
			row6 <= 6'b0; 
			count <= 3'b0; 
			countreset <= 3'b0; 
			xToLoad <= 6'b0; 
		end
		
		else if (resetMem) begin
			countreset <= countreset + 1'b1; 
			if (countreset == 3'd1) begin
				address <= 5'd1;
				row1 <= 6'b0; 
			end
			else if (countreset == 3'd2) begin
				address <= 5'd2; 
				row2 <= 6'b0;
			end
			else if (countreset == 3'd3) begin
				address <= 5'd3;
				row3 <= 6'b0;	
			end
			else if (countreset == 3'd4) begin
				address <= 5'd4; 
				row4 <= 6'b0;
			end
			else if (countreset == 3'd5) begin
				address <= 5'd5;
				row5 <= 6'b0;
			end
			else if (countreset == 3'd6) begin
				address <= 5'd6;
				row6 <= 6'b0;
				countreset <= 3'd0; 
			end 
		end
		
		else if (extract) begin
			address <= copyNum;  
			if (y_read == 7'd50) begin
				if (orientation_read == 1'b0) begin
					case (x_read)
						8'd50: row1[5:4] <= 2'b11;
						8'd55: row1[4:3] <= 2'b11;  
						8'd60: row1[3:2] <= 2'b11; 
						8'd65: row1[2:1] <= 2'b11;
						8'd70: row1[1:0] <= 2'b11; 
						default: ; 
					endcase
				end
				else begin
					case (x_read)
						8'd50: begin row1[5] <= 1'b1; row2[5] = 1'b1; end
						8'd55: begin row1[4] <= 1'b1; row2[4] = 1'b1; end 
						8'd60: begin row1[3] <= 1'b1; row2[3] = 1'b1; end
						8'd65: begin row1[2] <= 1'b1; row2[2] = 1'b1; end
						8'd70: begin row1[1] <= 1'b1; row2[1] = 1'b1; end
						8'd75: begin row1[0] <= 1'b1; row2[0] = 1'b1; end
						default: ; 
					endcase
				end
			end
			else if (y_read == 7'd55) begin
				if (orientation_read == 1'b0) begin
					case (x_read)
						8'd50: row2[5:4] <= 2'b11;
						8'd55: row2[4:3] <= 2'b11;  
						8'd60: row2[3:2] <= 2'b11; 
						8'd65: row2[2:1] <= 2'b11;
						8'd70: row2[1:0] <= 2'b11; 
						default: ; 
					endcase
				end
				else begin
					case (x_read)
						8'd50: begin row2[5] <= 1'b1; row3[5] = 1'b1; end
						8'd55: begin row2[4] <= 1'b1; row3[4] = 1'b1; end 
						8'd60: begin row2[3] <= 1'b1; row3[3] = 1'b1; end
						8'd65: begin row2[2] <= 1'b1; row3[2] = 1'b1; end
						8'd70: begin row2[1] <= 1'b1; row3[1] = 1'b1; end
						8'd75: begin row2[0] <= 1'b1; row3[0] = 1'b1; end
						default: ; 
					endcase
				end
			end
			else if (y_read == 7'd60) begin
				if (orientation_read == 1'b0) begin
					case (x_read)
						8'd50: row3[5:4] <= 2'b11;
						8'd55: row3[4:3] <= 2'b11;  
						8'd60: row3[3:2] <= 2'b11; 
						8'd65: row3[2:1] <= 2'b11;
						8'd70: row3[1:0] <= 2'b11; 
						default: ;
					endcase
				end
				else begin
					case (x_read)
						8'd50: begin row3[5] <= 1'b1; row4[5] = 1'b1; end
						8'd55: begin row3[4] <= 1'b1; row4[4] = 1'b1; end 
						8'd60: begin row3[3] <= 1'b1; row4[3] = 1'b1; end
						8'd65: begin row3[2] <= 1'b1; row4[2] = 1'b1; end
						8'd70: begin row3[1] <= 1'b1; row4[1] = 1'b1; end
						8'd75: begin row3[0] <= 1'b1; row4[0] = 1'b1; end
						default: ; 
					endcase
				end
			end
			else if (y_read == 7'd65) begin
				if (orientation_read == 1'b0) begin
					case (x_read)
						8'd50: row4[5:4] <= 2'b11;
						8'd55: row4[4:3] <= 2'b11;  
						8'd60: row4[3:2] <= 2'b11; 
						8'd65: row4[2:1] <= 2'b11;
						8'd70: row4[1:0] <= 2'b11; 
						default: ; 
					endcase
				end
				else begin
					case (x_read)
						8'd50: begin row4[5] <= 1'b1; row5[5] = 1'b1; end
						8'd55: begin row4[4] <= 1'b1; row5[4] = 1'b1; end 
						8'd60: begin row4[3] <= 1'b1; row5[3] = 1'b1; end
						8'd65: begin row4[2] <= 1'b1; row5[2] = 1'b1; end
						8'd70: begin row4[1] <= 1'b1; row5[1] = 1'b1; end
						8'd75: begin row4[0] <= 1'b1; row5[0] = 1'b1; end
						default: ; 
					endcase
				end
			end
			else if (y_read == 7'd70) begin
				if (orientation_read == 1'b0) begin
					case (x_read)
						8'd50: row5[5:4] <= 2'b11;
						8'd55: row5[4:3] <= 2'b11;  
						8'd60: row5[3:2] <= 2'b11; 
						8'd65: row5[2:1] <= 2'b11;
						8'd70: row5[1:0] <= 2'b11; 
						default: ; 
					endcase
				end
				else begin
					case (x_read)
						8'd50: begin row5[5] <= 1'b1; row6[5] = 1'b1; end
						8'd55: begin row5[4] <= 1'b1; row6[4] = 1'b1; end 
						8'd60: begin row5[3] <= 1'b1; row6[3] = 1'b1; end
						8'd65: begin row5[2] <= 1'b1; row6[2] = 1'b1; end
						8'd70: begin row5[1] <= 1'b1; row6[1] = 1'b1; end
						8'd75: begin row5[0] <= 1'b1; row6[0] = 1'b1; end
						default: ; 
					endcase
				end
			end
			else if (y_read == 7'd75) begin
				if (orientation_read == 1'b0) begin
					case (x_read)
						8'd50: row6[5:4] <= 2'b11;
						8'd55: row6[4:3] <= 2'b11;  
						8'd60: row6[3:2] <= 2'b11; 
						8'd65: row6[2:1] <= 2'b11;
						8'd70: row6[1:0] <= 2'b11; 
						default: ; 
					endcase
				end
			end
		end
		
		else if (load_copies) begin
			count <= count + 1'b1; 
			if (count == 3'd1) begin
				address <= 5'd1;
				rowData_write <= row1; 
			end
			else if (count == 3'd2) begin
				address <= 5'd2; 
				rowData_write <= row2;
			end
			else if (count == 3'd3) begin
				address <= 5'd3;
				rowData_write <= row3;	
			end
			else if (count == 3'd4) begin
				address <= 5'd4; 
				rowData_write <= row4;
			end
			else if (count == 3'd5) begin
				address <= 5'd5;
				rowData_write <= row5;
			end
			else if (count == 3'd6) begin
				address <= 5'd6;
				rowData_write <= row6;
				count <= 3'd0; 
			end 
		end
		
	end
	
endmodule

//*****************************************************
//*****************************************************
//*****************************************************
//*****************************************************
//***************** MOVE BLOCK FSM ********************
//*****************************************************
//*****************************************************
//*****************************************************
//*****************************************************
//*****************************************************

module moveBlockFSM(blockSelection, clk50m, reset, confirmBlock, leftDown, rightUp, doneWrite, 
						  x_read, y_read, colour_read, orientation_read, addressState, 
						  wren, address, win, rowData_read, boardStateWren, difficulty, 
						  x_write, y_write, colour_write, orientation_write); 

	input [4:0] blockSelection; 							// selects which block to read from
	input clk50m;			 									// 50MHz clock
	input reset, confirmBlock, leftDown, rightUp; 	// reset, confirm block selection, move left/down, move right/up 
	input [7:0] x_read; 										// x read from memory
	input [6:0] y_read;										// y read from memory
	input [2:0] colour_read; 							 	// colour read from memory
	input orientation_read; 								// orientation read from memory
	input [9:0] difficulty; 								// difficulty level
	
	input [5:0] rowData_read; 
	
	output wren, win; 										// selects whether the module is reading or writing
	output [4:0] address, addressState; 				// selects which address to read from/write to; modify this depending on state
	output [7:0] x_write; 									// x to write to memory
	output [6:0] y_write;									// y to write to memory
	output [2:0] colour_write; 							// colour to write to memory
	output orientation_write; 								// orientation to write to memory
	output doneWrite; 
	output boardStateWren;  
	
	wire checkWin, checkWin2, declareWin; 
	
	wire ld_initial, ld_address, ld_info, ld_memory, alu_RU, alu_LD; 	// wires to control datapath
	
	moveBlockFSM_control MC1(.clk50m(clk50m), .reset(reset), .confirmBlock(confirmBlock), .leftDown(leftDown), .rightUp(rightUp), 
									 .ld_initial(ld_initial), .wren(wren), .ld_address(ld_address), .checkWin(checkWin), .checkWin2(checkWin2), 
									 .ld_info(ld_info), .ld_memory(ld_memory), .alu_RU(alu_RU), .alu_LD(alu_LD), .doneWrite(doneWrite), 
									 .boardStateWren(boardStateWren)); 
	
	moveBlockFSM_datapath MD1(.clk50m(clk50m), .reset(reset), .switches(blockSelection), .addressState(addressState), 
									  .x_read(x_read), .y_read(y_read), .colour_read(colour_read), .orientation_read(orientation_read), 
									  .address(address), .declareWin(declareWin), .checkWin(checkWin), .checkWin2(checkWin2), .difficulty(difficulty), 
									  .x_write(x_write), .y_write(y_write), .colour_write(colour_write), .orientation_write(orientation_write), 
									  .ld_initial(ld_initial), .ld_address(ld_address), .ld_info(ld_info), .ld_memory(ld_memory),
									  .alu_RU(alu_RU), .alu_LD(alu_LD), .rowData_read(rowData_read)); 
									  
	assign win = declareWin; 

endmodule 

//*****************************************************

module moveBlockFSM_control(clk50m, reset, confirmBlock, leftDown, rightUp, checkWin, checkWin2, boardStateWren,
									 ld_initial, wren, ld_address, ld_info, ld_memory, alu_RU, alu_LD, doneWrite);
	
	input clk50m, 					//50 MHz clock
			reset, 					//resets board to initial state
			confirmBlock, 			//KEY[1]
			leftDown, 				//KEY[2]
			rightUp;					//KEY[3]
	output reg ld_initial, 		//whether reset has been pressed (and thus, if we should load the initial state)
				  wren, 				//whether we are writing to memory 
				  ld_address, 		//whether to load the address into registers
				  ld_info, 			//whether to load the existing block information
				  ld_memory, 		//whether to allow writing to memory 
				  alu_RU, 			//if the block should move up/right
				  alu_LD, 			//if the block should move down/left
				  doneWrite, 		//if we're done writing
				  boardStateWren, //whether to read from board state memory
				  checkWin, 		//whether to check if the player has won
				  checkWin2; 		//whether to check if the player has won
	
	reg [3:0] current_state, next_state; 
	reg [10:0] count; 
	
	localparam LOAD_INITIAL 		= 4'd0, 
				  CHOOSE_BLOCK 		= 4'd1, 
				  BLOCK_WAIT 			= 4'd2, 
				  LOAD_INFO				= 4'd3, 
				  CHOOSE_DIRECTION	= 4'd4, 
				  LEFT_DOWN				= 4'd5, 
				  RIGHT_UP				= 4'd6, 
				  LOAD_MEMORY			= 4'd7,
				  DONE					= 4'd8, 
				  CHECK_WIN				= 4'd9,
				  CHECK_WIN2			= 4'd10;   
	
	always @(*)
	begin: state_table
		case(current_state)
			LOAD_INITIAL: 	next_state = CHOOSE_BLOCK; 
			CHOOSE_BLOCK: 	next_state = confirmBlock ? BLOCK_WAIT : CHOOSE_BLOCK; 
			BLOCK_WAIT: 	next_state = confirmBlock ? BLOCK_WAIT : LOAD_INFO; 
			LOAD_INFO: 		next_state = CHOOSE_DIRECTION; 
			CHOOSE_DIRECTION: begin
				if (confirmBlock)
					next_state = CHOOSE_BLOCK; 
				else if (leftDown)
					next_state = LEFT_DOWN; 
				else if (rightUp)
					next_state = RIGHT_UP; 
				else
					next_state = CHOOSE_DIRECTION; 
			end
			LEFT_DOWN: 		next_state = leftDown ? LEFT_DOWN : LOAD_MEMORY; 
			RIGHT_UP: 		next_state = rightUp ? RIGHT_UP : LOAD_MEMORY; 
			LOAD_MEMORY: 	next_state = DONE; 
			DONE: 			next_state = CHECK_WIN;
			CHECK_WIN: 		next_state = CHECK_WIN2; 
			CHECK_WIN2: 	next_state = LOAD_INFO; 
			default: 		current_state = LOAD_INITIAL; 
		endcase
	end
	
	
	always @(*) 
	begin: enable_signals
		wren 				= 1'b0; 
		ld_initial 		= 1'b0; 
		ld_address 		= 1'b0; 
		ld_info 			= 1'b0; 
		ld_memory		= 1'b0; 
		alu_RU 			= 1'b0; 
		alu_LD			= 1'b0; 
		doneWrite 		= 1'b0; 
		boardStateWren = 1'b0; 
		checkWin 		= 1'b0; 
		checkWin2		= 1'b0; 
		
		case(current_state) 
			LOAD_INITIAL: begin
				wren = 1'b1; 
				ld_initial = 1'b1; 
				doneWrite = 1'b1; 
			end
			CHOOSE_BLOCK: ld_address = 1'b1; 
			LOAD_INFO: ld_info = 1'b1;  
			RIGHT_UP: alu_RU = 1'b1; 
			LEFT_DOWN: alu_LD = 1'b1;  
			LOAD_MEMORY: begin 
				ld_memory = 1'b1; 
				wren = 1'b1; 
			end
			DONE:doneWrite = 1'b1;  
			CHECK_WIN: checkWin = 1'b1;
			CHECK_WIN2: checkWin2 = 1'b1; 
		endcase
	end
	
	
	always @(posedge clk50m) 
	begin: state_FFs 
		if (reset) begin
			current_state <= LOAD_INITIAL; 
			count <= 10'd1000; 
		end
		else if (count == 10'd1999) begin
			current_state <= next_state; 
			count <= 10'd0; 
		end
		else begin
			current_state <= current_state; 
			count <= count + 1'b1; 
		end
	end
	
endmodule

//*****************************************************

module moveBlockFSM_datapath(clk50m, reset, switches,
									  x_read, y_read, colour_read, orientation_read, difficulty, 
									  address, addressState, declareWin, checkWin, checkWin2, 
									  x_write, y_write, colour_write, orientation_write, rowData_read,
									  ld_initial, ld_address, ld_info, ld_memory, alu_RU, alu_LD);

	input clk50m, reset; 
	input [4:0] switches; 
	input [7:0] x_read;
	input [6:0] y_read;
	input [2:0] colour_read;
	input [5:0] rowData_read;
	input [9:0] difficulty; 
	input orientation_read;
	
	output reg [4:0] address;
	output reg [4:0] addressState; 
	output reg [7:0] x_write;
	output reg [6:0] y_write;
	output reg [2:0] colour_write;
	output reg orientation_write;
	output reg declareWin; 
	
	input ld_initial, ld_address, ld_info, ld_memory, alu_RU, alu_LD, checkWin, checkWin2; 
	
	reg [4:0] addressreg; 
	reg [7:0] xreg, alu_x; 
	reg [6:0] yreg, alu_y; 
	reg orientationreg; 
	reg [2:0] colourreg;
	reg legal; 
	reg [2:0] xCheck; 
	
	reg [3:0] counter;  
	
	always @(posedge clk50m) begin
	
		if(reset) begin 
				addressreg <= 5'b0;
				xreg <= 8'b0;
				yreg <= 7'b0;
				orientationreg <= 1'b0;
				colourreg <= 3'b0;
				counter <= 4'd0; 
				declareWin <= 1'b0;
				legal <= 1'b1; 
				xCheck <= 1'b0; 
		end
		
		if (checkWin) begin
			address <= 5'd1; 
		end
		
		if (checkWin2) begin
			if (x_read > 8'd67) 
				declareWin <= 1'b1; 
			else
				declareWin <= 1'b0; 
		end
		
//*****************************************************
		
		if (ld_initial && difficulty == 10'd1) begin
			if (counter == 4'd1) begin
					address <= 5'd1; 
					x_write <= 8'd50;
					y_write <= 7'd60; 
					orientation_write <= 1'b0; 
					colour_write = 3'b100;
					counter <= counter + 1'b1;
				end 
			else if (counter == 4'd2) begin
				address <= 5'd2; 
				x_write <= 8'd70;
				y_write <= 7'd50; 
				orientation_write <= 1'b1; 
				colour_write <= 3'b111;
				counter <= counter + 1'b1;
			end
			else if (counter == 4'd3) begin
				address <= 5'd3; 
				x_write <= 8'd60;
				y_write <= 7'd55; 
				orientation_write <= 1'b0; 
				colour_write <= 3'b111;
				counter <= counter + 1'b1;
			end
			else if (counter == 4'd4) begin
				address <= 5'd4; 
				x_write <= 8'd60;
				y_write <= 7'd60; 
				orientation_write <= 1'b1; 
				colour_write <= 3'b111;
				counter <= counter + 1'b1;
			end
			else if (counter == 4'd5) begin
				address <= 5'd5; 
				x_write <= 8'd65;
				y_write <= 7'd60; 
				orientation_write <= 1'b1; 
				colour_write <= 3'b111;
				counter <= counter + 1'b1;
			end
			else if (counter == 4'd6) begin
				address <= 5'd6; 
				x_write <= 8'd60;
				y_write <= 7'd70; 
				orientation_write <= 1'b0; 
				colour_write <= 3'b111;
				counter <= counter + 1'b1;
			end
			else if (counter >= 4'd0) begin
				address <= {1'b0, counter}; 
				x_write <= 8'd0; 
				y_write <= 7'd0; 
				orientation_write <= 1'b0; 
				colour_write <= 3'b000;
				counter <= counter + 1'b1;	
			end 
			else 
				counter <= 4'b0; 
		end
		
		else if (ld_initial && difficulty == 10'd2) begin
			if (counter == 4'd1) begin
					address <= 5'd1; 
					x_write <= 8'd65;
					y_write <= 7'd60; 
					orientation_write <= 1'b0; 
					colour_write = 3'b100;
					counter <= counter + 1'b1;
				end 
			else if (counter == 4'd2) begin
				address <= 5'd2; 
				x_write <= 8'd55;
				y_write <= 7'd55; 
				orientation_write <= 1'b1; 
				colour_write <= 3'b111;
				counter <= counter + 1'b1;
			end
			else if (counter == 4'd3) begin
				address <= 5'd3; 
				x_write <= 8'd60;
				y_write <= 7'd55; 
				orientation_write <= 1'b0; 
				colour_write <= 3'b111;
				counter <= counter + 1'b1;
			end
			else if (counter == 4'd4) begin
				address <= 5'd4; 
				x_write <= 8'd70;
				y_write <= 7'd55; 
				orientation_write <= 1'b0; 
				colour_write <= 3'b111;
				counter <= counter + 1'b1;
			end
			else if (counter == 4'd5) begin
				address <= 5'd5; 
				x_write <= 8'd75;
				y_write <= 7'd60; 
				orientation_write <= 1'b1; 
				colour_write <= 3'b111;
				counter <= counter + 1'b1;
			end
			else if (counter == 4'd6) begin
				address <= 5'd6; 
				x_write <= 8'd55;
				y_write <= 7'd65; 
				orientation_write <= 1'b1; 
				colour_write <= 3'b111;
				counter <= counter + 1'b1;
			end
			else if (counter == 4'd7) begin
				address <= 5'd7; 
				x_write <= 8'd65;
				y_write <= 7'd70; 
				orientation_write <= 1'b1; 
				colour_write <= 3'b111;
				counter <= counter + 1'b1;
			end
			else if (counter == 4'd8) begin
				address <= 5'd8; 
				x_write <= 8'd55;
				y_write <= 7'd75; 
				orientation_write <= 1'b0; 
				colour_write <= 3'b111;
				counter <= counter + 1'b1;
			end
			else if (counter >= 4'd0) begin
				address <= {1'b0, counter}; 
				x_write <= 8'd0; 
				y_write <= 7'd0; 
				orientation_write <= 1'b0; 
				colour_write <= 3'b000;
				counter <= counter + 1'b1;	
			end 
			else 
				counter <= 4'b0; 
		end
		
		else if (ld_initial && difficulty == 10'd3) begin
			if (counter == 4'd1) begin
					address <= 5'd1; 
					x_write <= 8'd60;
					y_write <= 7'd60; 
					orientation_write <= 1'b0; 
					colour_write = 3'b100;
					counter <= counter + 1'b1;
				end 
			else if (counter == 4'd2) begin
				address <= 5'd2; 
				x_write <= 8'd65;
				y_write <= 7'd50; 
				orientation_write <= 1'b1; 
				colour_write <= 3'b111;
				counter <= counter + 1'b1;
			end
			else if (counter == 4'd3) begin
				address <= 5'd3; 
				x_write <= 8'd70;
				y_write <= 7'd50; 
				orientation_write <= 1'b0; 
				colour_write <= 3'b111;
				counter <= counter + 1'b1;
			end
			else if (counter == 4'd4) begin
				address <= 5'd4; 
				x_write <= 8'd70;
				y_write <= 7'd55; 
				orientation_write <= 1'b1; 
				colour_write <= 3'b111;
				counter <= counter + 1'b1;
			end
			else if (counter == 4'd5) begin
				address <= 5'd5; 
				x_write <= 8'd55;
				y_write <= 7'd65; 
				orientation_write <= 1'b0; 
				colour_write <= 3'b111;
				counter <= counter + 1'b1;
			end
			else if (counter == 4'd6) begin
				address <= 5'd6; 
				x_write <= 8'd65;
				y_write <= 7'd65; 
				orientation_write <= 1'b1; 
				colour_write <= 3'b111;
				counter <= counter + 1'b1;
			end
			else if (counter == 4'd7) begin
				address <= 5'd7; 
				x_write <= 8'd70;
				y_write <= 7'd65; 
				orientation_write <= 1'b0; 
				colour_write <= 3'b111;
				counter <= counter + 1'b1;
			end
			else if (counter == 4'd8) begin
				address <= 5'd8; 
				x_write <= 8'd60;
				y_write <= 7'd70; 
				orientation_write <= 1'b1; 
				colour_write <= 3'b111;
				counter <= counter + 1'b1;
			end
			else if (counter == 4'd9) begin
				address <= 5'd9; 
				x_write <= 8'd65;
				y_write <= 7'd75; 
				orientation_write <= 1'b0; 
				colour_write <= 3'b111;
				counter <= counter + 1'b1;
			end
			else if (counter >= 4'd0) begin
				address <= {1'b0, counter}; 
				x_write <= 8'd0; 
				y_write <= 7'd0; 
				orientation_write <= 1'b0; 
				colour_write <= 3'b000;
				counter <= counter + 1'b1;	
			end 
			else 
				counter <= 4'b0; 
		end

		else if (ld_initial) begin
			if (counter == 4'd1) begin
					address <= 5'd1; 
					x_write <= 8'd50;
					y_write <= 7'd60; 
					orientation_write <= 1'b0; 
					colour_write = 3'b100;
					counter <= counter + 1'b1;
				end 
			else if (counter == 4'd2) begin
				address <= 5'd2; 
				x_write <= 8'd60;
				y_write <= 7'd60; 
				orientation_write <= 1'b1; 
				colour_write <= 3'b111;
				counter <= counter + 1'b1;
			end
			else if (counter == 4'd3) begin
				address <= 5'd3; 
				x_write <= 8'd60;
				y_write <= 7'd70; 
				orientation_write <= 1'b0; 
				colour_write <= 3'b111;
				counter <= counter + 1'b1;
			end
			else if (counter == 4'd4) begin
				address <= 5'd4; 
				x_write <= 8'd70;
				y_write <= 7'd70; 
				orientation_write <= 1'b1; 
				colour_write <= 3'b111;
				counter <= counter + 1'b1;
			end
			else if (counter >= 4'd0) begin
				address <= {1'b0, counter}; 
				x_write <= 8'd0; 
				y_write <= 7'd0; 
				orientation_write <= 1'b0; 
				colour_write <= 3'b000;
				counter <= counter + 1'b1;	
			end 
			else 
				counter <= 4'b0; 
		end
		
		
//*****************************************************			
		
		
		if (ld_address) begin
			addressreg <= switches; 
			address <= switches; 
		end
		
		if (ld_info) begin
			address <= switches; 
			xreg <= x_read; 
			yreg <= y_read; 
			orientationreg <= orientation_read; 
			colourreg <= colour_read; 
		end
		
		if (ld_memory) begin
			address <= addressreg; 
			x_write <= alu_x; 
			y_write <= alu_y; 
			orientation_write <= orientationreg; 
			colour_write <= colourreg; 
		end
		
		if (alu_LD) begin
			
			if (orientationreg == 1'b0) begin //horizontal
				case (yreg) 
					7'd50: addressState <= 3'd0; 
					7'd55: addressState <= 3'd1; 
					7'd60: addressState <= 3'd2; 
					7'd65: addressState <= 3'd3; 
					7'd70: addressState <= 3'd4; 
					7'd75: addressState <= 3'd5; 
					default: ;
				endcase
				case (xreg)  
					8'd55: xCheck <= 3'd5; 
					8'd60: xCheck <= 3'd4; 
					8'd65: xCheck <= 3'd3; 
					8'd70: xCheck <= 3'd2;  
					default: ;
				endcase
				if (rowData_read[xCheck] == 1'b1) 
					legal <= 1'b0; 
				else
					legal <= 1'b1; 
			end
			
			else begin //vertical
				case (yreg) 
					7'd50: addressState <= 3'd2; 
					7'd55: addressState <= 3'd3; 
					7'd60: addressState <= 3'd4; 
					7'd65: addressState <= 3'd5; 
					default: ;
				endcase
				case (xreg)  
					8'd50: xCheck <= 3'd5; 
					8'd55: xCheck <= 3'd4; 
					8'd60: xCheck <= 3'd3; 
					8'd65: xCheck <= 3'd2; 
					8'd70: xCheck <= 3'd1; 
					8'd75: xCheck <= 3'd0; 
					default: ;
				endcase
				if (rowData_read[xCheck] == 1'b1) 
					legal <= 1'b0; 
				else
					legal <= 1'b1; 
			end
		end
		
		else if (alu_RU) begin
		
			if (orientationreg == 1'b0) begin //horizontal
				case (yreg) 
					7'd50: addressState <= 3'd0; 
					7'd55: addressState <= 3'd1; 
					7'd60: addressState <= 3'd2; 
					7'd65: addressState <= 3'd3; 
					7'd70: addressState <= 3'd4; 
					7'd75: addressState <= 3'd5; 
					default: ;
				endcase
				case (xreg)  
					8'd50: xCheck <= 3'd3;
					8'd55: xCheck <= 3'd2; 
					8'd60: xCheck <= 3'd1; 
					8'd65: xCheck <= 3'd0;  
					default: ;
				endcase
				if (rowData_read[xCheck] == 1'b1) 
					legal <= 1'b0; 
				else
					legal <= 1'b1; 
			end
				
			else begin //vertical
				case (yreg) 
					7'd55: addressState <= 3'd0; 
					7'd60: addressState <= 3'd1; 
					7'd65: addressState <= 3'd2; 
					7'd70: addressState <= 3'd3; 
					default: ;
				endcase
				case (xreg)  
					8'd50: xCheck <= 3'd5; 
					8'd55: xCheck <= 3'd4; 
					8'd60: xCheck <= 3'd3; 
					8'd65: xCheck <= 3'd2; 
					8'd70: xCheck <= 3'd1; 
					8'd75: xCheck <= 3'd0; 
					default: ;
				endcase
				if (rowData_read[xCheck] == 1'b1) 
					legal <= 1'b0; 
				else
					legal <= 1'b1; 
			end
		end
	end
	
	always @(*) 
	begin: ALU 
		if (reset) begin
			alu_x = 8'b0; 
			alu_y = 7'b0; 
		end
		if (alu_LD) begin
			if (!orientationreg) begin
				if (xreg >= 8'd55 && legal == 1'b1)
					alu_x = xreg - 3'd5;
				else
					alu_x = xreg; 
				alu_y = yreg; 
			end
			else begin 
				if (yreg <= 7'd65 && legal == 1'b1)
					alu_y = yreg + 3'd5; 
				else
					alu_y = yreg; 
				alu_x = xreg;
			end
		end
		else if (alu_RU) begin
			if (!orientationreg) begin
				if (xreg <= 8'd65 && legal == 1'b1)
					alu_x = xreg + 3'd5; 
				else
					alu_x = xreg; 
				alu_y = yreg; 
			end
			else begin
				if (yreg >= 7'd55 && legal == 1'b1)
					alu_y = yreg - 3'd5; 
				else
					alu_y = yreg; 
				alu_x = xreg; 
			end
		end
	end
	
	
endmodule

//*****************************************************
//*****************************************************
//*****************************************************
//*****************************************************
//********************* DRAW FSM **********************
//*****************************************************
//*****************************************************
//*****************************************************
//*****************************************************

module drawFSM(reset, clk50m, leftDown, rightUp, drawRead, doneWrite,
					x_read, y_read, orientation_read, colour_read, current_block,
					x_toDraw, y_toDraw, colour_toDraw, win,
					address, plot_out, wren, doneDraw); 

	input reset, clk50m;
	input leftDown, rightUp; 		//if any of these are pressed, clear the screen and redraw everything
	input [7:0] x_read; 
	input [6:0] y_read; 
	input orientation_read; 
	input [2:0] colour_read; 
	input doneWrite;
	input win; 
	input [4:0] current_block; 	//block currently selected by switches
	
	output [7:0] x_toDraw; 
	output [6:0] y_toDraw; 
	output [2:0] colour_toDraw;
	output [4:0] address; 
	output drawRead, doneDraw, plot_out, wren;  
	
	wire [4:0] loadXY;
	wire clear, plot;
	
	drawFSM_control DC1(.clk(clk50m), .reset(reset), .leftDown(leftDown), .rightUp(rightUp), .win(win),
							  .loadXY(loadXY), .wren(wren), .plot(plot), .clear(clear), .drawRead(drawRead), .doneWrite(doneWrite), .doneDraw(doneDraw)); 
	
	drawFSM_datapath DD1(.clk(clk50m), .reset(reset), .loadXY(loadXY), .clear(clear), .plot(plot), .current_block(current_block), 
								.x_read(x_read), .y_read(y_read), .colour_read(colour_read), .orientation_read(orientation_read), .win(win),
								.x_draw(x_toDraw), .y_draw(y_toDraw), .colour_draw(colour_toDraw), .address(address)); 
								
	assign plot_out = plot; 
	
endmodule 

//*****************************************************

module drawFSM_control(clk, reset, leftDown, rightUp, drawRead, win,
							  loadXY, wren, plot, clear, doneWrite, doneDraw);

	input clk, reset; 
	input leftDown, rightUp, doneWrite, win; 
	
	output reg [4:0] loadXY; 
	output reg wren, plot, clear, drawRead, doneDraw;
	
	wire trigger = leftDown | rightUp; 

	reg [6:0] current_state, next_state; 
	reg [10:0] count; 
	
	localparam WAIT 		= 7'd0,
				  LOADXY1	= 7'd1,
				  DRAW1		= 7'd2,
				  LOADXY2 	= 7'd3,
				  DRAW2 		= 7'd4,
				  LOADXY3  	= 7'd5,
				  DRAW3 		= 7'd6,
				  LOADXY4 	= 7'd7, 
				  DRAW4  	= 7'd8,
				  LOADXY5 	= 7'd9,
				  DRAW5  	= 7'd10,
				  LOADXY6 	= 7'd11,
				  DRAW6  	= 7'd12,
			     LOADXY7 	= 7'd13,
				  DRAW7 		= 7'd14,
				  LOADXY8	= 7'd15,
				  DRAW8		= 7'd16,
				  LOADXY9	= 7'd17,
				  DRAW9		= 7'd18,
				  LOADXY10	= 7'd19,
				  DRAW10		= 7'd20,
				  LOADXY11	= 7'd21,
				  DRAW11		= 7'd22,
				  LOADXY12	= 7'd23,
				  DRAW12		= 7'd24,
				  LOADXY13	= 7'd25,
				  DRAW13		= 7'd26,
				  LOADXY14	= 7'd27,
				  DRAW14		= 7'd28,
				  LOADXY15	= 7'd29,
				  DRAW15		= 7'd30,
				  LOADXY16	= 7'd31,
				  DRAW16 	= 7'd32,
				  CLEAR 		= 7'd33, 
				  WIN			= 7'd34;
				  
	always @(*) 
	begin: state_table
		case (current_state) 
			WAIT: 		next_state = doneWrite ? LOADXY1 : WAIT; 
			LOADXY1: 	next_state = DRAW1;
			DRAW1: 		next_state = LOADXY2; 
			LOADXY2: 	next_state = DRAW2;
			DRAW2: 		next_state = LOADXY3;
			LOADXY3: 	next_state = DRAW3;
			DRAW3: 		next_state = LOADXY4; 
			LOADXY4: 	next_state = DRAW4;
			DRAW4: 		next_state = LOADXY5;
			LOADXY5: 	next_state = DRAW5;
			DRAW5: 		next_state = LOADXY6;
			LOADXY6: 	next_state = DRAW6;
			DRAW6: 		next_state = LOADXY7;
			LOADXY7: 	next_state = DRAW7;
			DRAW7: 		next_state = LOADXY8;
			LOADXY8: 	next_state = DRAW8;
			DRAW8: 		next_state = LOADXY9;
			LOADXY9: 	next_state = DRAW9;
			DRAW9: 		next_state = LOADXY10;
			LOADXY10: 	next_state = DRAW10;
			DRAW10: 		next_state = LOADXY11;
			LOADXY11: 	next_state = DRAW11;
			DRAW11: 		next_state = LOADXY12;
			LOADXY12: 	next_state = DRAW12;
			DRAW12: 		next_state = LOADXY13;
			LOADXY13: 	next_state = DRAW13;
			DRAW13: 		next_state = LOADXY14;
			LOADXY14: 	next_state = DRAW14;
			DRAW14: 		next_state = LOADXY15;
			LOADXY15: 	next_state = DRAW15;
			DRAW15: 		next_state = LOADXY16;
			LOADXY16: 	next_state = DRAW16;
			DRAW16: 		next_state = LOADXY1;
			CLEAR: 		next_state = WAIT; 
			WIN: 			next_state = reset ? WAIT : WIN; 
			default: 	next_state = WAIT; 
		endcase
	end
	
	always @(*)
	begin: enable_signals
		loadXY = 5'b0; 
		plot = 1'b0; 
		wren = 1'b0; 
		clear = 1'b0; 
		drawRead = 1'b0;
		doneDraw	= 1'b0; 
		
		case(current_state) 
			LOADXY1: begin
				loadXY = 5'd1;
				drawRead = 1'b1; 
			end
			DRAW1: plot = 1'b1;
			LOADXY2: begin
				loadXY = 5'd2;
				drawRead = 1'b1; 
			end
			DRAW2: plot = 1'b1; 
			LOADXY3: begin
				loadXY = 5'd3;
				drawRead = 1'b1; 
			end
			DRAW3: plot = 1'b1;
			LOADXY4: begin
				loadXY = 5'd4;
				drawRead = 1'b1; 
			end
			DRAW4: plot = 1'b1;	
			LOADXY5: begin
				loadXY = 5'd5;
				drawRead = 1'b1; 
			end
			DRAW5: plot = 1'b1;
			LOADXY6: begin
				loadXY = 5'd6;
				drawRead = 1'b1; 
			end
			DRAW6: plot = 1'b1;
			LOADXY7: begin
				loadXY = 5'd7;
				drawRead = 1'b1; 
			end
			DRAW7: plot = 1'b1;	
			LOADXY8: begin
				loadXY = 5'd8;
				drawRead = 1'b1; 
			end
			DRAW8: plot = 1'b1;	
			LOADXY9: begin
				loadXY = 5'd9;
				drawRead = 1'b1; 
			end
			DRAW9: plot = 1'b1;	
			LOADXY10: begin
				loadXY = 5'd10;
				drawRead = 1'b1; 
			end
			DRAW10: plot = 1'b1;	
			LOADXY11: begin
				loadXY = 5'd11;
				drawRead = 1'b1; 
			end
			DRAW11: plot = 1'b1;
			LOADXY12: begin
				loadXY = 5'd12;
				drawRead = 1'b1; 
			end
			DRAW12: plot = 1'b1;		
			LOADXY13: begin
				loadXY = 5'd13;
				drawRead = 1'b1; 
			end
			DRAW13: plot = 1'b1;	
			LOADXY14: begin
				loadXY = 5'd14;
				drawRead = 1'b1; 
			end
			DRAW14: plot = 1'b1;	
			LOADXY15: begin
				loadXY = 5'd15;
				drawRead = 1'b1; 
			end
			DRAW15: plot = 1'b1;	
			LOADXY16: begin
				loadXY = 5'd16;
				drawRead = 1'b1; 
			end
			DRAW16: begin 
				plot = 1'b1;	
				doneDraw = 1'b1; 
			end
			CLEAR: begin 
				clear = 1'b1; 
				plot = 1'b1;	
			end
			WIN: begin 
				plot = 1'b1; 
				drawRead = 1'b1; 
			end
		endcase
	end

	always @(posedge clk) 
	begin: state_FFs 
		if (reset) begin
			current_state <= CLEAR; 
			count <= 11'd0; 
		end
		else if (win) 
			current_state <= WIN; 
		else if (trigger)
			current_state <= CLEAR;
		else if (count == 11'd999) begin
			current_state <= next_state; 
			count <= 11'd0; 
		end
		else begin
			current_state <= current_state; 
			count <= count + 1'b1; 
		end
	end
	
endmodule

//*****************************************************

module drawFSM_datapath(clk, reset, loadXY, clear, plot, current_block,
								x_read, y_read, colour_read, orientation_read, win, 
								x_draw, y_draw, colour_draw, address); 

	input clk, reset, clear, plot; 
	input [4:0] loadXY, current_block; 
	input [7:0] x_read; 
	input [6:0] y_read; 
	input [2:0] colour_read; 
	input orientation_read, win; 
	
	output reg [7:0] x_draw; 
	output reg [6:0] y_draw; 
	output reg [2:0] colour_draw; 
	output reg [4:0] address; 
	
	reg [7:0] xreg; 
	reg [6:0] yreg; 
	reg [2:0] colourreg; 
	reg orientationreg; 
	
	reg [14:0] clear_counter; 
	reg [9:0] xy_counter;
	
	
	// loads initial blocks 
	
	always @(posedge clk) begin
		
		if (win == 1'b0) begin 
		
			if (loadXY == 5'd1) begin
				address <= 5'd1; 
				xreg <= x_read; 
				yreg <= y_read; 
				colourreg <= (current_block == 5'd1) ? 3'b001 : colour_read; 
				orientationreg <= orientation_read; 
			end
			
			if (loadXY == 5'd2) begin
				address <= 5'd2; 
				xreg <= x_read; 
				yreg <= y_read; 
				colourreg <= (current_block == 5'd2) ? 3'b001 : colour_read; 
				orientationreg <= orientation_read; 
			end
			
			if (loadXY == 5'd3) begin
				address <= 5'd3; 
				xreg <= x_read; 
				yreg <= y_read;
				colourreg <= (current_block == 5'd3) ? 3'b001 : colour_read; 
				orientationreg <= orientation_read; 	
			end
			
			if (loadXY == 5'd4) begin
				address <= 5'd4; 
				xreg <= x_read; 
				yreg <= y_read; 
				colourreg <= (current_block == 5'd4) ? 3'b001 : colour_read; 
				orientationreg <= orientation_read; 
			end
			
			if (loadXY == 5'd5) begin
				address <= 5'd5; 
				xreg <= x_read; 
				yreg <= y_read; 
				colourreg <= (current_block == 5'd5) ? 3'b001 : colour_read; 
				orientationreg <= orientation_read; 
			end
			
			if (loadXY == 5'd6) begin
				address <= 5'd6; 
				xreg <= x_read; 
				yreg <= y_read; 
				colourreg <= (current_block == 5'd6) ? 3'b001 : colour_read;  
				orientationreg <= orientation_read; 
			end
			
			if (loadXY == 5'd7) begin
				address <= 5'd7; 
				xreg <= x_read; 
				yreg <= y_read; 
				colourreg <= (current_block == 5'd7) ? 3'b001 : colour_read; 
				orientationreg <= orientation_read; 
			end
			
			if (loadXY == 5'd8) begin
				address <= 5'd8; 
				xreg <= x_read; 
				yreg <= y_read; 
				colourreg <= (current_block == 5'd8) ? 3'b001 : colour_read; 
				orientationreg <= orientation_read; 
			end
			
			if (loadXY == 5'd9) begin
				address <= 5'd9; 
				xreg <= x_read; 
				yreg <= y_read; 
				colourreg <= (current_block == 5'd9) ? 3'b001 : colour_read; 
				orientationreg <= orientation_read; 
			end
			
			if (loadXY == 5'd10) begin
				address <= 5'd10; 
				xreg <= x_read; 
				yreg <= y_read; 
				colourreg <= (current_block == 5'd10) ? 3'b001 : colour_read; 
				orientationreg <= orientation_read; 
			end
			
			if (loadXY == 5'd11) begin
				address <= 5'd11; 
				xreg <= x_read; 
				yreg <= y_read; 
				colourreg <= (current_block == 5'd11) ? 3'b001 : colour_read;  
				orientationreg <= orientation_read; 
			end
			
			if (loadXY == 5'd12) begin
				address <= 5'd12; 
				xreg <= x_read; 
				yreg <= y_read;
				colourreg <= (current_block == 5'd12) ? 3'b001 : colour_read;  
				orientationreg <= orientation_read; 	
			end
			
			if (loadXY == 5'd13) begin
				address <= 5'd13; 
				xreg <= x_read; 
				yreg <= y_read;
				colourreg <= (current_block == 5'd13) ? 3'b001 : colour_read; 
				orientationreg <= orientation_read; 	
			end
			
			if (loadXY == 5'd14) begin
				address <= 5'd14; 
				xreg <= x_read; 
				yreg <= y_read; 
				colourreg <= (current_block == 5'd14) ? 3'b001 : colour_read; 
				orientationreg <= orientation_read; 
			end
			
			if (loadXY == 5'd15) begin
				address <= 5'd15; 
				xreg <= x_read; 
				yreg <= y_read;
				colourreg <= (current_block == 5'd15) ? 3'b001 : colour_read; 
				orientationreg <= orientation_read; 
			end
			
			if (loadXY == 5'd16) begin
				address <= 5'd16; 
				xreg <= x_read; 
				yreg <= y_read;
				colourreg <= (current_block == 5'd16) ? 3'b001 : colour_read; 
				orientationreg <= orientation_read; 	
			end
		
		end
		
	end
	
	always @(posedge clk) begin
		if (reset) begin
			clear_counter [7:0] <= 8'd49;
			clear_counter [14:8] <= 7'd49; 
		end
		
		if (clear | win) begin
			
			if (clear_counter[7:0] == 8'd80) begin
				clear_counter [7:0] <= 7'd49; 
				clear_counter [14:8] <= clear_counter [14:8] + 1'b1; 
			end
			
			else if (clear_counter[14:8] == 7'd80) begin
				clear_counter [7:0] <= 8'd49;
				clear_counter [14:8] <= 7'd49;  
			end
			
			else begin
				clear_counter <= clear_counter + 1'b1; 
				x_draw <= clear_counter[7:0]; 
				y_draw <= clear_counter[14:8]; 
				if (!win) 
					colour_draw <= 3'b0; 
				else if (win && (clear_counter == {7'd61,8'd61} || clear_counter == {7'd62,8'd62} || clear_counter == {7'd63,8'd63} 
							|| clear_counter == {7'd64,8'd64} || clear_counter == {7'd65,8'd65} || clear_counter == {7'd66,8'd66}
							|| clear_counter == {7'd67,8'd67} || clear_counter == {7'd66,8'd67} || clear_counter == {7'd65,8'd68}
							|| clear_counter == {7'd64,8'd69} || clear_counter == {7'd63,8'd70} || clear_counter == {7'd62,8'd71}
							|| clear_counter == {7'd61,8'd72} || clear_counter == {7'd60,8'd73} || clear_counter == {7'd59,8'd74}
						   || clear_counter == {7'd58,8'd75}))
					colour_draw <= 3'b111;  
				else
					colour_draw <= 3'b010; 
			end
		end
		
		else begin
			if (reset) begin
				x_draw <= 8'd49; 
				y_draw <= 7'd49; 
				xy_counter <= 6'b0;
				colour_draw <= colourreg; 
			end
			
			if (plot) begin  
				
				if (orientation_read == 0) begin 	//horizontal
					x_draw <= xreg + xy_counter[5:2]; 
					y_draw <= yreg + xy_counter[1:0]; 
					colour_draw <= colourreg; 
					if (xy_counter [5:2] == 4'd8) begin
						if (xy_counter[1:0] == 2'd3) 
							xy_counter <= 6'd0;
						else
							xy_counter <= xy_counter + 1'b1; 
					end
					else 
						xy_counter <= xy_counter + 1'b1; 
				end 
				
				else begin							//vertical
					x_draw<= xreg + xy_counter[1:0]; 
					y_draw <= yreg + xy_counter[5:2]; 
					colour_draw <= colourreg; 
					if (xy_counter [5:2] == 4'd8) begin
						if (xy_counter[1:0] == 2'd3) 
							xy_counter <= 6'd0;
						else
							xy_counter <= xy_counter + 1'b1; 
					end
					else 
						xy_counter <= xy_counter + 1'b1; 
				end
			end
		end
	end
	
endmodule

//*****************************************************
//*****************************************************
//*****************************************************
//*****************************************************
//*****************************************************
//****************** MEMORY STORE *********************
//*****************************************************
//*****************************************************
//*****************************************************
//*****************************************************

module memoryStore(reset, clk, 
						 x_in, y_in, orientation_in, colour_in, 
						 wren, address,  x_out, y_out, orientation_out, colour_out,
						 drawRead, draw_wren, addressDraw, x_out_draw, y_out_draw, orientation_out_draw, colour_out_draw, 
						 stateRead, state_wren, addressState, x_out_state, y_out_state, orientation_out_state, colour_out_state); 

	input reset,										//reset button
			clk, 											//50 MHz clock 
			wren, draw_wren, state_wren; 			//write enable
			
	input [4:0] address, 					//address we're trying to access
					addressDraw,
					addressState; 
	input drawRead, stateRead; 
	
	input [7:0] x_in;							//x value we're trying to write into memory
	input [6:0] y_in; 						//y value we're trying to write into memory
	input orientation_in;		//orientation we're trying to write into memory 
	input [2:0] colour_in; 			//colour we're trying to write into memory

	output reg [7:0] x_out, x_out_draw, x_out_state; 			//x value we're trying to read out of memory
	output reg [6:0] y_out, y_out_draw, y_out_state;			//y value we're trying to read out of memory
	output reg orientation_out, orientation_out_draw, 
				  orientation_out_state;	 							//orientation we're trying to read out of memory
	output reg [2:0] colour_out, colour_out_draw, 
						  colour_out_state;								//colour we're trying to read out of memory

	reg [19:0] data_in;
	wire [19:0] data_out; 
	
	reg [4:0] add; 
	reg wren_choose; 

	always @(posedge clk) begin
		data_in [7:0] <= x_in; 
		data_in [14:8] <= y_in; 
		data_in [15] <= orientation_in; 
		data_in [18:16] <= colour_in; 
		data_in [19] <= 1'b0;
		
		if (drawRead) begin
			add <= addressDraw;
			wren_choose <= draw_wren; 
		end	
		else if (stateRead) begin 
			add <= addressState; 
			wren_choose <= state_wren; 
		end
		else begin
			add <= address;
			wren_choose <= wren;
		end
	end

	memory M1(.address(add), .clock(clk), .data(data_in), .wren(wren_choose), .q(data_out));
	
	always @(posedge clk) begin
		if (drawRead) begin
			x_out_draw <= data_out[7:0]; 
			y_out_draw <= data_out[14:8]; 
			orientation_out_draw <= data_out[15]; 
			colour_out_draw <= data_out[18:16];
		end
		else if (stateRead) begin
			x_out_state <= data_out[7:0]; 
			y_out_state <= data_out[14:8]; 
			orientation_out_state <= data_out[15]; 
			colour_out_state <= data_out[18:16];
		end
		else begin
			x_out <= data_out[7:0]; 
			y_out <= data_out[14:8]; 
			orientation_out <= data_out[15]; 
			colour_out <= data_out[18:16];  
		end
	end

endmodule



module boardStateMemoryHelper(address1, address2, clk50m, rowData_write, boardStateWren, boardStateWren2, stateRead, rowData_read); 

	input [4:0] address1, address2;
	input clk50m; 
	input [5:0] rowData_write; 
	input boardStateWren, boardStateWren2; 
	input stateRead; 
	
	output [5:0] rowData_read; 
	
	reg wren; 
	reg [4:0] address; 
	
	always @(posedge clk50m) begin
		if (stateRead) begin
			wren <= boardStateWren; 
			address <= address1; 
		end
		else begin
			wren <= boardStateWren2;
			address <= address2; 
		end
	end

	boardStateMemory B1(.address(address), .clock(clk50m), .data(rowData_write), 
							.wren(wren), .q(rowData_read)); 

endmodule

//******************************************************************************

// synopsys translate_off
`timescale 1 ps / 1 ps
// synopsys translate_on
module boardStateMemory (
	address,
	clock,
	data,
	wren,
	q);

	input	[4:0]  address;
	input	  clock;
	input	[5:0]  data;
	input	  wren;
	output	[5:0]  q;
`ifndef ALTERA_RESERVED_QIS
// synopsys translate_off
`endif
	tri1	  clock;
`ifndef ALTERA_RESERVED_QIS
// synopsys translate_on
`endif

	wire [5:0] sub_wire0;
	wire [5:0] q = sub_wire0[5:0];

	altsyncram	altsyncram_component (
				.address_a (address),
				.clock0 (clock),
				.data_a (data),
				.wren_a (wren),
				.q_a (sub_wire0),
				.aclr0 (1'b0),
				.aclr1 (1'b0),
				.address_b (1'b1),
				.addressstall_a (1'b0),
				.addressstall_b (1'b0),
				.byteena_a (1'b1),
				.byteena_b (1'b1),
				.clock1 (1'b1),
				.clocken0 (1'b1),
				.clocken1 (1'b1),
				.clocken2 (1'b1),
				.clocken3 (1'b1),
				.data_b (1'b1),
				.eccstatus (),
				.q_b (),
				.rden_a (1'b1),
				.rden_b (1'b1),
				.wren_b (1'b0));
	defparam
		altsyncram_component.clock_enable_input_a = "BYPASS",
		altsyncram_component.clock_enable_output_a = "BYPASS",
		altsyncram_component.intended_device_family = "Cyclone V",
		altsyncram_component.lpm_hint = "ENABLE_RUNTIME_MOD=NO",
		altsyncram_component.lpm_type = "altsyncram",
		altsyncram_component.numwords_a = 32,
		altsyncram_component.operation_mode = "SINGLE_PORT",
		altsyncram_component.outdata_aclr_a = "NONE",
		altsyncram_component.outdata_reg_a = "UNREGISTERED",
		altsyncram_component.power_up_uninitialized = "FALSE",
		altsyncram_component.read_during_write_mode_port_a = "NEW_DATA_NO_NBE_READ",
		altsyncram_component.widthad_a = 5,
		altsyncram_component.width_a = 6,
		altsyncram_component.width_byteena_a = 1;


endmodule

//******************************************************************************

module memory (address, clock, data, wren, q);

	input[4:0] address;
	input clock;
	input [19:0] data;
	input wren;
	output [19:0] q;

	`ifndef ALTERA_RESERVED_QIS
	// synopsys translate_off
	`endif
	tri1 clock;
	`ifndef ALTERA_RESERVED_QIS
	// synopsys translate_on
	`endif

	wire [19:0] sub_wire0;
	wire [19:0] q = sub_wire0[19:0];

	altsyncram altsyncram_component (
		.address_a (address),
		.clock0 (clock),
		.data_a (data),
		.wren_a (wren),
		.q_a (sub_wire0),
		.aclr0 (1'b0),
		.aclr1 (1'b0),
		.address_b (1'b1),
		.addressstall_a (1'b0),
		.addressstall_b (1'b0),
		.byteena_a (1'b1),
		.byteena_b (1'b1),
		.clock1 (1'b1),
		.clocken0 (1'b1),
		.clocken1 (1'b1),
		.clocken2 (1'b1),
		.clocken3 (1'b1),
		.data_b (1'b1),
		.eccstatus (),
		.q_b (),
		.rden_a (1'b1),
		.rden_b (1'b1),
		.wren_b (1'b0));

	defparam
	altsyncram_component.clock_enable_input_a = "BYPASS",
	altsyncram_component.clock_enable_output_a = "BYPASS",
	altsyncram_component.intended_device_family = "Cyclone V",
	altsyncram_component.lpm_hint = "ENABLE_RUNTIME_MOD=NO",
	altsyncram_component.lpm_type = "altsyncram",
	altsyncram_component.numwords_a = 32,
	altsyncram_component.operation_mode = "SINGLE_PORT",
	altsyncram_component.outdata_aclr_a = "NONE",
	altsyncram_component.outdata_reg_a = "UNREGISTERED",
	altsyncram_component.power_up_uninitialized = "FALSE",
	altsyncram_component.read_during_write_mode_port_a = "NEW_DATA_NO_NBE_READ",
	altsyncram_component.widthad_a = 5,
	altsyncram_component.width_a = 20,
	altsyncram_component.width_byteena_a = 1;
	
endmodule

module hex_decoder(hex_digit, segments);
    input [3:0] hex_digit;
    output reg [6:0] segments;
   
    always @(*)
        case (hex_digit)
            4'h0: segments = 7'b100_0000;
            4'h1: segments = 7'b111_1001;
            4'h2: segments = 7'b010_0100;
            4'h3: segments = 7'b011_0000;
            4'h4: segments = 7'b001_1001;
            4'h5: segments = 7'b001_0010;
            4'h6: segments = 7'b000_0010;
            4'h7: segments = 7'b111_1000;
            4'h8: segments = 7'b000_0000;
            4'h9: segments = 7'b001_1000;
            4'hA: segments = 7'b000_1000;
            4'hB: segments = 7'b000_0011;
            4'hC: segments = 7'b100_0110;
            4'hD: segments = 7'b010_0001;
            4'hE: segments = 7'b000_0110;
            4'hF: segments = 7'b000_1110;   
            default: segments = 7'b100_0000;
        endcase
endmodule

