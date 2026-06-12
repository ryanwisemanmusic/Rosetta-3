SHA1MSG1 — Perform an Intermediate Calculation for the Next Four SHA1 Message Dwords

Opcode/Instruction	                        Op/En	64/32 bit Mode Support	CPUID Feature Flag	Description
NP 0F 38 C9 /r SHA1MSG1 xmm1, xmm2/m128	    RM	    V/V	                    SHA	                Performs an intermediate calculation for the next four SHA1 message dwords using previous message dwords from xmm1 and xmm2/m128, storing the result in xmm1.

Instruction Operand Encoding:

Op/En	Operand 1	        Operand 2	    Operand 3
RM	    ModRM:reg (r, w)	ModRM:r/m (r)	N/A

Description:

The SHA1MSG1 instruction is one of two SHA1 message scheduling instructions. The instruction performs an intermediate calculation for the next four SHA1 message dwords.

Operation:

SHA1MSG1:

W0 := SRC1[127:96] ;
W1 := SRC1[95:64] ;
W2 := SRC1[63: 32] ;
W3 := SRC1[31: 0] ;
W4 := SRC2[127:96] ;
W5 := SRC2[95:64] ;
DEST[127:96] := W2 XOR W0;
DEST[95:64] := W3 XOR W1;
DEST[63:32] := W4 XOR W2;
DEST[31:0] := W5 XOR W3;

Intel C/C++ Compiler Intrinsic Equivalent:

SHA1MSG1 __m128i _mm_sha1msg1_epu32(__m128i, __m128i);

Flags Affected:

None.

SIMD Floating-Point Exceptions:

None.

Other Exceptions:

See Table 2-21, “Type 4 Class Exception Conditions.”



SHA1MSG2 — Perform a Final Calculation for the Next Four SHA1 Message Dwords

Opcode/Instruction	                        Op/En	    64/32 bit Mode Support	CPUID Feature Flag	Description
NP 0F 38 CA /r SHA1MSG2 xmm1, xmm2/m128	    RM	        V/V	                    SHA	                Performs the final calculation for the next four SHA1 message dwords using intermediate results from xmm1 and the previous message dwords from xmm2/m128, storing the result in xmm1.

Instruction Operand Encoding:

Op/En	Operand 1	Operand 2	Operand 3
RM	ModRM:reg (r, w)	ModRM:r/m (r)	N/A

Description:

The SHA1MSG2 instruction is one of two SHA1 message scheduling instructions. The instruction performs the final calculation to derive the next four SHA1 message dwords.

Operation:

SHA1MSG2:

W13 := SRC2[95:64] ;
W14 := SRC2[63: 32] ;
W15 := SRC2[31: 0] ;
W16 := (SRC1[127:96] XOR W13 ) ROL 1;
W17 := (SRC1[95:64] XOR W14) ROL 1;
W18 := (SRC1[63: 32] XOR W15) ROL 1;
W19 := (SRC1[31: 0] XOR W16) ROL 1;
DEST[127:96] := W16;
DEST[95:64] := W17;
DEST[63:32] := W18;
DEST[31:0] := W19;

Intel C/C++ Compiler Intrinsic Equivalent:

SHA1MSG2 __m128i _mm_sha1msg2_epu32(__m128i, __m128i);

Flags Affected:

None.

SIMD Floating-Point Exceptions:

None.

Other Exceptions:

See Table 2-21, “Type 4 Class Exception Conditions.”


SHA1NEXTE — Calculate SHA1 State Variable E After Four Rounds

Opcode/Instruction	                        Op/En	64/32 bit Mode Support	CPUID Feature Flag	Description
NP 0F 38 C8 /r SHA1NEXTE xmm1, xmm2/m128	RM	    V/V	                    SHA	                Calculates SHA1 state variable E after four rounds of operation from the current SHA1 state variable A in xmm1. The calculated value of the SHA1 state variable E is added to the scheduled dwords in xmm2/m128, and stored with some of the scheduled dwords in xmm1.

Instruction Operand Encoding:

Op/En	Operand 1	        Operand 2	    Operand 3
RM	    ModRM:reg (r, w)	ModRM:r/m (r)	N/A

Description:

The SHA1NEXTE calculates the SHA1 state variable E after four rounds of operation from the current SHA1 state variable A in the destination operand. The calculated value of the SHA1 state variable E is added to the source operand, which contains the scheduled dwords.

Operation:

SHA1NEXTE:

TMP := (SRC1[127:96] ROL 30);
DEST[127:96] := SRC2[127:96] + TMP;
DEST[95:64] := SRC2[95:64];
DEST[63:32] := SRC2[63:32];
DEST[31:0] := SRC2[31:0];

Intel C/C++ Compiler Intrinsic Equivalent:

SHA1NEXTE __m128i _mm_sha1nexte_epu32(__m128i, __m128i);

Flags Affected:

None.

SIMD Floating-Point Exceptions:

None.

Other Exceptions:

See Table 2-21, “Type 4 Class Exception Conditions.”


SHA1RNDS4 — Perform Four Rounds of SHA1 Operation

Opcode/Instruction	                                Op/En	64/32 bit Mode Support	CPUID Feature Flag	Description
NP 0F 3A CC /r ib SHA1RNDS4 xmm1, xmm2/m128, imm8	RMI	    V/V	                    SHA	                Performs four rounds of SHA1 operation operating on SHA1 state (A,B,C,D) from xmm1, with a pre-computed sum of the next 4 round message dwords and state variable E from xmm2/m128. The immediate byte controls logic functions and round constants.

Instruction Operand Encoding:

Op/En	Operand 1	        Operand 2	    Operand 3
RMI	    ModRM:reg (r, w)	ModRM:r/m (r)	imm8

Description:

The SHA1RNDS4 instruction performs four rounds of SHA1 operation using an initial SHA1 state (A,B,C,D) from the first operand (which is a source operand and the destination operand) and some pre-computed sum of the next 4 round message dwords, and state variable E from the second operand (a source operand). The updated SHA1 state (A,B,C,D) after four rounds of processing is stored in the destination operand.

Operation:

SHA1RNDS4:

The function f() and Constant K are dependent on the value of the immediate.
IF ( imm8[1:0] = 0 )
    THEN f() := f0(),
        K := K0;
ELSE IF ( imm8[1:0]
        = 1 )
    THEN f() := f1(),
        K := K1;
ELSE IF ( imm8[1:0]
        = 2 )
    THEN f() := f2(),
        K := K2;
ELSE IF ( imm8[1:0]
        = 3 )
    THEN f() := f3(),
        K := K3;
FI;
A := SRC1[127:96];
B := SRC1[95:64];
C := SRC1[63:32];
D := SRC1[31:0];
W0E := SRC2[127:96];
W1 := SRC2[95:64];
W2 := SRC2[63:32];
W3 := SRC2[31:0];
Round i = 0 operation:
A_1 := f (B, C, D) + (A ROL 5) +W0E +K;
B_1 := A;
C_1 := B ROL 30;
D_1 := C;
E_1 := D;
FOR i = 1 to 3
    A_(i +1) := f (B_i, C_i, D_i) + (A_i ROL 5) +Wi+ E_i +K;
    B_(i +1) := A_i;
    C_(i +1) := B_i ROL 30;
    D_(i +1) := C_i;
    E_(i +1) := D_i;
ENDFOR
DEST[127:96] := A_4;
DEST[95:64] := B_4;
DEST[63:32] := C_4;
DEST[31:0] := D_4;

Intel C/C++ Compiler Intrinsic Equivalent:

SHA1RNDS4 __m128i _mm_sha1rnds4_epu32(__m128i, __m128i, const int);

Flags Affected:

None.

SIMD Floating-Point Exceptions:

None.

Other Exceptions:

See Table 2-21, “Type 4 Class Exception Conditions.”






SHA256MSG1 — Perform an Intermediate Calculation for the Next Four SHA256 MessageDwords

Opcode/Instruction	                        Op/En	64/32 bit Mode Support	CPUID Feature Flag	Description
NP 0F 38 CC /r SHA256MSG1 xmm1, xmm2/m128	RM	    V/V	                    SHA	                Performs an intermediate calculation for the next four SHA256 message dwords using previous message dwords from xmm1 and xmm2/m128, storing the result in xmm1.

Instruction Operand Encoding:

Op/En	Operand 1	        Operand 2	    Operand 3
RM	    ModRM:reg (r, w)	ModRM:r/m (r)	N/A

Description:

The SHA256MSG1 instruction is one of two SHA256 message scheduling instructions. The instruction performs an intermediate calculation for the next four SHA256 message dwords.

Operation:

SHA256MSG1:

W4 := SRC2[31: 0] ;
W3 := SRC1[127:96] ;
W2 := SRC1[95:64] ;
W1 := SRC1[63: 32] ;
W0 := SRC1[31: 0] ;
DEST[127:96] := W3 + σ0( W4);
DEST[95:64] := W2 + σ0( W3);
DEST[63:32] := W1 + σ0( W2);
DEST[31:0] := W0 + σ0( W1);

Intel C/C++ Compiler Intrinsic Equivalent:

SHA256MSG1 __m128i _mm_sha256msg1_epu32(__m128i, __m128i);

Flags Affected:

None.

SIMD Floating-Point Exceptions:

None.

Other Exceptions:

See Table 2-21, “Type 4 Class Exception Conditions.”






SHA256MSG2 — Perform a Final Calculation for the Next Four SHA256 Message Dwords

Opcode/Instruction	                        Op/En	64/32 bit Mode Support	CPUID Feature Flag	Description
NP 0F 38 CD /r SHA256MSG2 xmm1, xmm2/m128	RM	    V/V	                    SHA	                Performs the final calculation for the next four SHA256 message dwords using previous message dwords from xmm1 and xmm2/m128, storing the result in xmm1.

Instruction Operand Encoding:

Op/En	Operand 1	        Operand 2	    Operand 3
RM	    ModRM:reg (r, w)	ModRM:r/m (r)	N/A

Description:

The SHA256MSG2 instruction is one of two SHA2 message scheduling instructions. The instruction performs the final calculation for the next four SHA256 message dwords.

Operation:

SHA256MSG2:

W14 := SRC2[95:64] ;
W15 := SRC2[127:96] ;
W16 := SRC1[31: 0] + σ1( W14) ;
W17 := SRC1[63: 32] + σ1( W15) ;
W18 := SRC1[95: 64] + σ1( W16) ;
W19 := SRC1[127: 96] + σ1( W17) ;
DEST[127:96] := W19 ;
DEST[95:64] := W18 ;
DEST[63:32] := W17 ;
DEST[31:0] := W16;

Intel C/C++ Compiler Intrinsic Equivalent:

SHA256MSG2 __m128i _mm_sha256msg2_epu32(__m128i, __m128i);

Flags Affected:

None.

SIMD Floating-Point Exceptions:

None.

Other Exceptions:

See Table 2-21, “Type 4 Class Exception Conditions.”






SHA256RNDS2 — Perform Two Rounds of SHA256 Operation

Opcode/Instruction	                                    Op/En	64/32 bit Mode Support	CPUID Feature Flag	Description
NP 0F 38 CB /r SHA256RNDS2 xmm1, xmm2/m128, <XMM0>	    RMI	    V/V	                    SHA	                Perform 2 rounds of SHA256 operation using an initial SHA256 state (C,D,G,H) from xmm1, an initial SHA256 state (A,B,E,F) from xmm2/m128, and a pre-computed sum of the next 2 round message dwords and the corresponding round constants from the implicit operand XMM0, storing the updated SHA256 state (A,B,E,F) result in xmm1.

Instruction Operand Encoding:

Op/En	Operand 1	        Operand 2	    Operand 3
RMI	    ModRM:reg (r, w)	ModRM:r/m (r)	Implicit XMM0 (r)

Description:

The SHA256RNDS2 instruction performs 2 rounds of SHA256 operation using an initial SHA256 state (C,D,G,H) from the first operand, an initial SHA256 state (A,B,E,F) from the second operand, and a pre-computed sum of the next 2 round message dwords and the corresponding round constants from the implicit operand xmm0. Note that only the two lower dwords of XMM0 are used by the instruction.

The updated SHA256 state (A,B,E,F) is written to the first operand, and the second operand can be used as the updated state (C,D,G,H) in later rounds.

Operation:

SHA256RNDS2:

A_0 := SRC2[127:96];
B_0 := SRC2[95:64];
C_0 := SRC1[127:96];
D_0 := SRC1[95:64];
E_0 := SRC2[63:32];
F_0 := SRC2[31:0];
G_0 := SRC1[63:32];
H_0 := SRC1[31:0];
WK0 := XMM0[31: 0];
WK1 := XMM0[63: 32];
FOR i = 0 to 1
    A_(i +1) :=
        Ch (E_i, F_i, G_i) +Σ1( E_i) +WKi+ H_i + Maj(A_i , B_i, C_i) +Σ0( A_i);
    B_(i +1) :=
        A_i;
    C_(i +1) :=
        B_i ;
    D_(i +1) :=
        C_i;
    E_(i +1) :=
        Ch (E_i, F_i, G_i) +Σ1( E_i) +WKi+ H_i + D_i;
    F_(i +1) :=
        E_i ;
    G_(i +1) :=
        F_i;
    H_(i +1) :=
        G_i;
ENDFOR
DEST[127:96] := A_2;
DEST[95:64] := B_2;
DEST[63:32] := E_2;
DEST[31:0] := F_2;

Intel C/C++ Compiler Intrinsic Equivalent:

SHA256RNDS2 __m128i _mm_sha256rnds2_epu32(__m128i, __m128i, __m128i);

Flags Affected:

None.

SIMD Floating-Point Exceptions:

None.

Other Exceptions:

See Table 2-21, “Type 4 Class Exception Conditions.”





