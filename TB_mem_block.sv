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

	// ==== Parameters to make the Testbench more Flexible ====
	localparam DEPTH = 32, ADDR_WIDTH = $clog2(DEPTH), DATA_WIDTH = 8, RESET_VAL = 8'haa;
	
	// ==== Define Stimulus Signals ====
	reg clk;
	reg reset;
	reg sel;
	reg enable;
	reg wr;
	reg [DATA_WIDTH-1:0] wdata;
	reg [ADDR_WIDTH-1:0] addr;
	wire ready;
	wire [DATA_WIDTH-1:0] rdata;
	
	// ==== Instantiate the DUT ====
	mem_block # (.DATA_WIDTH(8),
		.DEPTH(DEPTH),
		.ADDR_WIDTH(ADDR_WIDTH),
		.RESET_VAL(RESET_VAL)
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


	// ==== Some Variables used for Checking Purposes ====
	integer pass_count = 0;
	integer error_count = 0;

	// Task to emulate an APB write transaction
	task apb_write (input [ADDR_WIDTH-1:0] trans_addr, input [DATA_WIDTH-1:0] data);
		begin
			@(posedge clk);
			#1;
			sel = 1'b1;
			wr = 1'b1;
			addr = trans_addr;
			wdata = data;
			@(posedge clk);
			#1;
			enable = 1'b1;
			@(posedge clk);
			#1;
			sel = 1'b0;
			enable = 1'b0;
		end
	endtask

	// Task to emulate an APB read transaction
	task apb_read (input [ADDR_WIDTH-1:0] trans_addr, input [DATA_WIDTH-1:0] expected_data);
		begin
			@(posedge clk);
			#1;
			sel = 1'b1;
			wr = 1'b0;
			addr = trans_addr;
			@(posedge clk);
			#1;
			enable = 1'b1;
			#1;
			if (expected_data == rdata) pass_count = pass_count + 1;
			else error_count = error_count + 1;
			@(posedge clk);
			#1;
			sel = 1'b0;
			enable = 1'b0;
		end
	endtask

	// Task to set the signal values on reset
	task reset_sigs();
		begin
			reset = 1'b0;
			sel = 1'b0;
			enable = 1'b0;
			wr = 1'b0;
			wdata = 0;
			addr = 0;
		end
	endtask

	// ==== Drive the Signals to the DUT ====
	initial
		begin
			reset_sigs(); // reset the signals initially
			// ==== Generate Stimulus to the DUT ====
			#15 reset = 1'b1; // reset the device
			#20 reset = 1'b0; // set reset low again
			#5; // wait a little...
			apb_write(5'b00011, 8'hbb);    // perform a write transaction
			#20;
			apb_read(5'b00011, 8'hbb);     // read back from the address - and specify the expected value in the second argument
			#10;
			apb_read(5'b00111, RESET_VAL); // read from a different address (one which we haven't written to) - value should be RESET_VAL
			#15;
			apb_write(5'b01111, 8'hca);    // perform another write transaction
			#10;
			apb_read(5'b01111, 8'hca);     // read back from the address used in the previous write transaction
			#200;
			$stop;
		end
	
	initial
		begin
			$dumpfile("dump.vcd");
			$dumpvars(2);
		end
endmodule