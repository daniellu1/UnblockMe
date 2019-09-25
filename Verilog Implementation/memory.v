`timescale 1 ps / 1 ps

module testMemory(SW, KEY, CLOCK_50, HEX0);
	
	input [4:0] SW; 
	input [0:0] KEY; 
	input CLOCK_50; 
	output [6:0] HEX0; 
	
	wire reset = ~KEY[0];
	wire [4:0] address = SW[4:0];

	wire [19:0] stored_value; 
	
	helper u0(.reset(reset), .address(address), .clk(CLOCK_50), .stored_value(stored_value)); 
	
	hex_decoder(stored_value[3:0], HEX0[6:0]); 
	
endmodule 

module memoryStore(reset, wren, clk, address, x_in, y_in, orientation_in, colour_in, x_out, y_out, orientation_out, colour_out); 

	input reset, clk, wren; 
	
	input [4:0] address; 
	input [7:0] x_in; 
	input [6:0] y_in; 
	input orientation_in; 
	input [2:0] colour_in; 

	reg [19:0] data_in;
	wire [19:0] data_out; 
	reg [4:0] add; 	

	always @(posedge clk) begin
		data_in [7:0] <= x_in; 
		data_in [14:8] <= y_in; 
		data_in [15] <= orientation_in; 
		data_in [18:16] = colour_in; 
	end
	
	memory M1(.address(add), .clock(clk), .data(data_in), .wren(wren), .q(data_out)); 

endmodule

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
            default: segments = 7'h7f;
        endcase

endmodule