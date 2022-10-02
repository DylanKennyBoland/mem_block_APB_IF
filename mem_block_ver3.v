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
	 output wire ready,                // ready signal - output of the slave device
	 output wire [DATA_WIDTH-1:0] rdata // the output of the module contains the data read from the specified address
	 );
	 
	 // ==== Define Internal Signals ====
	 // these are used to describe the functionality or logic performed:
	 reg [DATA_WIDTH-1:0] mem_block [DEPTH];  // a block of registers
	 reg next_state; // used in the state machine
	 reg curr_state; // used in the state machine
	 reg [DATA_WIDTH-1:0] rdata_reg; // register to store the data that will be put on the rdata bus
	 
	 // ==== Local Parameters to Improve Readability ====
	 localparam IDLE = 0, ACCESS_PHASE = 1;

	 // ==== Logic for Sequential (Clocked) Elements ====
	 always @ (posedge clk or posedge reset) begin
		if (reset) begin
			curr_state <= IDLE; // on reset go to the idle state
			mem_block  <= '{default: RESET_VAL}; // reset the memory block
		end else begin
			curr_state <= next_state;
		end
	 end

	 
	 // ==== Logic for Next State - Combinational Logic ====
	 always @ (*) begin // (*) means we do not need to specify the sensitivity list
		// define default behaviour
		next_state = curr_state;
		rdata_reg = {DATA_WIDTH{1'b0}};
		case (curr_state)
			IDLE: begin
				if (sel == 1'b1) begin
					next_state = ACCESS_PHASE;
				end
			end
			ACCESS_PHASE: begin
				if (enable == 1'b1) begin
					if (wr == 1'b1) begin
						mem_block[addr] = wdata;
					end else begin
						rdata_reg = mem_block[addr];
					end
					next_state = IDLE;
				end // else, next_state = curr_state = ACCESS_PHASE
			end
		endcase
	 end
	
	// ==== Drive the Ready Signal ====
	assign ready = (curr_state == ACCESS_PHASE) ? 1'b1 : 1'b0; // only drive the ready signal when in the access phase
	assign rdata = rdata_reg;
endmodule

