
module toplevel();
	
	tophelper T1(); 
	
endmodule 











module drawFSM(reset, clk50, x_out, y_out, colour_out, plot_out);
	
	input reset, clk50; 
	output [7:0] x_out;
	output [6:0] y_out;
	output [2:0] colour_out; 
	output plot_out; 
	
	wire loadXY, clear, wren, resetCounter, dummy, clk;
	wire [3:0] count; 
	
	rateDivider r1(.reset(resetCounter), .clk50m(clk50), .clk50k(dummy), .clk50koffset(clk)); 
	
	control C0(.clk(clk), .reset(reset), .count(count), .loadXY(loadXY), 
			     .clear(clear), .plot(plot_out), .wren(wren), .resetCounter(resetCounter)); 
	
	datapath D0(.clk(clk50), .reset(reset), .loadXY(loadXY), .clear(clear), 
				   .plot(plot_out), .wren(wren), .count(count), 
					.x_out(x_out), .y_out(y_out), .colour_out(colour_out)); 
	
endmodule












module datapath(clk, reset, loadXY, clear, plot, wren, count, x_out, y_out, colour_out); 
	
	input clk, reset, loadXY, clear, plot, wren; 
	output reg [3:0] count; 
	output reg [7:0] x_out;
	output reg [6:0] y_out;
	output reg [2:0] colour_out; 
	
	wire orientation;
	wire [7:0] x_initial; 
	wire [6:0] y_initial; 
	wire [2:0] colour; 
	
	reg [5:0] address_count; 
	reg [3:0] address; 
	reg [7:0] xreg;
	reg [6:0] yreg; 
	reg [14:0] clear_counter; 
	reg [5:0] xy_counter; 
	
	always @(posedge clk) begin
		if (reset) begin
			address <= 4'b0; 
			address_count <= 6'b0; 
		end
		else if (address_count == 6'd40) begin
			address_count <= 6'b0; 
			address <= address + 1'b1;
		end	
		else
			address_count <= address_count + 1'b1; 
	end
	
	memoryStore M2(.reset(reset), .wren(wren), .clk(clk), 
				   .address(address), .x_in(x_initial), .y_in(y_initial), .orientation_in(orientation), .colour_in(colour_out), 
					.x_out(x_initial), .y_out(y_initial), .orientation_out(orientation), .colour_out(colour));
		
	always @(posedge clk) begin
		if (loadXY) begin
			xreg <= x_initial; 
			yreg <= y_initial; 
		end

	end
	
	always @(posedge clk) begin
		if (clear) begin
			if (reset) begin
				clear_counter [7:0] <= 8'd49;
				clear_counter [14:8] <= 8'd49; 
			end
			
			else if (clear_counter[7:0] == 8'd80) begin
				clear_counter [7:0] <= 8'd49; 
				clear_counter [14:8] <= clear_counter [14:8] + 1'b1; 
			end
			
			else if (clear_counter[14:8] == 8'd80) begin
				clear_counter [7:0] <= 8'd49;
				clear_counter [14:8] <= 8'd49;  
			end
			
			else begin
				clear_counter <= clear_counter + 1'b1; 
				x_out <= clear_counter[7:0]; 
				y_out <= clear_counter[14:8]; 
				colour_out <= 3'b0; 
			end
		end
		
		else begin
			if (reset) begin
				x_out <= 8'b0; 
				y_out <= 7'b0; 
				xy_counter <= 6'b0; 
				colour_out <= colour; 
			end
			
			if (plot) begin  
				if (orientation == 0) begin 	//horizontal
					x_out <= xreg + xy_counter[5:2]; 
					y_out <= yreg + xy_counter[1:0]; 
					colour_out <= colour; 
					if (xy_counter [5:2] == 4'd10) 
						xy_counter <= 6'd0;
					else 
						xy_counter <= xy_counter + 1; 
				end 
				
				else begin							//vertical
					x_out <= xreg + xy_counter[1:0]; 
					y_out <= yreg + xy_counter[5:2]; 
					colour_out <= colour; 
					if (xy_counter [5:2] == 4'd10) 
						xy_counter <= 6'd0;
					else 
						xy_counter <= xy_counter + 1;
				end
			end
		end
	end
	
endmodule 









module control(clk, reset, count, loadXY, clear, plot, wren, resetCounter); 
	
	input clk, reset;
	input [3:0] count; 
	output reg loadXY, clear, plot, wren, resetCounter;
	
	reg [1:0] current_state, next_state; 
	
	localparam 	CLEAR = 2'd0,
					LOADXY = 2'd1, 
					DRAW = 2'd2, 
					RESETCOUNTER = 2'd3; 
	
	always @(*)
	begin: state_table
		case (current_state) 
			RESETCOUNTER: next_state = CLEAR; 
			CLEAR: next_state = LOADXY; 
			LOADXY: next_state = DRAW; 
			DRAW: next_state = CLEAR; 
			default: next_state = RESETCOUNTER; 
		endcase
	end
	
	always @(*)
	begin: enable_signals
		loadXY = 1'b0; 
		plot = 1'b0; 
		clear = 1'b0; 
		wren = 1'b0; 
		case (current_state) 
			RESETCOUNTER: resetCounter = 1'b1; 
			CLEAR: clear = 1'b0; 
			LOADXY: loadXY = 1'b1; 
			DRAW: plot = 1'b1; 
		endcase
	end
	
	always @(posedge clk) 
		begin: state_FFs 
			if (reset)
				current_state <= CLEAR; 
			else
				current_state <= next_state; 
	end
	
	
endmodule













module rateDivider(reset, clk50m, clk50k, clk50koffset);
	
	input reset; 
	input clk50m; 				//CLOCK_50, 50MHz 
	output reg clk50k; 			//50kHz clock; used to drive moveblock FSM
	output reg clk50koffset; 	//50kHz clock that is 25,000 cycles out of sync with clk1; used to drive draw FSM 
	
	reg [9:0] count50k;			//counts up to 999, equal to 499 at reset
	reg [9:0] count50koffset; 	//counts up to 999, equal to 0 at reset
	
	
	//clk1 
	always @(posedge clk50m) begin
		if (reset) begin
			count50k <= 10'd499; 
			clk50k <= 1'b0; 
		end
		else if (count50k == 10'd999) begin
			count50k <= 10'd0; 
			clk50k <= 1'b1; 
		end
		else begin
			count50k <= count50k + 10'd1; 
			clk50k <= 1'b0; 
		end
	end
	
	
	//clk1offset50
	always @(posedge clk50m) begin
		if (reset) begin
			count50k <= 10'd0; 
			clk50k <= 1'b0; 
		end
		else if (count50k == 10'd999) begin
			count50k <= 10'd0; 
			clk50k <= 1'b1; 
		end
		else begin
			count50k <= count50k + 10'd1; 
			clk50k <= 1'b0; 
		end
	end
	
	//add additional clocks as needed
	
endmodule 













module memoryStore(reset, wren, clk, address, x_in, y_in, orientation_in, colour_in, 
		   x_out, y_out, orientation_out, colour_out); 

	input reset, clk, wren; 
	
	input [3:0] address; 
	input [7:0] x_in; 
	input [6:0] y_in; 
	input orientation_in; 
	input [2:0] colour_in; 
	
	output [7:0] x_out; 
	output [6:0] y_out;
	output orientation_out; 
	output [2:0] colour_out;

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

	assign x_out = data_out[7:0]; 
	assign y_out = data_out[14:8]; 
	assign orientation_out = data_out[15]; 
	assign colour_out = data_out[18:16]; 

endmodule



















// Abstraction — Don't need to worry about anything below this; trust that it works properly

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