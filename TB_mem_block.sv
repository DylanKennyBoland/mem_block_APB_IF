//
// Author: Dylan Boland
//
// A simple testbench module for the mem_block module.
//
// The mem_block module acts as a bank of registers that can be written to
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

module TB_mem_block; // empty port list - signals are generated from within
	
	// ==== Define Stimulus Signals ====
	reg clk;
	reg reset;
	reg sel;
	reg enable;
	reg wr;
	reg [7:0] wdata;
	reg [7:0] addr;
	wire ready;
	wire [7:0] rdata;
	
	// ==== Instantiate the DUT ====
	mem_block # (.DATA_WIDTH(8),
		.DEPTH(32),
		.ADDR_WIDTH(5),
		.RESET_VAL(8'h00)
		) dut (.clk(clk),
			.reset(reset),
			.sel(sel),
			.enable(enable),
			.wr(wr),
			.wdata(wdata),
			.addr(addr),
			.ready(ready),
			.rdata(rdata)
			);
	
	// ==== Generate the Clock Signal ====
	initial
		begin
			clk = 1'b0;
			forever
				#10 clk = ~clk;
		end
	
	// ==== Define the Initial Signal Values ====
	initial
		begin
			reset = 1'b0;
			sel = 1'b0;
			enable = 1'b0;
			wr = 1'b0;
			wdata = 0;
			addr = 0;
			// ==== Generate Stimulus to the DUT ====
			#15 reset = 1'b1; // reset the device
			#20 reset = 1'b0; // set reset low again
			@(posedge clk)    // wait for a rising clock edge
			#1;
			sel = 1'b1;       // select the device just after the clock edge
			wr = 1'b1;        // start a write transaction
			addr = 1;         // specify address 1
			wdata = 8'haa;    // the write data signal (two As are easy to see on waveform diagram)
			@(posedge clk)    // wait for rising edge
			#1;
			enable = 1'b1;    // set enable high
			@(posedge clk)
			#1;
			enable = 1'b0; // set enable low
			sel = 1'b0;    // unselect the device
			#20;           // wait some time
			@(posedge clk)
			#1;
			sel = 1'b1;    // select the device just after the clock edge
			wr = 1'b0;     // try a read transaction
			addr = 1;      // specify address 1
			@(posedge clk) // wait for rising edge
			#1;
			enable = 1'b1; // set enable high
			@(posedge clk)
			#1;
			enable = 1'b0; // set enable low
			sel = 1'b0;    // unselect the device
			#200;
			$stop;
		end
	
	initial
		begin
			$dumpfile("dump.vcd");
			$dumpvars(2);
		end
endmodule
			
			
	
		
	