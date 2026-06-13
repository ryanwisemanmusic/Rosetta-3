AESDEC — Perform One Round of an AES Decryption Flow

Opcode/Instruction	                                        Op/En	64/32-bit Mode	CPUID Feature Flag	Description
66 0F 38 DE /r AESDEC xmm1, xmm2/m128	                    A	    V/V	            AES	                Perform one round of an AES decryption flow, using the Equivalent Inverse Cipher, using one 128-bit data (state) from xmm1 with one 128-bit round key from xmm2/m128.
VEX.128.66.0F38.WIG DE /r VAESDEC xmm1, xmm2, xmm3/m128	    B	    V/V	            AES AVX	            Perform one round of an AES decryption flow, using the Equivalent Inverse Cipher, using one 128-bit data (state) from xmm2 with one 128-bit round key from xmm3/m128; store the result in xmm1.
VEX.256.66.0F38.WIG DE /r VAESDEC ymm1, ymm2, ymm3/m256	    B	    V/V	            VAES	            Perform one round of an AES decryption flow, using the Equivalent Inverse Cipher, using two 128-bit data (state) from ymm2 with two 128-bit round keys from ymm3/m256; store the result in ymm1.
EVEX.128.66.0F38.WIG DE /r VAESDEC xmm1, xmm2, xmm3/m128	C	    V/V	            VAES AVX512VL	    Perform one round of an AES decryption flow, using the Equivalent Inverse Cipher, using one 128-bit data (state) from xmm2 with one 128-bit round key from xmm3/m128; store the result in xmm1.
EVEX.256.66.0F38.WIG DE /r VAESDEC ymm1, ymm2, ymm3/m256	C	    V/V	            VAES AVX512VL	    Perform one round of an AES decryption flow, using the Equivalent Inverse Cipher, using two 128-bit data (state) from ymm2 with two 128-bit round keys from ymm3/m256; store the result in ymm1.
EVEX.512.66.0F38.WIG DE /r VAESDEC zmm1, zmm2, zmm3/m512	C	    V/V	            VAES AVX512F	    Perform one round of an AES decryption flow, using the Equivalent Inverse Cipher, using four 128-bit data (state) from zmm2 with four 128-bit round keys from zmm3/m512; store the result in zmm1.

Instruction Operand Encoding:

Op/En	Tuple	    Operand 1	        Operand 2	    Operand 3	    Operand 4
A	    N/A	        ModRM:reg (r, w)	ModRM:r/m (r)	N/A	            N/A
B	    N/A	        ModRM:reg (w)	    VEX.vvvv (r)	ModRM:r/m (r)	N/A
C	    Full Mem	ModRM:reg (w)	    EVEX.vvvv (r)	ModRM:r/m (r)	N/A

Description:

This instruction performs a single round of the AES decryption flow using the Equivalent Inverse Cipher, using one/two/four (depending on vector length) 128-bit data (state) from the first source operand with one/two/four (depending on vector length) round key(s) from the second source operand, and stores the result in the destination operand.

Use the AESDEC instruction for all but the last decryption round. For the last decryption round, use the AESDECLAST instruction.

VEX and EVEX encoded versions of the instruction allow 3-operand (non-destructive) operation. The legacy encoded versions of the instruction require that the first source operand and the destination operand are the same and must be an XMM register.

The EVEX encoded form of this instruction does not support memory fault suppression.

Operation:

AESDEC:

STATE := SRC1;
RoundKey := SRC2;
STATE := InvShiftRows( STATE );
STATE := InvSubBytes( STATE );
STATE := InvMixColumns( STATE );
DEST[127:0] := STATE XOR RoundKey;
DEST[MAXVL-1:128] (Unmodified)

VAESDEC (128b and 256b VEX Encoded Versions):

(KL,VL) = (1,128), (2,256)
FOR i = 0 to KL-1:
    STATE := SRC1.xmm[i]
    RoundKey := SRC2.xmm[i]
    STATE := InvShiftRows( STATE )
    STATE := InvSubBytes( STATE )
    STATE := InvMixColumns( STATE )
    DEST.xmm[i] := STATE XOR RoundKey
DEST[MAXVL-1:VL] := 0

VAESDEC (EVEX Encoded Version):

(KL,VL) = (1,128), (2,256), (4,512)
FOR i = 0 to KL-1:
    STATE := SRC1.xmm[i]
    RoundKey := SRC2.xmm[i]
    STATE := InvShiftRows( STATE )
    STATE := InvSubBytes( STATE )
    STATE := InvMixColumns( STATE )
    DEST.xmm[i] := STATE XOR RoundKey
DEST[MAXVL-1:VL] :=0

Intel C/C++ Compiler Intrinsic Equivalent:

(V)AESDEC __m128i _mm_aesdec (__m128i, __m128i)
VAESDEC __m256i _mm256_aesdec_epi128(__m256i, __m256i);
VAESDEC __m512i _mm512_aesdec_epi128(__m512i, __m512i);

SIMD Floating-Point Exceptions:

None.

Other Exceptions:

See Table 2-21, “Type 4 Class Exception Conditions.”

EVEX-encoded: See Table 2-50, “Type E4NF Class Exception Conditions.”

AESDEC128KL — Perform Ten Rounds of AES Decryption Flow With Key Locker Using 128-BitKey

Opcode/Instruction	                                Op/En	64/32-bit Mode	CPUID Feature Flag	Description
F3 0F 38 DD !(11):rrr:bbb AESDEC128KL xmm, m384	    A	    V/V	            AESKLE	            Decrypt xmm using 128-bit AES key indicated by handle at m384 and store result in xmm.
Instruction Operand Encoding ¶

Op/En	Tuple	Operand 1	        Operand 2	    Operand 3	Operand 4
A	    N/A	    ModRM:reg (r, w)	ModRM:r/m (r)	N/A	        N/A

Description:

The AESDEC128KL1 instruction performs 10 rounds of AES to decrypt the first operand using the 128-bit key indicated by the handle from the second operand. It stores the result in the first operand if the operation succeeds (e.g., does not run into a handle violation failure).

Operation:

AESDEC128KL:

Handle := UnalignedLoad of 384 bit (SRC); // Load is not guaranteed to be atomic.
Illegal Handle = (HandleReservedBitSet (Handle) ||
                (Handle[0] AND (CPL > 0)) ||
                Handle [2] ||
                HandleKeyType (Handle) != HANDLE_KEY_TYPE_AES128);
IF (Illegal Handle) {
    THEN RFLAGS.ZF := 1;
    ELSE
        (UnwrappedKey, Authentic) := UnwrapKeyAndAuthenticate384 (Handle[383:0], IWKey);
        IF (Authentic == 0)
            THEN RFLAGS.ZF := 1;
            ELSE
                    DEST := AES128Decrypt (DEST, UnwrappedKey) ;
                    RFLAGS.ZF := 0;
        FI;
FI;
RFLAGS.OF, SF, AF, PF, CF := 0;

Flags Affected:

ZF is set to 0 if the operation succeeded and set to 1 if the operation failed due to a handle violation. The other arithmetic flags (OF, SF, AF, PF, CF) are cleared to 0.

Intel C/C++ Compiler Intrinsic Equivalent:

AESDEC128KL unsigned char _mm_aesdec128kl_u8(__m128i* odata, __m128i idata, const void* h);
1. Further details on Key Locker and usage of this instruction can be found here:
https://software.intel.com/content/www/us/en/develop/download/intel-key-locker-specification.html.

Exceptions (All Operating Modes):

#UD:
    If the LOCK prefix is used.

    If CPUID.07H:ECX.KL[bit 23] = 0.

    If CR4.KL = 0.

    If CPUID.19H:EBX.AESKLE[bit 0] = 0.

    If CR0.EM = 1.

    If CR4.OSFXSR = 0.

#NM:
    If CR0.TS = 1.

#PF:
    If a page fault occurs.

#GP(0):
    If a memory operand effective address is outside the CS, DS, ES, FS, or GS segment limit.

    If the DS, ES, FS, or GS register is used to access memory and it contains a NULL segment selector.

    If the memory address is in a non-canonical form.

#SS(0):
    If a memory operand effective address is outside the SS segment limit.

    If a memory address referencing the SS segment is in a non-canonical form.


AESDEC256KL — Perform 14 Rounds of AES Decryption Flow With Key Locker Using 256-Bit Key

Opcode/Instruction	                                Op/En	64/32-bit Mode	CPUID Feature Flag	Description
F3 0F 38 DF !(11):rrr:bbb AESDEC256KL xmm, m512	    A	    V/V	            AESKLE	            Decrypt xmm using 256-bit AES key indicated by handle at m512 and store result in xmm.

Instruction Operand Encoding:

Op/En	Tuple	Operand 1	        Operand 2	    Operand 3	Operand 4
A	    N/A	    ModRM:reg (r, w)	ModRM:r/m (r)	N/A	        N/A

Description:

The AESDEC256KL1 instruction performs 14 rounds of AES to decrypt the first operand using the 256-bit key indicated by the handle from the second operand. It stores the result in the first operand if the operation succeeds (e.g., does not run into a handle violation failure).

Operation:

AESDEC256KL:

Handle := UnalignedLoad of 512 bit (SRC); // Load is not guaranteed to be atomic.
Illegal Handle = (HandleReservedBitSet (Handle) ||
                (Handle[0] AND (CPL > 0)) ||
                Handle [2] ||
                HandleKeyType (Handle) != HANDLE_KEY_TYPE_AES256);
IF (Illegal Handle)
    THEN RFLAGS.ZF := 1;
    ELSE
        (UnwrappedKey, Authentic) := UnwrapKeyAndAuthenticate512 (Handle[511:0], IWKey);
        IF (Authentic == 0)
            THEN RFLAGS.ZF := 1;
            ELSE
                    DEST := AES256Decrypt (DEST, UnwrappedKey) ;
                    RFLAGS.ZF := 0;
        FI;
FI;
RFLAGS.OF, SF, AF, PF, CF := 0;

Flags Affected:

ZF is set to 0 if the operation succeeded and set to 1 if the operation failed due to a handle violation. The other arithmetic flags (OF, SF, AF, PF, CF) are cleared to 0.

Intel C/C++ Compiler Intrinsic Equivalent:

AESDEC256KL unsigned char _mm_aesdec256kl_u8(__m128i* odata, __m128i idata, const void* h);
1. Further details on Key Locker and usage of this instruction can be found here:
https://software.intel.com/content/www/us/en/develop/download/intel-key-locker-specification.html.

Exceptions (All Operating Modes):

#UD:
    If the LOCK prefix is used.

    If CPUID.07H:ECX.KL[bit 23] = 0.

    If CR4.KL = 0.

    If CPUID.19H:EBX.AESKLE[bit 0] = 0.

    If CR0.EM = 1.

    If CR4.OSFXSR = 0.

#NM:
    If CR0.TS = 1.

#PF:
    If a page fault occurs.

#GP(0):
    If a memory operand effective address is outside the CS, DS, ES, FS, or GS segment limit.

    If the DS, ES, FS, or GS register is used to access memory and it contains a NULL segment selector.

    If the memory address is in a non-canonical form.

#SS(0):
    If a memory operand effective address is outside the SS segment limit.

    If a memory address referencing the SS segment is in a non-canonical form.


AESDECLAST — Perform Last Round of an AES Decryption Flow

Opcode/Instruction	                                            Op/En	64/32-bit Mode	CPUID Feature Flag	Description
66 0F 38 DF /r AESDECLAST xmm1, xmm2/m128	                    A	    V/V	            AES	                Perform the last round of an AES decryption flow, using the Equivalent Inverse Cipher, using one 128-bit data (state) from xmm1 with one 128-bit round key from xmm2/m128.
VEX.128.66.0F38.WIG DF /r VAESDECLAST xmm1, xmm2, xmm3/m128	    B	    V/V	            AES AVX	            Perform the last round of an AES decryption flow, using the Equivalent Inverse Cipher, using one 128-bit data (state) from xmm2 with one 128-bit round key from xmm3/m128; store the result in xmm1.
VEX.256.66.0F38.WIG DF /r VAESDECLAST ymm1, ymm2, ymm3/m256	    B	    V/V	            VAES	            Perform the last round of an AES decryption flow, using the Equivalent Inverse Cipher, using two 128-bit data (state) from ymm2 with two 128-bit round keys from ymm3/m256; store the result in ymm1.
EVEX.128.66.0F38.WIG DF /r VAESDECLAST xmm1, xmm2, xmm3/m128	C	    V/V	            VAES AVX512VL	    Perform the last round of an AES decryption flow, using the Equivalent Inverse Cipher, using one 128-bit data (state) from xmm2 with one 128-bit round key from xmm3/m128; store the result in xmm1.
EVEX.256.66.0F38.WIG DF /r VAESDECLAST ymm1, ymm2, ymm3/m256	C	    V/V	            VAES AVX512VL	    Perform the last round of an AES decryption flow, using the Equivalent Inverse Cipher, using two 128-bit data (state) from ymm2 with two 128-bit round keys from ymm3/m256; store the result in ymm1.
EVEX.512.66.0F38.WIG DF /r VAESDECLAST zmm1, zmm2, zmm3/m512	C	    V/V	V           AES AVX512F	        Perform the last round of an AES decryption flow, using the Equivalent Inverse Cipher, using four128-bit data (state) from zmm2 with four 128-bit round keys from zmm3/m512; store the result in zmm1.

Instruction Operand Encoding:

Op/En	Tuple	    Operand 1	        Operand 2	    Operand 3	    Operand 4
A	    N/A	        ModRM:reg (r, w)	ModRM:r/m (r)	N/A	            N/A
B	    N/A	        ModRM:reg (w)	    VEX.vvvv (r)	ModRM:r/m (r)	N/A
C	    Full Mem	ModRM:reg (w)	    EVEX.vvvv (r)	ModRM:r/m (r)	N/A

Description:

This instruction performs the last round of the AES decryption flow using the Equivalent Inverse Cipher, using one/two/four (depending on vector length) 128-bit data (state) from the first source operand with one/two/four (depending on vector length) round key(s) from the second source operand, and stores the result in the destination operand.

VEX and EVEX encoded versions of the instruction allow 3-operand (non-destructive) operation. The legacy encoded versions of the instruction require that the first source operand and the destination operand are the same and must be an XMM register.

The EVEX encoded form of this instruction does not support memory fault suppression.

Operation:

AESDECLAST:

STATE := SRC1;
RoundKey := SRC2;
STATE := InvShiftRows( STATE );
STATE := InvSubBytes( STATE );
DEST[127:0] := STATE XOR RoundKey;
DEST[MAXVL-1:128] (Unmodified)

VAESDECLAST (128b and 256b VEX Encoded Versions):

(KL,VL) = (1,128), (2,256)
FOR i = 0 to KL-1:
    STATE := SRC1.xmm[i]
    RoundKey := SRC2.xmm[i]
    STATE := InvShiftRows( STATE )
    STATE := InvSubBytes( STATE )
    DEST.xmm[i] := STATE XOR RoundKey
DEST[MAXVL-1:VL] := 0

VAESDECLAST (EVEX Encoded Version):

(KL,VL) = (1,128), (2,256), (4,512)
FOR i = 0 to KL-1:
    STATE := SRC1.xmm[i]
    RoundKey := SRC2.xmm[i]
    STATE := InvShiftRows( STATE )
    STATE := InvSubBytes( STATE )
    DEST.xmm[i] := STATE XOR RoundKey
DEST[MAXVL-1:VL] := 0

Intel C/C++ Compiler Intrinsic Equivalent:

(V)AESDECLAST __m128i _mm_aesdeclast (__m128i, __m128i)
VAESDECLAST __m256i _mm256_aesdeclast_epi128(__m256i, __m256i);
VAESDECLAST __m512i _mm512_aesdeclast_epi128(__m512i, __m512i);

SIMD Floating-Point Exceptions:

None.

Other Exceptions:

See Table 2-21, “Type 4 Class Exception Conditions.”

EVEX-encoded: See Table 2-50, “Type E4NF Class Exception Conditions.”


AESDECWIDE128KL — Perform Ten Rounds of AES Decryption Flow With Key Locker on 8 BlocksUsing 128-Bit Key

Opcode/Instruction	                                        Op/En	64/32-bit Mode	CPUID Feature Flag	Description
F3 0F 38 D8 !(11):001:bbb AESDECWIDE128KL m384, <XMM0-7>	A	    V/V	            AESKLEWIDE_KL	    Decrypt XMM0-7 using 128-bit AES key indicated by handle at m384 and store each resultant block back to its corresponding register.

Instruction Operand Encoding:

Op/En	Tuple	Operand 1	    Operands 2—9
A	    N/A	    ModRM:r/m (r)	Implicit XMM0-7 (r, w)

Description:

The AESDECWIDE128KL1 instruction performs ten rounds of AES to decrypt each of the eight blocks in XMM0-7 using the 128-bit key indicated by the handle from the second operand. It replaces each input block in XMM0-7 with its corresponding decrypted block if the operation succeeds (e.g., does not run into a handle violation failure).

Operation:

AESDECWIDE128KL:

Handle := UnalignedLoad of 384 bit (SRC); // Load is not guaranteed to be atomic.
Illegal Handle = (HandleReservedBitSet (Handle) ||
                (Handle[0] AND (CPL > 0)) ||
                Handle [2] ||
                HandleKeyType (Handle) != HANDLE_KEY_TYPE_AES128);
IF (Illegal Handle)
    THEN RFLAGS.ZF := 1;
    ELSE
        (UnwrappedKey, Authentic) := UnwrapKeyAndAuthenticate384 (Handle[383:0], IWKey);
        IF Authentic == 0 {
            THEN RFLAGS.ZF := 1;
            ELSE
                    XMM0 := AES128Decrypt (XMM0, UnwrappedKey) ;
                    XMM1 := AES128Decrypt (XMM1, UnwrappedKey) ;
                    XMM2 := AES128Decrypt (XMM2, UnwrappedKey) ;
                    XMM3 := AES128Decrypt (XMM3, UnwrappedKey) ;
                    XMM4 := AES128Decrypt (XMM4, UnwrappedKey) ;
                    XMM5 := AES128Decrypt (XMM5, UnwrappedKey) ;
                    XMM6 := AES128Decrypt (XMM6, UnwrappedKey) ;
                    XMM7 := AES128Decrypt (XMM7, UnwrappedKey) ;
                    RFLAGS.ZF := 0;
        FI;
FI;
RFLAGS.OF, SF, AF, PF, CF := 0;

Flags Affected:

ZF is set to 0 if the operation succeeded and set to 1 if the operation failed due to a handle violation. The other arithmetic flags (OF, SF, AF, PF, CF) are cleared to 0.

1. Further details on Key Locker and usage of this instruction can be found here:

https://software.intel.com/content/www/us/en/develop/download/intel-key-locker-specification.html.

Intel C/C++ Compiler Intrinsic Equivalent:

AESDECWIDE128KLunsigned char _mm_aesdecwide128kl_u8(__m128i odata[8], const __m128i idata[8], const void* h);

Exceptions (All Operating Modes):

#UD:
    If the LOCK prefix is used.

    If CPUID.07H:ECX.KL[bit 23] = 0.

    If CR4.KL = 0.

    If CPUID.19H:EBX.AESKLE[bit 0] = 0.

    If CR0.EM = 1.

    If CR4.OSFXSR = 0.

    If CPUID.19H:EBX.WIDE_KL[bit 2] = 0.

#NM:
    If CR0.TS = 1.

#PF:
    If a page fault occurs.

#GP(0):
    If a memory operand effective address is outside the CS, DS, ES, FS, or GS segment limit.

    If the DS, ES, FS, or GS register is used to access memory and it contains a NULL segment selector.

    If the memory address is in a non-canonical form.

#SS(0):
    If a memory operand effective address is outside the SS segment limit.

    If a memory address referencing the SS segment is in a non-canonical form.


AESDECWIDE256KL — Perform 14 Rounds of AES Decryption Flow With Key Locker on 8 BlocksUsing 256-Bit Key

Opcode/Instruction	                                        Op/En	64/32-bit Mode	CPUID Feature Flag	Description
F3 0F 38 D8 !(11):011:bbb AESDECWIDE256KL m512, <XMM0-7>	A	    V/V	            AESKLEWIDE_KL	    Decrypt XMM0-7 using 256-bit AES key indicated by handle at m512 and store each resultant block back to its corresponding register.

Instruction Operand Encoding:

Op/En	Tuple	Operand 1	    Operands 2—9
A	    N/A	    ModRM:r/m (r)	Implicit XMM0-7 (r, w)

Description:

The AESDECWIDE256KL1 instruction performs 14 rounds of AES to decrypt each of the eight blocks in XMM0-7 using the 256-bit key indicated by the handle from the second operand. It replaces each input block in XMM0-7 with its corresponding decrypted block if the operation succeeds (e.g., does not run into a handle violation failure).

Operation:

AESDECWIDE256KL:

Handle := UnalignedLoad of 512 bit (SRC); // Load is not guaranteed to be atomic.
Illegal Handle = (HandleReservedBitSet (Handle) ||
                (Handle[0] AND (CPL > 0)) ||
                Handle [2] ||
                HandleKeyType (Handle) != HANDLE_KEY_TYPE_AES256);
IF (Illegal Handle) {
    THEN RFLAGS.ZF := 1;
    ELSE
        (UnwrappedKey, Authentic) := UnwrapKeyAndAuthenticate512 (Handle[511:0], IWKey);
        IF (Authentic == 0)
            THEN RFLAGS.ZF := 1;
            ELSE
                XMM0 := AES256Decrypt (XMM0, UnwrappedKey) ;
                XMM1 := AES256Decrypt (XMM1, UnwrappedKey) ;
                XMM2 := AES256Decrypt (XMM2, UnwrappedKey) ;
                XMM3 := AES256Decrypt (XMM3, UnwrappedKey) ;
                XMM4 := AES256Decrypt (XMM4, UnwrappedKey) ;
                XMM5 := AES256Decrypt (XMM5, UnwrappedKey) ;
                XMM6 := AES256Decrypt (XMM6, UnwrappedKey) ;
                XMM7 := AES256Decrypt (XMM7, UnwrappedKey) ;
                RFLAGS.ZF := 0;
        FI;
FI;
RFLAGS.OF, SF, AF, PF, CF := 0;

Flags Affected:

ZF is set to 0 if the operation succeeded and set to 1 if the operation failed due to a handle violation. The other arithmetic flags (OF, SF, AF, PF, CF) are cleared to 0.

1. Further details on Key Locker and usage of this instruction can be found here:

https://software.intel.com/content/www/us/en/develop/download/intel-key-locker-specification.html.

Intel C/C++ Compiler Intrinsic Equivalent:

AESDECWIDE256KLunsigned char _mm_aesdecwide256kl_u8(__m128i odata[8], const __m128i idata[8], const void* h);
Exceptions (All Operating Modes) ¶

#UD:
    If the LOCK prefix is used.

    If CPUID.07H:ECX.KL[bit 23] = 0.

    If CR4.KL = 0.

    If CPUID.19H:EBX.AESKLE[bit 0] = 0.

    If CR0.EM = 1.

    If CR4.OSFXSR = 0.

    If CPUID.19H:EBX.WIDE_KL[bit 2] = 0.

#NM:
    If CR0.TS = 1.

#PF:
    If a page fault occurs.

#GP(0):
    If a memory operand effective address is outside the CS, DS, ES, FS, or GS segment limit.

    If the DS, ES, FS, or GS register is used to access memory and it contains a NULL segment selector.

    If the memory address is in a non-canonical form.

#SS(0):
    If a memory operand effective address is outside the SS segment limit.

    If a memory address referencing the SS segment is in a non-canonical form.


AESENC — Perform One Round of an AES Encryption Flow

Opcode/Instruction	                                        Op/En	64/32-bit Mode	CPUID Feature Flag	Description
66 0F 38 DC /r AESENC xmm1, xmm2/m128	                    A	    V/V	            AES	                Perform one round of an AES encryption flow, using one 128-bit data (state) from xmm1 with one 128-bit round key from xmm2/m128.
VEX.128.66.0F38.WIG DC /r VAESENC xmm1, xmm2, xmm3/m128	    B	    V/V	            AES AVX	            Perform one round of an AES encryption flow, using one 128-bit data (state) from xmm2 with one 128-bit round key from the xmm3/m128; store the result in xmm1.
VEX.256.66.0F38.WIG DC /r VAESENC ymm1, ymm2, ymm3/m256	    B	    V/V	            VAES	            Perform one round of an AES encryption flow, using two 128-bit data (state) from ymm2 with two 128-bit round keys from the ymm3/m256; store the result in ymm1.
EVEX.128.66.0F38.WIG DC /r VAESENC xmm1, xmm2, xmm3/m128	C	    V/V	            VAES AVX512VL	    Perform one round of an AES encryption flow, using one 128-bit data (state) from xmm2 with one 128-bit round key from the xmm3/m128; store the result in xmm1.
EVEX.256.66.0F38.WIG DC /r VAESENC ymm1, ymm2, ymm3/m256	C	    V/V	            VAES AVX512VL	    Perform one round of an AES encryption flow, using two 128-bit data (state) from ymm2 with two 128-bit round keys from the ymm3/m256; store the result in ymm1.
EVEX.512.66.0F38.WIG DC /r VAESENC zmm1, zmm2, zmm3/m512	C	    V/V	V           AES AVX512F	        Perform one round of an AES encryption flow, using four 128-bit data (state) from zmm2 with four 128-bit round keys from the zmm3/m512; store the result in zmm1.

Instruction Operand Encoding:

Op/En	Tuple	    Operand 1	        Operand 2	    Operand 3	    Operand 4
A	    N/A	        ModRM:reg (r, w)	ModRM:r/m (r)	N/A	            N/A
B	    N/A	        ModRM:reg (w)	    VEX.vvvv (r)	ModRM:r/m (r)	N/A
C	    Full Mem	ModRM:reg (w)	    EVEX.vvvv (r)	ModRM:r/m (r)	N/A

Description:

This instruction performs a single round of an AES encryption flow using one/two/four (depending on vector length) 128-bit data (state) from the first source operand with one/two/four (depending on vector length) round key(s) from the second source operand, and stores the result in the destination operand.

Use the AESENC instruction for all but the last encryption rounds. For the last encryption round, use the AESENCCLAST instruction.

VEX and EVEX encoded versions of the instruction allow 3-operand (non-destructive) operation. The legacy encoded versions of the instruction require that the first source operand and the destination operand are the same and must be an XMM register.

The EVEX encoded form of this instruction does not support memory fault suppression.

Operation:

AESENC:

STATE := SRC1;
RoundKey := SRC2;
STATE := ShiftRows( STATE );
STATE := SubBytes( STATE );
STATE := MixColumns( STATE );
DEST[127:0] := STATE XOR RoundKey;
DEST[MAXVL-1:128] (Unmodified)

VAESENC (128b and 256b VEX Encoded Versions):

(KL,VL) = (1,128), (2,256)
FOR I := 0 to KL-1:
    STATE := SRC1.xmm[i]
    RoundKey := SRC2.xmm[i]
    STATE := ShiftRows( STATE )
    STATE := SubBytes( STATE )
    STATE := MixColumns( STATE )
    DEST.xmm[i] := STATE XOR RoundKey
DEST[MAXVL-1:VL] := 0

VAESENC (EVEX Encoded Version):

(KL,VL) = (1,128), (2,256), (4,512)
FOR i := 0 to KL-1:
    STATE := SRC1.xmm[i] // xmm[i] is the i’th xmm word in the SIMD register
    RoundKey := SRC2.xmm[i]
    STATE := ShiftRows( STATE )
    STATE := SubBytes( STATE )
    STATE := MixColumns( STATE )
    DEST.xmm[i] := STATE XOR RoundKey
DEST[MAXVL-1:VL] := 0

Intel C/C++ Compiler Intrinsic Equivalent:

(V)AESENC __m128i _mm_aesenc (__m128i, __m128i)
VAESENC __m256i _mm256_aesenc_epi128(__m256i, __m256i);
VAESENC __m512i _mm512_aesenc_epi128(__m512i, __m512i);

SIMD Floating-Point Exceptions:

None.

Other Exceptions:

See Table 2-21, “Type 4 Class Exception Conditions.”

EVEX-encoded: See Table 2-50, “Type E4NF Class Exception Conditions.”




AESENC128KL — Perform Ten Rounds of AES Encryption Flow With Key Locker Using 128-Bit Key

Opcode/Instruction	Op/En	64/32-bit Mode	CPUID Feature Flag	Description
F3 0F 38 DC !(11):rrr:bbb AESENC128KL xmm, m384	A	V/V	AESKLE	Encrypt xmm using 128-bit AES key indicated by handle at m384 and store result in xmm.

Instruction Operand Encoding:

Op/En	Tuple	Operand 1	        Operand 2	    Operand 3	Operand 4
A	    N/A	    ModRM:reg (r, w)	ModRM:r/m (r)	N/A	        N/A

Description:

The AESENC128KL1 instruction performs ten rounds of AES to encrypt the first operand using the 128-bit key indicated by the handle from the second operand. It stores the result in the first operand if the operation succeeds (e.g., does not run into a handle violation failure).

Operation:

AESENC128KL:

Handle := UnalignedLoad of 384 bit (SRC); // Load is not guaranteed to be atomic.
Illegal Handle = (
                HandleReservedBitSet (Handle) ||
                (Handle[0] AND (CPL > 0)) ||
                Handle [1] ||
                HandleKeyType (Handle) != HANDLE_KEY_TYPE_AES128
                );
IF (Illegal Handle) {
    THEN RFLAGS.ZF := 1;
    ELSE
        (UnwrappedKey, Authentic) := UnwrapKeyAndAuthenticate384 (Handle[383:0], IWKey);
        IF (Authentic == 0)
        THEN RFLAGS.ZF := 1;
        ELSE
            DEST := AES128Encrypt (DEST, UnwrappedKey) ;
            RFLAGS.ZF := 0;
        FI;
FI;
RFLAGS.OF, SF, AF, PF, CF := 0;

Flags Affected:

ZF is set to 0 if the operation succeeded and set to 1 if the operation failed due to a handle violation. The other arithmetic flags (OF, SF, AF, PF, CF) are cleared to 0.

Intel C/C++ Compiler Intrinsic Equivalent:

AESENC128KL unsigned char _mm_aesenc128kl_u8(__m128i* odata, __m128i idata, const void* h);
1. Further details on Key Locker and usage of this instruction can be found here:
https://software.intel.com/content/www/us/en/develop/download/intel-key-locker-specification.html.

Exceptions (All Operating Modes):

#UD:
    If the LOCK prefix is used.

    If CPUID.07H:ECX.KL[bit 23] = 0.

    If CR4.KL = 0.

    If CPUID.19H:EBX.AESKLE[bit 0] = 0.

    If CR0.EM = 1.

    If CR4.OSFXSR = 0.

#NM:
    If CR0.TS = 1.

#PF:
    If a page fault occurs.

#GP(0):
    If a memory operand effective address is outside the CS, DS, ES, FS, or GS segment limit.

    If the DS, ES, FS, or GS register is used to access memory and it contains a NULL segment selector.

    If the memory address is in a non-canonical form.

#SS(0):
    If a memory operand effective address is outside the SS segment limit.

    If a memory address referencing the SS segment is in a non-canonical form.


AESENC256KL — Perform 14 Rounds of AES Encryption Flow With Key Locker Using 256-Bit Key

Opcode/Instruction	                                Op/En	64/32-bit Mode	CPUID Feature Flag	Description
F3 0F 38 DE !(11):rrr:bbb AESENC256KL xmm, m512	    A	    V/V	            AESKLE	            Encrypt xmm using 256-bit AES key indicated by handle at m512 and store result in xmm.

Instruction Operand Encoding:

Op/En	Tuple	Operand 1	        Operand 2	    Operand 3	Operand 4
A	    N/A	    ModRM:reg (r, w)	ModRM:r/m (r)	N/A	        N/A

Description:

The AESENC256KL1 instruction performs 14 rounds of AES to encrypt the first operand using the 256-bit key indicated by the handle from the second operand. It stores the result in the first operand if the operation succeeds (e.g., does not run into a handle violation failure).

Operation:

AESENC256KL:

Handle := UnalignedLoad of 512 bit (SRC); // Load is not guaranteed to be atomic.
Illegal Handle = (
                HandleReservedBitSet (Handle) ||
                (Handle[0] AND (CPL > 0)) ||
                Handle [1] ||
                HandleKeyType (Handle) != HANDLE_KEY_TYPE_AES256
                );
IF (Illegal Handle)
    THEN RFLAGS.ZF := 1;
    ELSE
        (UnwrappedKey, Authentic) := UnwrapKeyAndAuthenticate512 (Handle[511:0], IWKey);
        IF (Authentic == 0)
            THEN RFLAGS.ZF := 1;
            ELSE
                    DEST := AES256Encrypt (DEST, UnwrappedKey) ;
                    RFLAGS.ZF := 0;
        FI;
FI;
RFLAGS.OF, SF, AF, PF, CF := 0;

Flags Affected:

ZF is set to 0 if the operation succeeded and set to 1 if the operation failed due to a handle violation. The other arithmetic flags (OF, SF, AF, PF, CF) are cleared to 0.

Intel C/C++ Compiler Intrinsic Equivalent:

AESENC256KL unsigned char _mm_aesenc256kl_u8(__m128i* odata, __m128i idata, const void* h);
1. Further details on Key Locker and usage of this instruction can be found here:
https://software.intel.com/content/www/us/en/develop/download/intel-key-locker-specification.html.

Exceptions (All Operating Modes)

#UD:
    If the LOCK prefix is used.

    If CPUID.07H:ECX.KL[bit 23] = 0.

    If CR4.KL = 0.

    If CPUID.19H:EBX.AESKLE[bit 0] = 0.

    If CR0.EM = 1.

    If CR4.OSFXSR = 0.

#NM:
    If CR0.TS = 1.

#PF:
    If a page fault occurs.

#GP(0):
    If a memory operand effective address is outside the CS, DS, ES, FS, or GS segment limit.

    If the DS, ES, FS, or GS register is used to access memory and it contains a NULL segment selector.

    If the memory address is in a non-canonical form.

#SS(0):
    If a memory operand effective address is outside the SS segment limit.

    If a memory address referencing the SS segment is in a non-canonical form.


AESENCLAST — Perform Last Round of an AES Encryption Flow

Opcode/Instruction	                                            Op/En	64/32-bit Mode	CPUID Feature Flag	Description
66 0F 38 DD /r AESENCLAST xmm1, xmm2/m128	                    A	    V/V	            AES	                Perform the last round of an AES encryption flow, using one 128-bit data (state) from xmm1 with one 128-bit round key from xmm2/m128.
VEX.128.66.0F38.WIG DD /r VAESENCLAST xmm1, xmm2, xmm3/m128	    B	    V/V	            AES AVX	            Perform the last round of an AES encryption flow, using one 128-bit data (state) from xmm2 with one 128-bit round key from xmm3/m128; store the result in xmm1.
VEX.256.66.0F38.WIG DD /r VAESENCLAST ymm1, ymm2, ymm3/m256	    B	    V/V	            VAES	            Perform the last round of an AES encryption flow, using two 128-bit data (state) from ymm2 with two 128-bit round keys from ymm3/m256; store the result in ymm1.
EVEX.128.66.0F38.WIG DD /r VAESENCLAST xmm1, xmm2, xmm3/m128	C	    V/V	            VAES AVX512VL	    Perform the last round of an AES encryption flow, using one 128-bit data (state) from xmm2 with one 128-bit round key from xmm3/m128; store the result in xmm1.
EVEX.256.66.0F38.WIG DD /r VAESENCLAST ymm1, ymm2, ymm3/m256	C	    V/V	            VAES AVX512VL	    Perform the last round of an AES encryption flow, using two 128-bit data (state) from ymm2 with two 128-bit round keys from ymm3/m256; store the result in ymm1.
EVEX.512.66.0F38.WIG DD /r VAESENCLAST zmm1, zmm2, zmm3/m512	C	    V/V	            VAES AVX512F	    Perform the last round of an AES encryption flow, using four 128-bit data (state) from zmm2 with four 128-bit round keys from zmm3/m512; store the result in zmm1.

Instruction Operand Encoding:

Op/En	Tuple	    Operand 1	        Operand 2	    Operand 3	    Operand 4
A	    N/A	        ModRM:reg (r, w)	ModRM:r/m (r)	N/A	            N/A
B	    N/A	        ModRM:reg (w)	    VEX.vvvv (r)	ModRM:r/m (r)	N/A
C	    Full Mem	ModRM:reg (w)	    EVEX.vvvv (r)	ModRM:r/m (r)	N/A

Description:

This instruction performs the last round of an AES encryption flow using one/two/four (depending on vector length) 128-bit data (state) from the first source operand with one/two/four (depending on vector length) round key(s) from the second source operand, and stores the result in the destination operand.

VEX and EVEX encoded versions of the instruction allows 3-operand (non-destructive) operation. The legacy encoded versions of the instruction require that the first source operand and the destination operand are the same and must be an XMM register.

The EVEX encoded form of this instruction does not support memory fault suppression.

Operation:

AESENCLAST:

STATE := SRC1;
RoundKey := SRC2;
STATE := ShiftRows( STATE );
STATE := SubBytes( STATE );
DEST[127:0] := STATE XOR RoundKey;
DEST[MAXVL-1:128] (Unmodified)

VAESENCLAST (128b and 256b VEX Encoded Versions):

(KL, VL) = (1,128), (2,256)
FOR I=0 to KL-1:
    STATE := SRC1.xmm[i]
    RoundKey := SRC2.xmm[i]
    STATE := ShiftRows( STATE )
    STATE := SubBytes( STATE )
    DEST.xmm[i] := STATE XOR RoundKey
DEST[MAXVL-1:VL] := 0

VAESENCLAST (EVEX Encoded Version):

(KL,VL) = (1,128), (2,256), (4,512)
FOR i = 0 to KL-1:
    STATE := SRC1.xmm[i]
    RoundKey := SRC2.xmm[i]
    STATE := ShiftRows( STATE )
    STATE := SubBytes( STATE )
    DEST.xmm[i] := STATE XOR RoundKey
DEST[MAXVL-1:VL] := 0

Intel C/C++ Compiler Intrinsic Equivalent:

(V)AESENCLAST __m128i _mm_aesenclast (__m128i, __m128i)
VAESENCLAST __m256i _mm256_aesenclast_epi128(__m256i, __m256i);
VAESENCLAST __m512i _mm512_aesenclast_epi128(__m512i, __m512i);

SIMD Floating-Point Exceptions:

None.

Other Exceptions:

See Table 2-21, “Type 4 Class Exception Conditions.”

EVEX-encoded: See Table 2-50, “Type E4NF Class Exception Conditions.”


AESENCWIDE128KL — Perform Ten Rounds of AES Encryption Flow With Key Locker on 8 BlocksUsing 128-Bit Key

Opcode/Instruction	                                        Op/En	64/32-bit Mode	CPUID Feature Flag	Description
F3 0F 38 D8 !(11):000:bbb AESENCWIDE128KL m384, <XMM0-7>	A	    V/V	            AESKLE WIDE_KL	    Encrypt XMM0-7 using 128-bit AES key indicated by handle at m384 and store each resultant block back to its corresponding register.

Instruction Operand Encoding:

Op/En	Tuple	Operand 1	    Operands 2—9
A	    N/A	    ModRM:r/m (r)	Implicit XMM0-7 (r, w)

Description:

The AESENCWIDE128KL1 instruction performs ten rounds of AES to encrypt each of the eight blocks in XMM0-7 using the 128-bit key indicated by the handle from the second operand. It replaces each input block in XMM0-7 with its corresponding encrypted block if the operation succeeds (e.g., does not run into a handle violation failure).

Operation:

AESENCWIDE128KL:

Handle := UnalignedLoad of 384 bit (SRC); // Load is not guaranteed to be atomic.
Illegal Handle = (
                HandleReservedBitSet (Handle) ||
                (Handle[0] AND (CPL > 0)) ||
                Handle [1] ||
                HandleKeyType (Handle) != HANDLE_KEY_TYPE_AES128
                );
IF (Illegal Handle)
    THEN RFLAGS.ZF := 1;
    ELSE
        (UnwrappedKey, Authentic) := UnwrapKeyAndAuthenticate384 (Handle[383:0], IWKey);
        IF Authentic == 0
            THEN RFLAGS.ZF := 1;
            ELSE
            XMM0 := AES128Encrypt (XMM0, UnwrappedKey) ;
                    XMM1 := AES128Encrypt (XMM1, UnwrappedKey) ;
                    XMM2 := AES128Encrypt (XMM2, UnwrappedKey) ;
                    XMM3 := AES128Encrypt (XMM3, UnwrappedKey) ;
                    XMM4 := AES128Encrypt (XMM4, UnwrappedKey) ;
                    XMM5 := AES128Encrypt (XMM5, UnwrappedKey) ;
                    XMM6 := AES128Encrypt (XMM6, UnwrappedKey) ;
                    XMM7 := AES128Encrypt (XMM7, UnwrappedKey) ;
                    RFLAGS.ZF := 0;
        FI;
FI;
RFLAGS.OF, SF, AF, PF, CF := 0;
1. Further details on Key Locker and usage of this instruction can be found here:
https://software.intel.com/content/www/us/en/develop/download/intel-key-locker-specification.html. 

Flags Affected:

ZF is set to 0 if the operation succeeded and set to 1 if the operation failed due to a handle violation. The other arithmetic flags (OF, SF, AF, PF, CF) are cleared to 0.

Intel C/C++ Compiler Intrinsic Equivalent:

AESENCWIDE128KLunsigned char _mm_aesencwide128kl_u8(__m128i odata[8], const __m128i idata[8], const void* h);

Exceptions (All Operating Modes):

#UD:
    If the LOCK prefix is used.

    If CPUID.07H:ECX.KL[bit 23] = 0.

    If CR4.KL = 0.

    If CPUID.AESKLE = 0.

    If CR0.EM = 1.

    If CR4.OSFXSR = 0.

    If CPUID.19H:EBX.WIDE_KL[bit 2] = 0.

#NM:
    If CR0.TS = 1.

#PF:
    If a page fault occurs.

#GP(0):
    If a memory operand effective address is outside the CS, DS, ES, FS, or GS segment limit.

    If the DS, ES, FS, or GS register is used to access memory and it contains a NULL segment selector.

    If the memory address is in a non-canonical form.

#SS(0):
    If a memory operand effective address is outside the SS segment limit.

    If a memory address referencing the SS segment is in a non-canonical form.


AESENCWIDE256KL — Perform 14 Rounds of AES Encryption Flow With Key Locker on 8 BlocksUsing 256-Bit Key

Opcode/Instruction	                                        Op/En   64/32-bit Mode	CPUID Feature Flag	Description
F3 0F 38 D8 !(11):010:bbb AESENCWIDE256KL m512, <XMM0-7>	A	    V/V	            AESKLE WIDE_KL	    Encrypt XMM0-7 using 256-bit AES key indicated by handle at m512 and store each resultant block back to its corresponding register.

Instruction Operand Encoding:

Op/En	Tuple	Operand 1	    Operands 2—9
A	    N/A	    ModRM:r/m (r)	Implicit XMM0-7 (r, w)

Description:

The AESENCWIDE256KL1 instruction performs 14 rounds of AES to encrypt each of the eight blocks in XMM0-7 using the 256-bit key indicated by the handle from the second operand. It replaces each input block in XMM0-7 with its corresponding encrypted block if the operation succeeds (e.g., does not run into a handle violation failure).

Operation:

AESENCWIDE256KL:

Handle := UnalignedLoad of 512 bit (SRC); // Load is not guaranteed to be atomic.
Illegal Handle = (
                HandleReservedBitSet (Handle) ||
                (Handle[0] AND (CPL > 0)) ||
                Handle [1] ||
                HandleKeyType (Handle) != HANDLE_KEY_TYPE_AES256
                );
IF (Illegal Handle)
    THEN RFLAGS.ZF := 1;
    ELSE
        (UnwrappedKey, Authentic) := UnwrapKeyAndAuthenticate512 (Handle[511:0], IWKey);
        IF (Authentic == 0)
            THEN RFLAGS.ZF := 1;
            ELSE
                    XMM0 := AES256Encrypt (XMM0, UnwrappedKey) ;
                    XMM1 := AES256Encrypt (XMM1, UnwrappedKey) ;
                    XMM2 := AES256Encrypt (XMM2, UnwrappedKey) ;
                    XMM3 := AES256Encrypt (XMM3, UnwrappedKey) ;
                    XMM4 := AES256Encrypt (XMM4, UnwrappedKey) ;
                    XMM5 := AES256Encrypt (XMM5, UnwrappedKey) ;
                    XMM6 := AES256Encrypt (XMM6, UnwrappedKey) ;
                    XMM7 := AES256Encrypt (XMM7, UnwrappedKey) ;
                    RFLAGS.ZF := 0;
        FI;
FI;
RFLAGS.OF, SF, AF, PF, CF := 0;
1. Further details on Key Locker and usage of this instruction can be found here:
https://software.intel.com/content/www/us/en/develop/download/intel-key-locker-specification.html.

Flags Affected:

ZF is set to 0 if the operation succeeded and set to 1 if the operation failed due to a handle violation. The other arithmetic flags (OF, SF, AF, PF, CF) are cleared to 0.

Intel C/C++ Compiler Intrinsic Equivalent:

AESENCWIDE256KLunsigned char _mm_aesencwide256kl_u8(__m128i odata[8], const __m128i idata[8], const void* h);

Exceptions (All Operating Modes):

#UD:
    If the LOCK prefix is used.

    If CPUID.07H:ECX.KL[bit 23] = 0.

    If CR4.KL = 0.

    If CPUID.19H:EBX.AESKLE[bit 0] = 0.

    If CR0.EM = 1.

    If CR4.OSFXSR = 0.

    If CPUID.19H:EBX.WIDE_KL[bit 2] = 0.

#NM:
    If CR0.TS = 1.

    #PF If a page fault occurs.

#GP(0):
    If a memory operand effective address is outside the CS, DS, ES, FS, or GS segment limit.

    If the DS, ES, FS, or GS register is used to access memory and it contains a NULL segment selector.

    If the memory address is in a non-canonical form.

#SS(0):
    If a memory operand effective address is outside the SS segment limit.

    If a memory address referencing the SS segment is in a non-canonical form.


AESIMC — Perform the AES InvMixColumn Transformation

Opcode/Instruction	                                Op/En	64/32-bit Mode	CPUID Feature Flag	    Description
66 0F 38 DB /r AESIMC xmm1, xmm2/m128	            RM	    V/V	            AES	                    Perform the InvMixColumn transformation on a 128-bit round key from xmm2/m128 and store the result in xmm1.
VEX.128.66.0F38.WIG DB /r VAESIMC xmm1, xmm2/m128	RM	    V/V	            Both AES and AVX flags	Perform the InvMixColumn transformation on a 128-bit round key from xmm2/m128 and store the result in xmm1.

Instruction Operand Encoding:

Op/En	Operand 1	    Operand 2	    Operand 3	Operand 4
RM	    ModRM:reg (w)	ModRM:r/m (r)	N/A	        N/A

Description:

Perform the InvMixColumns transformation on the source operand and store the result in the destination operand. The destination operand is an XMM register. The source operand can be an XMM register or a 128-bit memory location.

Note: the AESIMC instruction should be applied to the expanded AES round keys (except for the first and last round key) in order to prepare them for decryption using the “Equivalent Inverse Cipher” (defined in FIPS 197).

128-bit Legacy SSE version: Bits (MAXVL-1:128) of the corresponding YMM destination register remain unchanged.

VEX.128 encoded version: Bits (MAXVL-1:128) of the destination YMM register are zeroed.

Note: In VEX-encoded versions, VEX.vvvv is reserved and must be 1111b, otherwise instructions will #UD.

Operation:

AESIMC:

DEST[127:0] := InvMixColumns( SRC );
DEST[MAXVL-1:128] (Unmodified)

VAESIMC:

DEST[127:0] := InvMixColumns( SRC );
DEST[MAXVL-1:128] := 0;

Intel C/C++ Compiler Intrinsic Equivalent:

(V)AESIMC __m128i _mm_aesimc (__m128i)

SIMD Floating-Point Exceptions:

None.

Other Exceptions:

See Table 2-21, “Type 4 Class Exception Conditions,” additionally:

#UD:
    If VEX.vvvv ≠ 1111B.







AESKEYGENASSIST — AES Round Key Generation Assist

Opcode/Instruction	                                                    Op/En	64/32-bit Mode	CPUID Feature Flag	    Description
66 0F 3A DF /r ib AESKEYGENASSIST xmm1, xmm2/m128, imm8	                RMI	    V/V	            AES	                    Assist in AES round key generation using an 8 bits Round Constant (RCON) specified in the immediate byte, operating on 128 bits of data specified in xmm2/m128 and stores the result in xmm1.
VEX.128.66.0F3A.WIG DF /r ib VAESKEYGENASSIST xmm1, xmm2/m128, imm8	    RMI	    V/V	            Both AES and AVX flags	Assist in AES round key generation using 8 bits Round Constant (RCON) specified in the immediate byte, operating on 128 bits of data specified in xmm2/m128 and stores the result in xmm1.

Instruction Operand Encoding:

Op/En	Operand 1	    Operand 2	    Operand 3	Operand 4
RMI	    ModRM:reg (w)	ModRM:r/m (r)	imm8	    N/A

Description:

Assist in expanding the AES cipher key, by computing steps towards generating a round key for encryption, using 128-bit data specified in the source operand and an 8-bit round constant specified as an immediate, store the result in the destination operand.

The destination operand is an XMM register. The source operand can be an XMM register or a 128-bit memory location.

128-bit Legacy SSE version: Bits (MAXVL-1:128) of the corresponding YMM destination register remain unchanged.

VEX.128 encoded version: Bits (MAXVL-1:128) of the destination YMM register are zeroed.

Note: In VEX-encoded versions, VEX.vvvv is reserved and must be 1111b, otherwise instructions will #UD.

Operation:

AESKEYGENASSIST:

X3[31:0] := SRC [127: 96];
X2[31:0] := SRC [95: 64];
X1[31:0] := SRC [63: 32];
X0[31:0] := SRC [31: 0];
RCON[31:0] := ZeroExtend(imm8[7:0]);
DEST[31:0] := SubWord(X1);
DEST[63:32 ] := RotWord( SubWord(X1) ) XOR RCON;
DEST[95:64] := SubWord(X3);
DEST[127:96] := RotWord( SubWord(X3) ) XOR RCON;
DEST[MAXVL-1:128] (Unmodified)

VAESKEYGENASSIST:

X3[31:0] := SRC [127: 96];
X2[31:0] := SRC [95: 64];
X1[31:0] := SRC [63: 32];
X0[31:0] := SRC [31: 0];
RCON[31:0] := ZeroExtend(imm8[7:0]);
DEST[31:0] := SubWord(X1);
DEST[63:32 ] := RotWord( SubWord(X1) ) XOR RCON;
DEST[95:64] := SubWord(X3);
DEST[127:96] := RotWord( SubWord(X3) ) XOR RCON;
DEST[MAXVL-1:128] := 0;

Intel C/C++ Compiler Intrinsic Equivalent:

(V)AESKEYGENASSIST __m128i _mm_aeskeygenassist (__m128i, const int)

SIMD Floating-Point Exceptions:

None.

Other Exceptions:

See Table 2-21, “Type 4 Class Exception Conditions,” additionally:

#UD:
If VEX.vvvv ≠ 1111B.
