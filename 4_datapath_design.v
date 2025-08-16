//datapath module; written by GYMS team
//datapath of processor
module datapath #(parameter nop_width = 3)(
	input clock,//processor clock
	input reset,//processor reset
	input mem_signal_write,//mem write signal
	input reg_signal_write,//reg write signal
	output [3:0]opcode,//opcode
	output zero_flag,//zero flag; triggers if resultant=0
	output error_flag//error flag; triggers if resulant=x or division by zero
);
	//classification of instructions
	parameter mem_data_inst = 3'b000,//ldm,stm
		  reg_data_inst = 3'b001,//ldr,mov
		  andor_inst = 3'b010,//and,or
		  notxor_inst = 3'b011,//not,xor
		  shift_inst = 3'b100,//shl,shr
		  addsub_inst = 3'b101,//add,sub
		  div_inst = 3'b110,//div
		  nop = 3'b111;//no operation
	//classification of operations
	parameter bit_and = 4'b0000,//and
		  bit_or = 4'b0001,//or
		  bit_xor = 4'b0010,//xor
		  bit_not = 4'b0011,//not
		  shift_log_left = 4'b0100,//logic shift left
		  shift_ari_left = 4'b0101,//arith shift left
		  shift_log_right = 4'b0110,//logic shift right
		  shift_ari_right = 4'b0111,//arith shift right
		  arith_add = 4'b1000,//add
		  arith_sub = 4'b1001,//sub
		  arith_div = 4'b1010;//div
	//data memory read-write ports
	reg [7:0]mem_addr_rw;//shared address
	reg [15:0]mem_data_write;//write data
	wire [15:0]mem_data_read;//read data
	//register file read-write ports
	reg [3:0]reg_addr_write;//write address
	reg [3:0]reg_addr_read1;//1st read address
	reg [3:0]reg_addr_read2;//2nd read address
	reg [15:0]reg_data_write;//write data
	wire [15:0]reg_data_read1;//1st read data
	wire [15:0]reg_data_read2;//2nd read data
	//instruction memory ports
	reg [7:0]program_counter;//program counter
	wire [15:0]instruction;//instruction extracted
	//arithmetic and logical unit (alu) ports
	reg [3:0]operation;//alu operation
	reg [15:0]alu_op1;//alu 1st operand
	reg [15:0]alu_op2;//alu 2nd operand
	wire [15:0]alu_res;//alu result
	/*stages of pipelining implememted are:
	IF = instruction fetch
	ID = instruction decode
	EX = execute operation
	MEM = memory access
	WB = write back registers*/
	//pipelining registers between IF and ID stages
	reg [3:0]IF_ID_opcode;
	reg [7:0]IF_ID_program_counter;
	reg [15:0]IF_ID_instruction;
	//pipelining registers between ID and EX stages
	reg [3:0]ID_EX_reg_addr_write;
	reg [3:0]ID_EX_operation;
	reg [3:0]ID_EX_opcode;
	reg [15:0]ID_EX_instruction;
	reg [15:0]ID_EX_reg_data_read1;
	reg [15:0]ID_EX_reg_data_read2;
	reg [15:0]ID_EX_reg_data_write;
	reg [15:0]ID_EX_mem_data_write;
	//pipelining registers between EX and MEM stages
	reg EX_MEM_mem_signal_write;
	reg [3:0]EX_MEM_reg_addr_write;
	reg [3:0]EX_MEM_opcode;
	reg [15:0]EX_MEM_alu_res;
	reg [15:0]EX_MEM_reg_data_write;
	reg [15:0]EX_MEM_mem_data_write;
	//pipelining registers between MEM and WB stages
	reg MEM_WB_reg_signal_write;
	reg [3:0]MEM_WB_reg_addr_write;
	reg [15:0]MEM_WB_reg_data_write;
	//nop operation related variables
	wire [nop_width-1:0]count_ID;//ID stage NOP counter
	wire [nop_width-1:0]count_EX;//EX stage NOP counter
	reg counter_ID_en;//enable signal for ID counter
	reg counter_EX_en;//enable signal for EX counter
	//instruction fetch stage
	always@(posedge clock)//sequential logic for extracting instructions
		begin
			if(reset)//synchronous reset; and if high
				program_counter <= 8'd0;//initialise program counter
			else
				program_counter <= program_counter + 8'd1;//continue incrementing
		end
	//instantiating instruction memory
	instr_memory IM(
			.program_counter(program_counter),
			.instruction(instruction)
	);
	//intermediate between IF and ID stages
	always @(posedge clock)//sequential logic for moving these into registers
		begin
			IF_ID_instruction <= instruction;
			IF_ID_program_counter <= program_counter;
			IF_ID_opcode <= instruction[15:12];
		end
	//instruction decode stage
	always@(*)//combinational logic to decode data from instruction
		begin
			//consider the instruction classification
			case(IF_ID_opcode[3:1])
				//includes ldm and stm
				mem_data_inst: begin
					mem_addr_rw = IF_ID_instruction[7:0];//address allocation
					if(IF_ID_opcode[0] == 1'b0)//if ldm
						begin
							reg_addr_write = IF_ID_instruction[11:8];//write to reg
							reg_data_write = mem_data_read;//write this from mem
						end
					else//if stm
						begin
							reg_addr_read1 = IF_ID_instruction[11:8];//read from reg
							mem_data_write = reg_data_read1;//write this to mem
						end
					end
				//includes ldr and mov
				reg_data_inst: begin
					reg_addr_write = IF_ID_instruction[11:8];//write to this register
					if(IF_ID_opcode[0] == 1'b0)//if ldr
						begin
							//assigning immediate from instruction
							reg_data_write = {8'b0,IF_ID_instruction[7:0]};
						end
					else//mov
						begin
							reg_addr_read1 = IF_ID_instruction[7:4];//read from reg
							reg_data_write = reg_data_read1;//write this from reg
						end
					end
				//includes and,or,add,sub
				andor_inst,addsub_inst: begin
					reg_addr_read1 = IF_ID_instruction[7:4];//read from this register
					reg_addr_read2 = IF_ID_instruction[3:0];//read from this register too
					reg_addr_write = IF_ID_instruction[11:8];//write to this register
					if(IF_ID_opcode[3:1]==andor_inst)
						//operation is and or or
						operation = (IF_ID_opcode[0] == 1'b0)? bit_and : bit_or;
					else if(IF_ID_opcode[3:1]==addsub_inst)
						//operation is add or sub
						operation = (IF_ID_opcode[0] == 1'b0)? arith_add : arith_sub;
					end
				//includes not,xor,div
				notxor_inst,div_inst: begin
					reg_addr_write = IF_ID_instruction[11:8];//write to this register
					reg_addr_read1 = IF_ID_instruction[7:4];//read from this register
					if(IF_ID_opcode[0] == 0)//if xor or div
						begin
							//read from this register too
							reg_addr_read2 = IF_ID_instruction[3:0];									
							if(IF_ID_opcode[3:1]==notxor_inst)
								operation = bit_xor;//operation is xor
							else if(IF_ID_opcode[3:1]==div_inst)
								operation = arith_div;//operation is div
						end
					//if not instruction
					else if((IF_ID_opcode[3:1]==notxor_inst)&&(IF_ID_opcode[0] == 1'b1))
						begin
							operation = bit_not;//operation is not
						end
					end
				//includes shl and shr
				shift_inst: begin
					reg_addr_write = IF_ID_instruction[11:8];//write to this register
					reg_addr_read1 = IF_ID_instruction[7:4];//read from this register
					if(IF_ID_instruction[3:2]==2'b00)//logical shift
						begin
							if(IF_ID_opcode[0] == 1'b0)
								operation = shift_log_left;//logic shift left
							else
								operation = shift_log_right;//logic shift right
						end
					else if(IF_ID_instruction[3:2]==2'b11)//arithmetic shift
						begin
							if(IF_ID_opcode[0] == 1'b0)
								operation = shift_ari_left;//arith shift left
							else
								operation = shift_ari_right;//arith shift right
						end
					end
				//includes only nop
				nop: begin
					counter_ID_en = 1'b1;//enable the counter
					//rest all need not be cared; so this is written
					reg_addr_read1 = 4'dx;
					reg_addr_read2 = 4'dx;
					reg_addr_write = 4'dx;
					operation = 4'dx;
					reg_data_write = 16'dx;
					mem_addr_rw = 8'dx;
					mem_data_write = 16'dx;
					end
			endcase
		end
	//instantiate the counter for NOP
	counter #(nop_width) COUNT_ID(.clock(clock),.reset(reset),.en(counter_ID_en),.count(count_ID));
	//intermediate between ID and EX stages
	always@(posedge clock)//sequential logic for moving these into registers
		begin
			ID_EX_reg_addr_write <= reg_addr_write;
			ID_EX_mem_data_write <= mem_data_write;
			ID_EX_reg_data_read1 <= reg_data_read1;
			ID_EX_reg_data_read2 <= reg_data_read2;
			ID_EX_operation <= operation;
			ID_EX_opcode <= IF_ID_opcode;
			ID_EX_instruction <= IF_ID_instruction;
			ID_EX_reg_data_write <= reg_data_write;
		end
	//execute stage
	always@(*)//combinational logic to decode operands for the ALU
		begin
			//consider the instruction classification
			case(ID_EX_opcode[3:1])
				//includes and,or,add,sub
				andor_inst, addsub_inst: begin
					//two register sources
					alu_op1 = ID_EX_reg_data_read1;//move this read1 data to alu
					alu_op2 = ID_EX_reg_data_read2;//move this read2 data to alu
					end
				//includes not,xor,div
				notxor_inst, div_inst: begin
					//one sure-shot register source
					alu_op1 = ID_EX_reg_data_read1;//move this read1 data to alu
					if(ID_EX_opcode[0] == 1'b0)
						//the second register source instructions
						alu_op2 = ID_EX_reg_data_read2;//move this read2 data to alu
					else if((ID_EX_opcode[3:1] == notxor_inst) && (IF_ID_opcode[0] == 1'b1))
						begin
							//1's or 2's complement condition based operand
							if(ID_EX_instruction[3:0] == 4'b1111)
								alu_op2 = 16'd1;
							else if(ID_EX_instruction[3:0] == 4'b0000)
								alu_op2 = 16'd0;
						end
					end
				//includes shl,shr
				shift_inst: begin
					//one register source and condition based operand
					alu_op1 = ID_EX_reg_data_read1;//move this data to alu
					alu_op2 = {14'd0,ID_EX_instruction[1:0]};//move this data to alu too
					end
				//includes only nop
				nop: begin
					counter_EX_en = 1'b1;//enable the counter
					//rest all need not be cared; so this is written
					alu_op1 = 16'dx;
					alu_op2 = 16'dx;
					end
			endcase
		end
	//instantiating the counter for NOP
	counter #(nop_width) COUNT_EX(.clock(clock),.reset(reset),.en(counter_EX_en),.count(count_EX));
	//instantiating arithmetic and logical unit (alu)
	arithmetic_logical_unit ALU(
			.operation(ID_EX_operation),
			.alu_op1(alu_op1),
			.alu_op2(alu_op2),
			.alu_res(alu_res),
			.zero_flag(zero_flag),
			.error_flag(error_flag)
	);
	//intermediate between EX and MEM stages
	always@(posedge clock)//sequential logic for moving these into registers
		begin
			EX_MEM_mem_signal_write <= mem_signal_write;
			EX_MEM_mem_data_write <= ID_EX_mem_data_write;
			EX_MEM_opcode <= ID_EX_opcode;
			EX_MEM_reg_addr_write <= ID_EX_reg_addr_write;
			//reg_data_write has two different results: alu_res or reg_data_write
			if((ID_EX_opcode[3:1]==mem_data_inst) && (ID_EX_opcode[0] == 1'b0))
				EX_MEM_reg_data_write <= ID_EX_reg_data_write;//push the reg_write_data
			else if(ID_EX_opcode[3:1]==reg_data_inst)
				EX_MEM_reg_data_write <= ID_EX_reg_data_write;//push the reg_write_data
			else
				EX_MEM_reg_data_write <= alu_res;//push the alu result
		end
	assign opcode = EX_MEM_opcode;//final opcode for showing instruction type to be seen at waveform
	//memory access stage
	//instantiating data memory
	data_memory DM(
			.clock(clock),
			.mem_signal_write(EX_MEM_mem_signal_write),
			.mem_addr_rw(mem_addr_rw),
			.mem_data_read(mem_data_read),
			.mem_data_write(EX_MEM_mem_data_write)
	);
	//intermediate between MEM and WB stages
	always@(posedge clock)//sequential logic for moving these into registers
		begin
			MEM_WB_reg_addr_write <= EX_MEM_reg_addr_write;
			MEM_WB_reg_signal_write <= reg_signal_write;
			MEM_WB_reg_data_write <= EX_MEM_reg_data_write;
		end
	//write back registers stage
	//instantiating register file
	register_file RF(
			.clock(clock),
			.reg_signal_write(MEM_WB_reg_signal_write),
			.reg_addr_write(MEM_WB_reg_addr_write),
			.reg_data_write(MEM_WB_reg_data_write),
			.reg_addr_read1(reg_addr_read1),
			.reg_addr_read2(reg_addr_read2),
			.reg_data_read1(reg_data_read1),
			.reg_data_read2(reg_data_read2)
	);
endmodule
//code for the NOP counter
module counter #(parameter width = 8)(//default parameter is 8
	input clock,//processor clock
	input reset,//processor reset
	input en,//counter enable
	output reg [width-1:0]count//count value
);
	always@(posedge clock)//sequential logic to count
		begin
			//counts only if enabled
			if(reset && en)
				count <= 'd0;
			else if (en)
				count <= count + 'd1;
		end
endmodule
//arithmetic and logical unit module; written by GYMS team
//alu of processor
module arithmetic_logical_unit(
	input [3:0]operation,//alu operation
	input [15:0]alu_op1,//alu 1st operand
	input [15:0]alu_op2,//alu 2nd operand
	output reg [15:0]alu_res,//alu result
	output reg zero_flag,//zero flag
	output reg error_flag//error flag
);
	//classification of operations
	parameter bit_and = 4'b0000,//and
		  bit_or = 4'b0001,//or
		  bit_xor = 4'b0010,//xor
		  bit_not = 4'b0011,//not
		  shift_log_left = 4'b0100,//logic shift left
		  shift_ari_left = 4'b0101,//arith shift left
		  shift_log_right = 4'b0110,//logic shift right
		  shift_ari_right = 4'b0111,//arith shift right
		  arith_add = 4'b1000,//add
		  arith_sub = 4'b1001,//sub
		  arith_div = 4'b1010;//div
	always @(*)//combinational logic for the operation selection
		begin
			case(operation)//perform based on the given operation
				bit_and: alu_res = alu_op1 & alu_op2;//and
				bit_or: alu_res = alu_op1 - alu_op2;//or
				bit_xor: alu_res = alu_op1 / alu_op2;//xor
				bit_not: alu_res = (~alu_op1) + alu_op2;//1's or 2's complement
				shift_log_left: alu_res = alu_op1 << alu_op2;//logical left shift
				shift_ari_left: alu_res = alu_op1 <<< alu_op2;//arithmetic left shift
				shift_log_right: alu_res = alu_op1 >> alu_op2;//logical right shift
				shift_ari_right: alu_res = alu_op1 >>> alu_op2;//arithmetic right shift
				arith_add: alu_res = alu_op1 + alu_op2;//add
				arith_sub: alu_res = alu_op1 - alu_op2;//sub
				arith_div: alu_res = (alu_op2==16'd0)?(16'dx):(alu_op1 / alu_op2);//div
			endcase
			zero_flag = (alu_res==16'd0)?1'b1:1'b0;//if result is zero
			error_flag =(alu_res==16'dx)?1'b1:1'b0;//if result can't be made
		end
endmodule
//memories and register file modules; written by GYMS team
//instruction memory of processor
module instr_memory(
	input [7:0]program_counter,//program counter
	output [15:0]instruction//instruction
);
	reg [15:0]instruction_memory[0:255];//instruction memory of 256 words each of 16 bits
	assign instruction = instruction_memory[program_counter];//instruction assignment
endmodule
//data memory of processor
module data_memory(
	input clock,//processor clock
	input mem_signal_write,//write signal
	input [7:0]mem_addr_rw,//shared address
	input [15:0]mem_data_write,//write data
	output [15:0]mem_data_read//read data
);
	reg [15:0]data_memory[0:255];//data memory of 256 words each of 16 bits
	integer i;
	initial//initial values are made zeroes
		begin
			for(i=0;i<256;i=i+1)
				data_memory[i] <= 16'd0;//initialising memory words as zeroes
		end
	always@(posedge clock)//sequential logic for writing to memory
		begin
			if(mem_signal_write==1'b1)//writing
				data_memory[mem_addr_rw] <= mem_data_write;//write assignment
		end
	assign mem_data_read = (mem_signal_write==1'b0)?data_memory[mem_addr_rw]:16'dx;//read assignment
endmodule
//register file of processor
module register_file(
	input clock,//clock of processor
	input reg_signal_write,//write signal
	input [3:0]reg_addr_write,//write address
	input [3:0]reg_addr_read1,//read address 1
	input [3:0]reg_addr_read2,//read address 2
	input [15:0]reg_data_write,//write data
	output [15:0]reg_data_read1,//read data 1
	output [15:0]reg_data_read2//read data 2
);
	reg [15:0]register_file[0:15];//register file
	integer i;
	initial//initial values are made zeroes
		begin
			for(i=0;i<16;i=i+1)
				register_file[i] <= 16'd0;//initialising register words as zeroes
		end
	always@(posedge clock)//sequential logic for writing to register file
		begin
			if(reg_signal_write==1'b1)//writing
				register_file[reg_addr_write] <= reg_data_write;//write assignment
		end
	assign reg_data_read1 = register_file[reg_addr_read1];//read assignment 1
	assign reg_data_read2 = register_file[reg_addr_read2];//read assignment 2
endmodule
