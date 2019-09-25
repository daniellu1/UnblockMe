state_of_board S1(.aclr(clear), .address(address_new), .clock(CLOCK_50), .data(data_out),
						.wren(wren_new), .q(data(data_in)); 

module update_state(
	 input clk,
	 input resetn,
	 input move_occured, //connects to move block FSM
	 input [7:0] x_old, //connects to old memory
	 input [6:0] y_old, //connects to old memory
	 input orientation_old, //connects to old memory
	 input [5:0] data_in_new, //connects to new memory
	 input [5:0] data_out_new, //connects to new memory
	 output reg clear, //connects to new memory
	 output reg [4:0] address_new, //connects to new memory
	 output reg wren_new,
	 output reg wren_old, //connects to old memory
	 output reg [3:0] address_old //connects to old memory
	 );
	 
	 wire read, updated;
	 wire [3:0] address_c;//address generated from control path
	 wire enable;
	 wire [7:0] x_new;
	 wire [6:0] y_new;
	 wire orientation_new;
	 wire clear;
	 
	 update_state_control C1  (.clk(clk), .resetn(resetn), .move_occured(move_occured), 
									   .address(address_c), .read(read), .updated(updated), .clear(clear));
	 update_state_datapath D1 (.clk(clk), .resetn(resetn), .address_in(address_c), .x_in(x_old),
										.y_in(y_old), .orientation_in(orientation_old), .read(read),
										.updated(updated), .address_out(address_old), .writeEnableOld(wren_old),
										.enable(enable), .x_out(x_new), .y_out(y_new), .orientation_out(orientation_new));
	 update_one_block U1		  (.clk(clk), .resetn(resetn), .x(x_new), .y(y_new), .orientation(orientation_new), 
										.enable(enable), .data_in(data_in_new), .data_out(data_out_new),
										.address(address_new), .writeEnableNew(wren_new));										
endmodule
	
module update_state_control(
	 input clk,
	 input resetn,
	 input move_occured,
	 output reg [3:0] address,
	 output reg read, updated,
	 output reg clear
	 );
	 
	 reg [5:0] current_state, next_state; 
    
    localparam  RESET = 6'd0,
					 READ_FROM_BLOCK_MEMORY1 = 6'd1,
					 UPDATE_ONE_BLOCK1 = 6'd2,
					 READ_FROM_BLOCK_MEMORY2 = 6'd3,
					 UPDATE_ONE_BLOCK2 = 6'd4,
					 READ_FROM_BLOCK_MEMORY3 = 6'd5,
					 UPDATE_ONE_BLOCK3 = 6'd6,
					 READ_FROM_BLOCK_MEMORY4 = 6'd7,
					 UPDATE_ONE_BLOCK4 = 6'd8,
					 READ_FROM_BLOCK_MEMORY5 = 6'd9,
					 UPDATE_ONE_BLOCK5 = 6'd10,
					 READ_FROM_BLOCK_MEMORY6 = 6'd11,
					 UPDATE_ONE_BLOCK6 = 6'd12,
					 READ_FROM_BLOCK_MEMORY7 = 6'd13,
					 UPDATE_ONE_BLOCK7 = 6'd14,
					 READ_FROM_BLOCK_MEMORY8 = 6'd15,
					 UPDATE_ONE_BLOCK8 = 6'd16,
					 READ_FROM_BLOCK_MEMORY9 = 6'd17,
					 UPDATE_ONE_BLOCK9 = 6'd18,
					 READ_FROM_BLOCK_MEMORY10 = 6'd19,
					 UPDATE_ONE_BLOCK10 = 6'd20,
					 READ_FROM_BLOCK_MEMORY11 = 6'd21,
					 UPDATE_ONE_BLOCK11 = 6'd22,
					 READ_FROM_BLOCK_MEMORY12 = 6'd23,
					 UPDATE_ONE_BLOCK12 = 6'd24,
					 READ_FROM_BLOCK_MEMORY13 = 6'd25,
					 UPDATE_ONE_BLOCK13 = 6'd26,
					 READ_FROM_BLOCK_MEMORY14 = 6'd27,
					 UPDATE_ONE_BLOCK14 = 6'd28,
					 READ_FROM_BLOCK_MEMORY15 = 6'd29,
					 UPDATE_ONE_BLOCK15 = 6'd30,
					 READ_FROM_BLOCK_MEMORY16 = 6'd31,
					 UPDATE_ONE_BLOCK16 = 6'd32,
					 WAIT = 6'd33;
					 
    always@(*)
    begin: state_table 
            case (current_state)
					 RESET: next_state = READ_FROM_BLOCK_MEMORY1;
					 READ_FROM_BLOCK_MEMORY1: next_state = UPDATE_ONE_BLOCK1;
					 UPDATE_ONE_BLOCK1: next_state = READ_FROM_BLOCK_MEMORY2;
					 READ_FROM_BLOCK_MEMORY2: next_state = UPDATE_ONE_BLOCK2;
					 UPDATE_ONE_BLOCK2: next_state = READ_FROM_BLOCK_MEMORY3;
					 READ_FROM_BLOCK_MEMORY3: next_state = UPDATE_ONE_BLOCK3;
					 UPDATE_ONE_BLOCK3: next_state = READ_FROM_BLOCK_MEMORY4;
					 READ_FROM_BLOCK_MEMORY4: next_state = UPDATE_ONE_BLOCK4;
					 UPDATE_ONE_BLOCK4: next_state = READ_FROM_BLOCK_MEMORY5;
					 READ_FROM_BLOCK_MEMORY5: next_state = UPDATE_ONE_BLOCK5;
					 UPDATE_ONE_BLOCK5: next_state = READ_FROM_BLOCK_MEMORY6;
					 READ_FROM_BLOCK_MEMORY6: next_state = UPDATE_ONE_BLOCK6;
					 UPDATE_ONE_BLOCK6: next_state = READ_FROM_BLOCK_MEMORY7;
					 READ_FROM_BLOCK_MEMORY7: next_state = UPDATE_ONE_BLOCK7;
					 UPDATE_ONE_BLOCK7: next_state = READ_FROM_BLOCK_MEMORY8;
					 READ_FROM_BLOCK_MEMORY8: next_state = UPDATE_ONE_BLOCK8;
					 UPDATE_ONE_BLOCK8: next_state = READ_FROM_BLOCK_MEMORY9;
					 READ_FROM_BLOCK_MEMORY9: next_state = UPDATE_ONE_BLOCK9;
					 UPDATE_ONE_BLOCK9: next_state = READ_FROM_BLOCK_MEMORY10;
					 READ_FROM_BLOCK_MEMORY10: next_state = UPDATE_ONE_BLOCK10;
					 UPDATE_ONE_BLOCK10: next_state = READ_FROM_BLOCK_MEMORY11;
					 READ_FROM_BLOCK_MEMORY11: next_state = UPDATE_ONE_BLOCK11;
					 UPDATE_ONE_BLOCK11: next_state = READ_FROM_BLOCK_MEMORY12;
					 READ_FROM_BLOCK_MEMORY12: next_state = UPDATE_ONE_BLOCK12;
					 UPDATE_ONE_BLOCK12: next_state = READ_FROM_BLOCK_MEMORY13;
					 READ_FROM_BLOCK_MEMORY13: next_state = UPDATE_ONE_BLOCK13;
					 UPDATE_ONE_BLOCK13: next_state = READ_FROM_BLOCK_MEMORY14;
					 READ_FROM_BLOCK_MEMORY14: next_state = UPDATE_ONE_BLOCK14;
					 UPDATE_ONE_BLOCK14: next_state = READ_FROM_BLOCK_MEMORY15;
					 READ_FROM_BLOCK_MEMORY15: next_state = UPDATE_ONE_BLOCK15;
					 UPDATE_ONE_BLOCK15: next_state = READ_FROM_BLOCK_MEMORY16;
					 READ_FROM_BLOCK_MEMORY16: next_state = UPDATE_ONE_BLOCK16;
					 UPDATE_ONE_BLOCK16: next_state = move_occured ? WAIT : UPDATE_ONE_BLOCK16;
					 WAIT: next_state = move_occured ? WAIT : RESET;
            default:     next_state = RESET;
        endcase
    end
	 
	 always @(*)
    begin: enable_signals
		  read = 1'b0; 
		  updated = 1'b0;
		  clear = 1'b0;

        case (current_state)
				RESET: begin 
				clear = 1'b1;
				end
				READ_FROM_BLOCK_MEMORY1: begin
				read = 1'b1;
				address = 4'b0000;
				end
				UPDATE_ONE_BLOCK1: begin
				updated = 1'b1;
				end
				READ_FROM_BLOCK_MEMORY2: begin
				read = 1'b1;
				address = 4'b0001;
				end
				UPDATE_ONE_BLOCK2: begin
				updated = 1'b1;
				end
				READ_FROM_BLOCK_MEMORY3: begin
				read = 1'b1;
				address = 4'b0010;
				end
				UPDATE_ONE_BLOCK3: begin
				updated = 1'b1;
				end
				READ_FROM_BLOCK_MEMORY4: begin
				read = 1'b1;
				address = 4'b0011;
				end
				UPDATE_ONE_BLOCK4: begin
				updated = 1'b1;
				end
				READ_FROM_BLOCK_MEMORY5: begin
				read = 1'b1;
				address = 4'b0100;
				end
				UPDATE_ONE_BLOCK5: begin
				updated = 1'b1;
				end
				READ_FROM_BLOCK_MEMORY6: begin
				read = 1'b1;
				address = 4'b0101;
				end
				UPDATE_ONE_BLOCK6: begin
				updated = 1'b1;
				end
				READ_FROM_BLOCK_MEMORY7: begin
				read = 1'b1;
				address = 4'b0110;
				end
				UPDATE_ONE_BLOCK7: begin
				updated = 1'b1;
				end
				READ_FROM_BLOCK_MEMORY8: begin
				read = 1'b1;
				address = 4'b0111;
				end
				UPDATE_ONE_BLOCK8: begin
				updated = 1'b1;
				end
				READ_FROM_BLOCK_MEMORY9: begin
				read = 1'b1;
				address = 4'b1000;
				end
				UPDATE_ONE_BLOCK9: begin
				updated = 1'b1;
				end
				READ_FROM_BLOCK_MEMORY10: begin
				read = 1'b1;
				address = 4'b1001;
				end
				UPDATE_ONE_BLOCK10: begin
				updated = 1'b1;
				end
				READ_FROM_BLOCK_MEMORY11: begin
				read = 1'b1;
				address = 4'b1010;
				end
				UPDATE_ONE_BLOCK11: begin
				updated = 1'b1;
				end
				READ_FROM_BLOCK_MEMORY12: begin
				read = 1'b1;
				address = 4'b1011;
				end
				UPDATE_ONE_BLOCK12: begin
				updated = 1'b1;
				end
				READ_FROM_BLOCK_MEMORY13: begin
				read = 1'b1;
				address = 4'b1100;
				end
				UPDATE_ONE_BLOCK13: begin
				updated = 1'b1;
				end
				READ_FROM_BLOCK_MEMORY14: begin
				read = 1'b1;
				address = 4'b1101;
				end
				UPDATE_ONE_BLOCK14: begin
				updated = 1'b1;
				end
				READ_FROM_BLOCK_MEMORY15: begin
				read = 1'b1;
				address = 4'b1110;
				end
				UPDATE_ONE_BLOCK15: begin
				updated = 1'b1;
				end
				READ_FROM_BLOCK_MEMORY16: begin
				read = 1'b1;
				address = 4'b1111;
				end
				UPDATE_ONE_BLOCK16: begin
				updated = 1'b1;
				end
        endcase
    end
 
    always@(posedge clk)
    begin: state_FFs
        if(!resetn)
            current_state <= RESET;
        else
            current_state <= next_state;
    end
endmodule 

module update_state_datapath (
	 input clk,
    input resetn,
	 input [3:0] address_in, //connects to control path
	 input [7:0] x_in, //connects to old memory
	 input [6:0] y_in, //connects to old memory
	 input orientation_in, //connects to old memory
    input read, updated, //connects to control path
	 output reg [4:0] address_out, //connects to old memory
	 output reg writeEnableOld, //connects to old memory
	 output reg enable, //connects to update one block
	 output reg [7:0] x_out, //connects to update one block
	 output reg [6:0] y_out, //connects to update one block
	 output reg orientation_out //connects to update one block
	 );

    always@(posedge clk) begin
        if(!resetn) begin 
				address_out <= 5'b0;
				writeEnableOld <= 1'b0;
				enable <= 1'b0;
				x_out <= 8'b0;
				y_out <= 7'b0;
				orientation_out <= 1'b0;
        end
        else begin
				if (read) begin
					address_out <= address_in;
					writeEnableOld <= 1'b0;
					enable <= 1'b1;
				end
				if(updated) begin 
					address_out <= address_in;
					writeEnableOld <= 1'b0;
					x_out <= x_in;
					y_out <= y_in;
					orientation_out <= orientation_in;
					enable <= 1'b0;
				end
        end
    end
  
endmodule 

module update_one_block(
	 input clk, 
	 input resetn, 
	 input [7:0] x, //connects to update state
	 input [6:0] y, //connects to update state
	 input orientation, //connects to update state
	 input enable, //connects to update state
	 input [5:0] data_in, //connects to new memory
	 output [5:0] data_out, //connects to new memory
	 output [4:0] address, //connects to new memory
	 output writeEnableNew //connects to new memory
	 );
	 
	 wire ld_xy, ld_new, ld_r, add_x, add_y;
	 wire orientation_out;
	 update_one_block_control C1  (.clk(clk), .resetn(resetn), .orientation_out(orientation_out), 
										.ld_xy(ld_xy), .ld_new(ld_new), .ld_r(ld_r), .add_x(add_x), 
										.add_y(add_y), .enable(enable));
	 update_one_block_datapath D1 (.clk(clk), .resetn(resetn), .x_in(x), .y_in(y), .data_in(data), 
										.orientation_in(orientation), .ld_xy(ld_xy), .ld_new(ld_new), 
										.ld_r(ld_r), .add_x(add_x), .add_y(add_y), .address_new_out(address),
										.data_out(data_out), .orientation_out(orientation_out),
										.writeEnableNew(writeEnableNew));
endmodule
	 
module update_one_block_control(
	 input clk,
	 input resetn,
	 input orientation_out,
	 input enable, 
	 output reg ld_xy, ld_new, ld_r, add_x, add_y
	 );
	 
	 reg [5:0] current_state, next_state; 
    
    localparam  LOADXY = 5'd0, 
					 LOAD_NEW1 = 5'd1,
                LOAD_R1 = 5'd2,
					 HORIZONTAL1 = 5'd3,
					 VERTICAL1 = 5'd4,
					 LOAD_NEW2 = 5'd5,
					 LOAD_R2 = 5'd6,
					 WAIT = 5'd15;
					 
    always@(*)
    begin: state_table 
            case (current_state)
					 LOADXY: next_state = LOAD_NEW1; 
					 LOAD_NEW1: next_state = LOAD_R1;
					 LOAD_R1: next_state = orientation_out ? HORIZONTAL1 : VERTICAL1;
					 HORIZONTAL1: next_state = LOAD_NEW2;
					 VERTICAL1: next_state = LOAD_NEW2;
					 LOAD_NEW2: next_state = LOAD_R2;
					 LOAD_R2: next_state = enable ? WAIT : LOAD_R2;
					 WAIT: next_state = enable ? WAIT : LOADXY; //cycle only runs once
            default:     next_state = LOADXY;
        endcase
    end 
	 
    always @(*)
    begin: enable_signals
		  ld_xy = 1'b0; 
		  ld_new = 1'b0;
		  ld_r = 1'b0;
		  add_x = 1'b0;
		  add_y = 1'b0;

        case (current_state)
				LOADXY: begin
					ld_xy = 1'b1; 
				end
				LOAD_NEW1: begin
					ld_new = 1'b1;
				end
				LOAD_R1: begin
					ld_r = 1'b1;
				end
				HORIZONTAL1: begin
					add_x = 1'b1;
				end
				VERTICAL1: begin
					add_y = 1'b1;
				end
				LOAD_NEW2: begin
					ld_new = 1'b1;
				end
				LOAD_R2: begin
					ld_r = 1'b1;
				end
        endcase
    end
 
    always@(posedge clk)
    begin: state_FFs
        if(!resetn)
            current_state <= LOADXY;
        else
            current_state <= next_state;
    end
endmodule 

module update_one_block_datapath (
	 input clk,
    input resetn,
	 input [7:0] x_in,
	 input [6:0] y_in,
	 input [5:0] data_in,
	 input orientation_in,
    input ld_xy, ld_new, ld_r, add_x, add_y,
	 output reg [4:0] address_new_out,
    output reg [5:0] data_out,
	 output reg orientation_out,
	 output reg writeEnableNew
	 );
reg [7:0] x;
reg [6:0] y;
reg [5:0] Data_in;
reg [2:0] address;
reg [5:0] Data_out;

    always@(posedge clk) begin
        if(!resetn) begin 
				x <= 8'b0;
				y <= 7'b0;
				address <= 3'b0;
				Data_in <= 6'b0;
				Data_out <= 6'b0;
        end
        else begin
				if(ld_xy) begin //takes in x and y values from existing register, output address is computed 
					x <= x_in;
					y <= y_in;
					orientation_out <= orientation_in;
				end
				if(ld_new) begin //takes in data at output address
					writeEnableNew <= 1'b0;
					Data_in <= data_in;
					address_new_out <= address;
				end
				if(ld_r) begin //adds output data to existing data
					 writeEnableNew <= 1'b1;
					 address_new_out <= address;
                data_out <= Data_out;
				end
				if (add_x) begin //increments x by 5
					x <= x+3'd5;
				end
				if (add_y) begin //increments y by 5
					y <= y+3'd5;
				end
        end
    end
 
    always @(*)
    begin  
        case (y)
			7'd50: begin
				address = 3'd1;
			end
			7'd55: begin
				address = 3'd2;
			end
			7'd60: begin
				address = 3'd3;
			end
			7'd65: begin
				address = 3'd4;
			end
			7'd70: begin
				address = 3'd5;
			end
			7'd85: begin
				address = 3'd6;
			end
			default: begin
				address = 3'd0;
			end
			endcase 
    end
	 
	 always @(*)
	 begin
		case (x)
			7'd50: begin
				Data_out = Data_in + 6'd32;
			end
			7'd55: begin
				Data_out = Data_in + 6'd16;
			end
			7'd60: begin
				Data_out = Data_in + 6'd8;
			end
			7'd65: begin
				Data_out = Data_in + 6'd4;
			end
			7'd70: begin
				Data_out = Data_in + 6'd2;
			end
			7'd85: begin
				Data_out = Data_in + 6'd1;
			end
			default: begin
				Data_out = Data_in + 6'd0;
			end
			endcase
	 end
	 
endmodule 

// megafunction wizard: %RAM: 1-PORT%
// GENERATION: STANDARD
// VERSION: WM1.0
// MODULE: altsyncram 

// ============================================================
// File Name: state_of_board.v
// Megafunction Name(s):
// 			altsyncram
//
// Simulation Library Files(s):
// 			altera_mf
// ============================================================
// ************************************************************
// THIS IS A WIZARD-GENERATED FILE. DO NOT EDIT THIS FILE!
//
// 18.1.0 Build 625 09/12/2018 SJ Lite Edition
// ************************************************************


//Copyright (C) 2018  Intel Corporation. All rights reserved.
//Your use of Intel Corporation's design tools, logic functions 
//and other software and tools, and its AMPP partner logic 
//functions, and any output files from any of the foregoing 
//(including device programming or simulation files), and any 
//associated documentation or information are expressly subject 
//to the terms and conditions of the Intel Program License 
//Subscription Agreement, the Intel Quartus Prime License Agreement,
//the Intel FPGA IP License Agreement, or other applicable license
//agreement, including, without limitation, that your use is for
//the sole purpose of programming logic devices manufactured by
//Intel and sold by Intel or its authorized distributors.  Please
//refer to the applicable agreement for further details.


// synopsys translate_off
`timescale 1 ps / 1 ps
// synopsys translate_on
module state_of_board (
	aclr,
	address,
	clock,
	data,
	wren,
	q);

	input	  aclr;
	input	[4:0]  address;
	input	  clock;
	input	[5:0]  data;
	input	  wren;
	output	[5:0]  q;
`ifndef ALTERA_RESERVED_QIS
// synopsys translate_off
`endif
	tri0	  aclr;
	tri1	  clock;
`ifndef ALTERA_RESERVED_QIS
// synopsys translate_on
`endif

	wire [5:0] sub_wire0;
	wire [5:0] q = sub_wire0[5:0];

	altsyncram	altsyncram_component (
				.aclr0 (aclr),
				.address_a (address),
				.clock0 (clock),
				.data_a (data),
				.wren_a (wren),
				.q_a (sub_wire0),
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
		altsyncram_component.outdata_aclr_a = "CLEAR0",
		altsyncram_component.outdata_reg_a = "UNREGISTERED",
		altsyncram_component.power_up_uninitialized = "FALSE",
		altsyncram_component.read_during_write_mode_port_a = "NEW_DATA_NO_NBE_READ",
		altsyncram_component.widthad_a = 5,
		altsyncram_component.width_a = 6,
		altsyncram_component.width_byteena_a = 1;


endmodule

// ============================================================
// CNX file retrieval info
// ============================================================
// Retrieval info: PRIVATE: ADDRESSSTALL_A NUMERIC "0"
// Retrieval info: PRIVATE: AclrAddr NUMERIC "0"
// Retrieval info: PRIVATE: AclrByte NUMERIC "0"
// Retrieval info: PRIVATE: AclrData NUMERIC "0"
// Retrieval info: PRIVATE: AclrOutput NUMERIC "1"
// Retrieval info: PRIVATE: BYTE_ENABLE NUMERIC "0"
// Retrieval info: PRIVATE: BYTE_SIZE NUMERIC "8"
// Retrieval info: PRIVATE: BlankMemory NUMERIC "1"
// Retrieval info: PRIVATE: CLOCK_ENABLE_INPUT_A NUMERIC "0"
// Retrieval info: PRIVATE: CLOCK_ENABLE_OUTPUT_A NUMERIC "0"
// Retrieval info: PRIVATE: Clken NUMERIC "0"
// Retrieval info: PRIVATE: DataBusSeparated NUMERIC "1"
// Retrieval info: PRIVATE: IMPLEMENT_IN_LES NUMERIC "0"
// Retrieval info: PRIVATE: INIT_FILE_LAYOUT STRING "PORT_A"
// Retrieval info: PRIVATE: INIT_TO_SIM_X NUMERIC "0"
// Retrieval info: PRIVATE: INTENDED_DEVICE_FAMILY STRING "Cyclone V"
// Retrieval info: PRIVATE: JTAG_ENABLED NUMERIC "0"
// Retrieval info: PRIVATE: JTAG_ID STRING "NONE"
// Retrieval info: PRIVATE: MAXIMUM_DEPTH NUMERIC "0"
// Retrieval info: PRIVATE: MIFfilename STRING ""
// Retrieval info: PRIVATE: NUMWORDS_A NUMERIC "32"
// Retrieval info: PRIVATE: RAM_BLOCK_TYPE NUMERIC "0"
// Retrieval info: PRIVATE: READ_DURING_WRITE_MODE_PORT_A NUMERIC "3"
// Retrieval info: PRIVATE: RegAddr NUMERIC "1"
// Retrieval info: PRIVATE: RegData NUMERIC "1"
// Retrieval info: PRIVATE: RegOutput NUMERIC "0"
// Retrieval info: PRIVATE: SYNTH_WRAPPER_GEN_POSTFIX STRING "0"
// Retrieval info: PRIVATE: SingleClock NUMERIC "1"
// Retrieval info: PRIVATE: UseDQRAM NUMERIC "1"
// Retrieval info: PRIVATE: WRCONTROL_ACLR_A NUMERIC "0"
// Retrieval info: PRIVATE: WidthAddr NUMERIC "5"
// Retrieval info: PRIVATE: WidthData NUMERIC "6"
// Retrieval info: PRIVATE: rden NUMERIC "0"
// Retrieval info: LIBRARY: altera_mf altera_mf.altera_mf_components.all
// Retrieval info: CONSTANT: CLOCK_ENABLE_INPUT_A STRING "BYPASS"
// Retrieval info: CONSTANT: CLOCK_ENABLE_OUTPUT_A STRING "BYPASS"
// Retrieval info: CONSTANT: INTENDED_DEVICE_FAMILY STRING "Cyclone V"
// Retrieval info: CONSTANT: LPM_HINT STRING "ENABLE_RUNTIME_MOD=NO"
// Retrieval info: CONSTANT: LPM_TYPE STRING "altsyncram"
// Retrieval info: CONSTANT: NUMWORDS_A NUMERIC "32"
// Retrieval info: CONSTANT: OPERATION_MODE STRING "SINGLE_PORT"
// Retrieval info: CONSTANT: OUTDATA_ACLR_A STRING "CLEAR0"
// Retrieval info: CONSTANT: OUTDATA_REG_A STRING "UNREGISTERED"
// Retrieval info: CONSTANT: POWER_UP_UNINITIALIZED STRING "FALSE"
// Retrieval info: CONSTANT: READ_DURING_WRITE_MODE_PORT_A STRING "NEW_DATA_NO_NBE_READ"
// Retrieval info: CONSTANT: WIDTHAD_A NUMERIC "5"
// Retrieval info: CONSTANT: WIDTH_A NUMERIC "6"
// Retrieval info: CONSTANT: WIDTH_BYTEENA_A NUMERIC "1"
// Retrieval info: USED_PORT: aclr 0 0 0 0 INPUT GND "aclr"
// Retrieval info: USED_PORT: address 0 0 5 0 INPUT NODEFVAL "address[4..0]"
// Retrieval info: USED_PORT: clock 0 0 0 0 INPUT VCC "clock"
// Retrieval info: USED_PORT: data 0 0 6 0 INPUT NODEFVAL "data[5..0]"
// Retrieval info: USED_PORT: q 0 0 6 0 OUTPUT NODEFVAL "q[5..0]"
// Retrieval info: USED_PORT: wren 0 0 0 0 INPUT NODEFVAL "wren"
// Retrieval info: CONNECT: @aclr0 0 0 0 0 aclr 0 0 0 0
// Retrieval info: CONNECT: @address_a 0 0 5 0 address 0 0 5 0
// Retrieval info: CONNECT: @clock0 0 0 0 0 clock 0 0 0 0
// Retrieval info: CONNECT: @data_a 0 0 6 0 data 0 0 6 0
// Retrieval info: CONNECT: @wren_a 0 0 0 0 wren 0 0 0 0
// Retrieval info: CONNECT: q 0 0 6 0 @q_a 0 0 6 0
// Retrieval info: GEN_FILE: TYPE_NORMAL state_of_board.v TRUE
// Retrieval info: GEN_FILE: TYPE_NORMAL state_of_board.inc FALSE
// Retrieval info: GEN_FILE: TYPE_NORMAL state_of_board.cmp FALSE
// Retrieval info: GEN_FILE: TYPE_NORMAL state_of_board.bsf FALSE
// Retrieval info: GEN_FILE: TYPE_NORMAL state_of_board_inst.v FALSE
// Retrieval info: GEN_FILE: TYPE_NORMAL state_of_board_bb.v TRUE
// Retrieval info: LIB_FILE: altera_mf
