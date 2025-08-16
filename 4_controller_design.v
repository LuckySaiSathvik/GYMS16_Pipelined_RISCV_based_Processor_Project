//controller module; written by GYMS team
//control unit of processor
module controller(
	input [3:0]opcode,//opcode
	output reg mem_signal_write,//memory write signal
	output reg reg_signal_write//register write signal
);
	//classification of instructions
	parameter mem_data_inst = 3'b000,//ldm,stm
		  reg_data_inst = 3'b001,//ldr,mov
		  andor_inst = 3'b010,//and,or
		  notxor_inst = 3'b011,//not,xor
		  shift_inst = 3'b100,//shl,shr
		  addsub_inst = 3'b101,//add,sub
		  div_inst = 3'b110;//div
	always@(*)//combinational logic for control signal generation
		begin
			case(opcode[3:1])
				mem_data_inst: begin
					//for ldm, write to reg file; for stm, read from reg file
					//for ldm, read from data mem; for stm, write to data mem
					reg_signal_write <= ~opcode[0];
					mem_signal_write <= opcode[0];
				end
				reg_data_inst,andor_inst,notxor_inst: begin
					//for: ldr,mov,and,or,not,xor only write to reg file
					reg_signal_write <= 1'b1;
					mem_signal_write <= 1'b0;
				end
				addsub_inst,div_inst,shift_inst: begin
					//for: add,sub,div,shl,shr only write to reg file
					reg_signal_write <= 1;
					mem_signal_write <= 0;
				end
			endcase
		end
endmodule
