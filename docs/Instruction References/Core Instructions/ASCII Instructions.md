https://www.felixcloutier.com/x86/

AAA — ASCII Adjust After Addition

Opcode	Instruction	Op/En	64-bit Mode	    Compat/Leg Mode	       Description
37	        AAA	     ZO	    Invalid	          Valid	            ASCII adjust AL after addition.

Instruction Operand Encoding:

Op/En	Operand 1	Operand 2	Operand 3	Operand 4
ZO	       N/A	        N/A	       N/A	       N/A

Description:

Adjusts the sum of two unpacked BCD values to create an unpacked BCD result. The AL register is the implied source and destination operand for this instruction. The AAA instruction is only useful when it follows an ADD instruction that adds (binary addition) two unpacked BCD values and stores a byte result in the AL register. The AAA instruction then adjusts the contents of the AL register to contain the correct 1-digit unpacked BCD result.

If the addition produces a decimal carry, the AH register increments by 1, and the CF and AF flags are set. If there was no decimal carry, the CF and AF flags are cleared and the AH register is unchanged. In either case, bits 4 through 7 of the AL register are set to 0.

This instruction executes as described in compatibility mode and legacy mode. It is not valid in 64-bit mode.

Operation:

IF 64-Bit Mode
    THEN
        #UD;
    ELSE
        IF ((AL AND 0FH) > 9) or (AF = 1)
            THEN
                AX := AX + 106H;
                AF := 1;
                CF := 1;
            ELSE
                AF := 0;
                CF := 0;
        FI;
        AL := AL AND 0FH;
FI;
Flags Affected:

The AF and CF flags are set to 1 if the adjustment results in a decimal carry; otherwise they are set to 0. The OF, SF, ZF, and PF flags are undefined.

Protected Mode Exceptions:

#UD	If the LOCK prefix is used.

Real-Address Mode Exceptions:

Same exceptions as protected mode.

Virtual-8086 Mode Exceptions:

Same exceptions as protected mode.

Compatibility Mode Exceptions:

Same exceptions as protected mode.

64-Bit Mode Exceptions:

#UD	If in 64-bit mode.



AAD — ASCII Adjust AX Before Division
Opcode	Instruction	Op/En	64-bit Mode	 Compat/Leg Mode	Description
 D5 0A	   AAD	      ZO	  Invalid	     Valid	     ASCII adjust AX before division.
 D5 ib	   AADimm8	  ZO	  Invalid	     Valid	     Adjust AX before division to number base imm8.

Instruction Operand Encoding:

Op/En	Operand 1	Operand 2	Operand 3	Operand 4
  ZO	  N/A	      N/A	      N/A	        N/A

Description:

Adjusts two unpacked BCD digits (the least-significant digit in the AL register and the most-significant digit in the AH register) so that a division operation performed on the result will yield a correct unpacked BCD value. The AAD instruction is only useful when it precedes a DIV instruction that divides (binary division) the adjusted value in the AX register by an unpacked BCD value.

The AAD instruction sets the value in the AL register to (AL + (10 * AH)), and then clears the AH register to 00H. The value in the AX register is then equal to the binary equivalent of the original unpacked two-digit (base 10) number in registers AH and AL.

The generalized version of this instruction allows adjustment of two unpacked digits of any number base (see the “Operation” section below), by setting the imm8 byte to the selected number base (for example, 08H for octal, 0AH for decimal, or 0CH for base 12 numbers). The AAD mnemonic is interpreted by all assemblers to mean adjust ASCII (base 10) values. To adjust values in another number base, the instruction must be hand coded in machine code (D5 imm8).

This instruction executes as described in compatibility mode and legacy mode. It is not valid in 64-bit mode.

Operation:

IF 64-Bit Mode
    THEN
        #UD;
    ELSE
        tempAL := AL;
        tempAH := AH;
        AL := (tempAL + (tempAH ∗ imm8)) AND FFH;
        (* imm8 is set to 0AH for the AAD mnemonic.*)
        AH := 0;
FI;
The immediate value (imm8) is taken from the second byte of the instruction.

Flags Affected:

The SF, ZF, and PF flags are set according to the resulting binary value in the AL register; the OF, AF, and CF flags are undefined.

Protected Mode Exceptions:

#UD	If the LOCK prefix is used.

Real-Address Mode Exceptions:

Same exceptions as protected mode.

Virtual-8086 Mode Exceptions:

Same exceptions as protected mode.

Compatibility Mode Exceptions:

Same exceptions as protected mode.

64-Bit Mode Exceptions:

#UD	If in 64-bit mode.



AAM — ASCII Adjust AX After Multiply
Opcode	Instruction	Op/En	64-bit Mode	Compat/Leg Mode	  Description
D4 0A	   AAM	     ZO	    Invalid	       Valid	    ASCII adjust AX after multiply.
D4 ib	 AAM imm8	 ZO	    Invalid	       Valid	    Adjust AX after multiply to number base imm8.

Instruction Operand Encoding

Op/En	Operand 1	Operand 2	Operand 3	Operand 4
  ZO	   N/A	       N/A	      N/A	      N/A

Description:

Adjusts the result of the multiplication of two unpacked BCD values to create a pair of unpacked (base 10) BCD values. The AX register is the implied source and destination operand for this instruction. The AAM instruction is only useful when it follows an MUL instruction that multiplies (binary multiplication) two unpacked BCD values and stores a word result in the AX register. The AAM instruction then adjusts the contents of the AX register to contain the correct 2-digit unpacked (base 10) BCD result.

The generalized version of this instruction allows adjustment of the contents of the AX to create two unpacked digits of any number base (see the “Operation” section below). Here, the imm8 byte is set to the selected number base (for example, 08H for octal, 0AH for decimal, or 0CH for base 12 numbers). The AAM mnemonic is interpreted by all assemblers to mean adjust to ASCII (base 10) values. To adjust to values in another number base, the instruction must be hand coded in machine code (D4 imm8).

This instruction executes as described in compatibility mode and legacy mode. It is not valid in 64-bit mode.

Operation:

IF 64-Bit Mode
    THEN
        #UD;
    ELSE
        tempAL := AL;
        AH := tempAL / imm8; (* imm8 is set to 0AH for the AAM mnemonic *)
        AL := tempAL MOD imm8;
FI;
The immediate value (imm8) is taken from the second byte of the instruction.

Flags Affected:

The SF, ZF, and PF flags are set according to the resulting binary value in the AL register. The OF, AF, and CF flags are undefined.

Protected Mode Exceptions:

#DE	If an immediate value of 0 is used.
#UD	If the LOCK prefix is used.

Real-Address Mode Exceptions:

Same exceptions as protected mode.

Virtual-8086 Mode Exceptions:

Same exceptions as protected mode.

Compatibility Mode Exceptions:

Same exceptions as protected mode.

64-Bit Mode Exceptions:

#UD	If in 64-bit mode.



AAS — ASCII Adjust AL After Subtraction
Opcode	Instruction	Op/En	64-bit Mode	Compat/Leg Mode	   Description
  3F	    AAS	      ZO	  Invalid	  Valid	        ASCII adjust AL after subtraction.

Instruction Operand Encoding :

Op/En	Operand 1	Operand 2	Operand 3	Operand 4
  ZO	   N/A	       N/A	       N/A	       N/A

Description :

Adjusts the result of the subtraction of two unpacked BCD values to create a unpacked BCD result. The AL register is the implied source and destination operand for this instruction. The AAS instruction is only useful when it follows a SUB instruction that subtracts (binary subtraction) one unpacked BCD value from another and stores a byte result in the AL register. The AAA instruction then adjusts the contents of the AL register to contain the correct 1-digit unpacked BCD result.

If the subtraction produced a decimal carry, the AH register decrements by 1, and the CF and AF flags are set. If no decimal carry occurred, the CF and AF flags are cleared, and the AH register is unchanged. In either case, the AL register is left with its top four bits set to 0.

This instruction executes as described in compatibility mode and legacy mode. It is not valid in 64-bit mode.

Operation:

IF 64-bit mode
    THEN
        #UD;
    ELSE
        IF ((AL AND 0FH) > 9) or (AF = 1)
            THEN
                AX := AX – 6;
                AH := AH – 1;
                AF := 1;
                CF := 1;
                AL := AL AND 0FH;
            ELSE
                CF := 0;
                AF := 0;
                AL := AL AND 0FH;
        FI;
FI;

Flags Affected:

The AF and CF flags are set to 1 if there is a decimal borrow; otherwise, they are cleared to 0. The OF, SF, ZF, and PF flags are undefined.

Protected Mode Exceptions:

#UD	If the LOCK prefix is used.

Real-Address Mode Exceptions:

Same exceptions as protected mode.

Virtual-8086 Mode Exceptions:

Same exceptions as protected mode.

Compatibility Mode Exceptions:

Same exceptions as protected mode.

64-Bit Mode Exceptions:

#UD	If in 64-bit mode.