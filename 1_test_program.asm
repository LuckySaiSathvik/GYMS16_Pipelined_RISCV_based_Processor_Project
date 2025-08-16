LDR R0, 8               # Move immediate value 10 into register R0
LDR R1, 5               # Move immediate value 5 into register R1
NOP                     # No operation; used for hazard mitigation
NOP                     # No operation; used for hazard mitigation
NOP                     # No operation; used for hazard mitigation
ADD R2, R0, R1          # Add R0 and R1, store the result in R2 (R2 = R0 + R1)
SUB R3, R0, R1          # Subtract R0 and R1, store the result in R3 (R3 = R0 - R1)
DIV R4, R0, R1          # Divide R0 and R1, store the result in R4 (R4 = R0 / R1)
AND R5, R0, R1          # And R0 and R1, store the result in R5 (R5 = R0 & R1)
OR R6, R0, R1           # Or R0 and R1, store the result in R6 (R6 = R0 | R1)
NOT R7, R0, 1111        # Perform 2's comp of R0, store the result in R7 (R7 = ~(R0)+1)
NOT R8, R0, 0000        # Perform 1's comp of R0, store the result in R8 (R8 = ~(R0)+0)
XOR R9, R0, R1          # Xor R0 and R1, store the result in R9 (R9 = R0 ^ R1)
SHL R10, R1, 00, 10     # Logical Shift R1 to left by 2, store the result in R10 (R10 = R1<<2)
SHL R11, R1, 11, 10     # Arithmetic Shift R1 to left by 2, store the result in R11 (R11 = R1<<<2)
SHR R12, R1, 00, 10     # Logical Shift R1 to right by 2, store the result in R12 (R12 = R1>>2)
SHR R13, R1, 11, 10     # Arithmetic Shift R1 to right by 2, store the result in R13 (R13 = R1>>>2)
STM R0, 00000001        # Store R0 into memory address 0x01
STM R1, 00000002        # Store R1 into memory address 0x02
LDM R14, 00000001       # Load from memory address 0x01 and store in R14
LDM R15, 00000002       # Load from memory address 0x02 and store in R15
