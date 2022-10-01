// Author: Dylan Boland
//
// This is a module which acts as a bank of registers that can be written to
// and read from. The depth of the memory (the number of registers) can be
// specified by changing the parameter DEPTH of the module. The data width
// or size of the registers can be altered by using the DATA_WIDTH parameter.
// The address width (ADDR_WIDTH) is another parameter, and is related to the
// depth by:
//
// ADDR_WIDTH = log2(DEPTH)
//
// For this reason, the parameter DEPTH should be a power of two, as would
// often be the case for memory modules anyway.
// The value that all of the registers hold on reset is dictated by the
// RESET_VAL parameter. 

module mem_block
	# (
		parameter DATA_WIDTH = 8,
		parameter DEPTH = 32,
        parameter ADDR_WIDTH = $clog2(DEPTH),
		parameter RESET_VAL = 'h00
	)
	(
	 input clk,                        // input clock signal
	 input reset,                      // active-high reset input pin
	 input [ADDR_WIDTH-1:0] addr,      // input address to the module
	 input wr,                         // by default a 1-bit wide wire; indicates a write or read; if wr == 1, a write is being done, and vice versa
	 input [DATA_WIDTH-1:0] wdata,     // the input write-data line, with the MSB on the left
	 input sel,                        // active-high select signal; there could be data on the wdata line - only do stuff if sel is high
	 input enable,                     // enable signal that the master device drives in the transaction
	 output reg ready,                 // ready signal - output of the slave device
	 output reg [DATA_WIDTH-1:0] rdata // the output of the module contains the data read from the specified address
	 );
	 
	 // ==== Define Internal Signals ====
	 // these are used to describe the functionality or logic performed:
	 reg [DATA_WIDTH-1:0] mem_block [DEPTH];  // a block of registers
	 reg next_state; // used in the state machine
	 reg curr_state; // used in the state machine
	 
	 // ==== Local Parameters to Improve Readability ====
	 localparam IDLE = 1'b0, ACCESS_PHASE = 1'b1;
	 
	 // ==== Logic for Next State ====
	 always @ (negedge clk or posedge reset) begin
		if (reset) begin
			next_state = IDLE;
		end
		else begin
			case ({sel, enable})
				2'b00: next_state = IDLE;
				2'b10: next_state = ACCESS_PHASE;
				2'b11: next_state = IDLE;
				default: next_state = IDLE;
			endcase
		end
	 end
	 // ==== Logic for Current State ====
	 always @ (posedge clk or posedge reset) begin
		if (reset) begin
			curr_state = IDLE; // on reset go to the idle state
		end
		else begin
			case (next_state)
				IDLE: curr_state = IDLE;
				ACCESS_PHASE: curr_state = ACCESS_PHASE;
				default: curr_state = IDLE;
			endcase
		end
	 end

	// ==== Logic for Module Outputs ====
	always @ (posedge clk or posedge reset) begin
		if (reset) begin
			// each register in the bank takes on RESET_VAL on a reset
			// compact way to describe the reset of the bank of registers
			// one could also use a for loop to do this
			mem_block <= '{default: RESET_VAL};
		end
		else begin
			case (curr_state)
				IDLE: begin
					ready <= 0;
					rdata <= 0;
				end
				ACCESS_PHASE: begin
					ready <= 1;
					if (wr) mem_block[addr] <= wdata;
					else rdata <= mem_block[addr];
				end
				default: begin
					ready <= 0;
					rdata <= 0;
				end
			endcase
		end
	end
	
endmodule