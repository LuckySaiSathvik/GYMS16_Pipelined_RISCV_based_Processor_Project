//GYMS-16 testbench; written by GYMS team
`timescale 1ns / 1ps//time unit 1ns and precision of 1ps
`include "5_processor_design.v"
//processor testbench
module tb_processor;
	//inputs are reg datatype
	reg clock;
	reg reset;
	//outputs are wire datatype
	wire zero_flag;
	wire error_flag;
	//instantiate the processor RTL design
	processor GYMS_16 (.clock(clock),.reset(reset),.zero_flag(zero_flag),.error_flag(error_flag));
	//clock generation
	initial clock = 1'b1;
	always #5 clock = ~clock;//10ns clock time period
	//reset generation
	task reset_perform();
		begin
			@(negedge clock)
				reset = 1'b0;
			@(negedge clock)
				reset = 1'b1;
		end
	endtask//task-based reset used
	//testbench logic
	initial
		begin
			//reset, then load instructions from the binary file and finish after a while
			reset_perform();
			$readmemb("3_test_output.bin",GYMS_16.DATA.IM.instruction_memory);
			#1000 $finish;
		end
	initial
		begin
			//dump into the vcd file and display it on the terminal
			$dumpfile("7_processor_waveform.vcd");
			$dumpvars;
		end
endmodule
