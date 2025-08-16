**GYMS16_Pipelined_RISCV_based_Processor_Project**

This project was on designing 16-bit 5-staged pipelined RISC-V based Processor, with 0.5kB data and instruction memories each separately; along with 16 general-purpose registers.

The processor is coded in Verilog HDL along with Python script that converts Assembly code into binary, based on the ISA; and was performed as part of BTech Mini Project during 7th Semester (2nd half of 2024) in IIIT Dharwad (more details available in the report attached).

The Instruction Set Architecture (ISA) contains 14 unique instructions for different logical, shifting and arithmetic operations; along with reg-to-reg, reg-to-mem and mem-to-reg data movement. The NOP (No Operation) was used as resolver for pipeline conflicts; and there aren't any branching instructions.

My contribution in this project involved designing the ISA and the datapath along with final synthesis, while the team's effort was in designing each individual component separately along with the syntax-error-free simulation in Icarus Verilog and GTKWave.

**Steps to run it in your device terminal after cloning:**
(Keep Icarus Verilog and GTKWave installed)

1) Edit "1_test_program.asm" based on your working (refer to the ISA and make changes).
2) Now run: **python3 2_gyms16_assembler.py** ; the process is successful if you get "Machine code written to 3_test_output.bin".
3) Now run: **iverilog -o 6_processor_wave 5_processor_testbench.v** ; the process is succesful if you don't get any errors.
4) Now run: **vvp 6_processor_wave** ; the process is succesful if you don't get any errors.
5) Finally run: **gtkwave 7_processor_waveform.vcd** ; and check for the required signals' movement as per your choice in the new window opened.

**Note:** Please don't change any other files after cloning this repo other than 1_test_program.asm for best results. You can learn more theory from the report attached.

**Sai Sathvik G B**

Contributor
