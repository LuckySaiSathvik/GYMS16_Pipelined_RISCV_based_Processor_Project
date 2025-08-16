#program to convert assembly language program into binary form
import argparse
# define opcodes of GYMS-16 processor
OPCODES = {'ADD':'1010', 'SUB':'1011', 'DIV':'1100', 'STM':'0001',
		'LDM':'0000', 'LDR':'0010', 'MOV':'0011', 'AND':'0100',
		'OR':'0101', 'XOR':'0110', 'SHL':'1000','SHR':'1001', 
		'NOT':'0111', 'NOP':'1111'}
# define registers of GYMS-16 processor
REGISTERS = {'R0':'0000', 'R1':'0001', 'R2':'0010', 'R3':'0011',
		'R4':'0100', 'R5':'0101', 'R6':'0110', 'R7':'0111',
		'R8':'1000', 'R9':'1001', 'R10':'1010', 'R11':'1011',
		'R12':'1100', 'R13':'1101', 'R14':'1110', 'R15':'1111'}
# first pass to identify labels and their corresponding memory addresses
def first_pass(assembly_code):
	label_table = {}
	address = 0
	for line in assembly_code:
		line = line.strip()
		if not line or line.startswith(';'):
			continue
		if ':' in line:
			label, instruction = line.split(':', 1)
			label = label.strip()
			label_table[label] = address
			line = instruction.strip()
		if line:
			address += 1
	return label_table
# convert an instruction line into binary based on the opcode and format
def assemble_instruction(line, label_table):
	parts = line.split()
	# if not spaced
	if not parts:
		return None
	# extract the opcodes
	opcode = parts[0].upper()
	if opcode not in OPCODES:
		raise ValueError(f"Unknown opcode: {opcode}")
	# this is the total binary code
	binary_code = OPCODES[opcode]
	# based on the function, assign the registers, conditions and immediates to the binary code
	if opcode in ['ADD', 'SUB', 'DIV', 'AND', 'OR', 'XOR']:
		rd = REGISTERS[parts[1].strip(',')]
		rs1 = REGISTERS[parts[2].strip(',')]
		rs2 = REGISTERS[parts[3].strip(',')]
		binary_code += rd + rs1 + rs2
	elif opcode == 'LDR':
		rd = REGISTERS[parts[1].strip(',')]
		imm_value = format(int(parts[2]), '08b')
		binary_code += rd + imm_value
	elif opcode == 'MOV':
		rd = REGISTERS[parts[1].strip(',')]
		rs = REGISTERS[parts[2].strip(',')]
		binary_code += rd + rs + 'xxxx'
	elif opcode in ['SHL','SHR']:
		rd = REGISTERS[parts[1].strip(',')]
		rs = REGISTERS[parts[2].strip(',')]
		mode = parts[3].strip(',')
		imm_value = parts[4].strip(',')
		if mode not in ['00','11']:
			raise ValueError(f"Unknown condition: {mode}")
		binary_code += rd + rs + mode + imm_value
	elif opcode == 'NOT':
		rd = REGISTERS[parts[1].strip(',')]
		rs = REGISTERS[parts[2].strip(',')]
		mode = parts[3].strip(',')
		if mode not in ['0000', '1111']:
			raise ValueError(f"Unknown condition: {mode}")
		binary_code += rd + rs + mode
	elif opcode in ['LDM', 'STM']:
		r = REGISTERS[parts[1].strip(',')]
		memaddr = format(int(parts[2]), '08b')
		binary_code += r + memaddr
	elif opcode == 'NOP':
		binary_code = '1111111111111111'
	else:
		raise ValueError(f"Unsupported operation: {opcode}")
	return binary_code
# main assembler function to process assembly file
def assemble_file(input_filename, output_filename):
	with open(input_filename, 'r') as f:
		assembly_code = f.readlines()
	label_table = first_pass(assembly_code)
	machine_code = []
	for line in assembly_code:
		line = line.strip()
		if not line or line.startswith(';') or ':' in line:
			continue
		binary_instruction = assemble_instruction(line, label_table)
		if binary_instruction:
			machine_code.append(binary_instruction)
	with open(output_filename, 'w') as f:
		for binary in machine_code:
			f.write(binary + '\n')
# command-line argument parsing
if __name__ == "__main__":
	input_file = "1_test_program.asm"
	output_file = "3_test_output.bin"
	assemble_file(input_file, output_file)
	print(f"Assembly complete. Machine code written to {output_file}")
