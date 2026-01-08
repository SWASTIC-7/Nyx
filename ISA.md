# x86 Instruction Set Architecture Reference

A comprehensive reference for x86 assembly instructions, organized by category. Useful for bootloader and OS development.

---

## Table of Contents
1. [Data Movement Instructions](#1-data-movement-instructions)
2. [Arithmetic Instructions](#2-arithmetic-instructions)
3. [Logical Instructions](#3-logical-instructions)
4. [Shift and Rotate Instructions](#4-shift-and-rotate-instructions)
5. [Control Flow Instructions](#5-control-flow-instructions)
6. [Comparison and Test Instructions](#6-comparison-and-test-instructions)
7. [String Instructions](#7-string-instructions)
8. [I/O Instructions](#8-io-instructions)
9. [Flag Manipulation Instructions](#9-flag-manipulation-instructions)
10. [Stack Instructions](#10-stack-instructions)
11. [Segment and Address Instructions](#11-segment-and-address-instructions)
12. [System Instructions](#12-system-instructions)
13. [Miscellaneous Instructions](#13-miscellaneous-instructions)
14. [x86 Registers](#14-x86-registers)
15. [FLAGS Register Bits](#15-flags-register-bits)
16. [Common BIOS Interrupts](#16-common-bios-interrupts)

---

## 1. Data Movement Instructions

| Instruction | Syntax | Description | Flags Affected |
|-------------|--------|-------------|----------------|
| `MOV` | `MOV dest, src` | Copy data from source to destination | None |
| `MOVZX` | `MOVZX dest, src` | Move with zero-extension (unsigned) | None |
| `MOVSX` | `MOVSX dest, src` | Move with sign-extension (signed) | None |
| `XCHG` | `XCHG op1, op2` | Exchange values between operands | None |
| `LEA` | `LEA dest, src` | Load effective address into register | None |
| `LDS` | `LDS reg, mem` | Load pointer into DS:reg | None |
| `LES` | `LES reg, mem` | Load pointer into ES:reg | None |
| `LFS` | `LFS reg, mem` | Load pointer into FS:reg (386+) | None |
| `LGS` | `LGS reg, mem` | Load pointer into GS:reg (386+) | None |
| `LSS` | `LSS reg, mem` | Load pointer into SS:reg (386+) | None |
| `LAHF` | `LAHF` | Load AH from lower byte of FLAGS | None |
| `SAHF` | `SAHF` | Store AH into lower byte of FLAGS | SF, ZF, AF, PF, CF |
| `XLAT` | `XLAT` / `XLATB` | Table lookup translation (AL = [BX+AL]) | None |
| `BSWAP` | `BSWAP reg32` | Byte swap (reverse byte order) (486+) | None |
| `CMOVcc` | `CMOVcc dest, src` | Conditional move (Pentium Pro+) | None |

### Conditional Move Instructions (CMOVcc)

| Instruction | Condition | Description |
|-------------|-----------|-------------|
| `CMOVA` | CF=0 and ZF=0 | Move if above (unsigned) |
| `CMOVAE` | CF=0 | Move if above or equal |
| `CMOVB` | CF=1 | Move if below (unsigned) |
| `CMOVBE` | CF=1 or ZF=1 | Move if below or equal |
| `CMOVC` | CF=1 | Move if carry |
| `CMOVE` | ZF=1 | Move if equal |
| `CMOVG` | ZF=0 and SF=OF | Move if greater (signed) |
| `CMOVGE` | SF=OF | Move if greater or equal |
| `CMOVL` | SF≠OF | Move if less (signed) |
| `CMOVLE` | ZF=1 or SF≠OF | Move if less or equal |
| `CMOVNA` | CF=1 or ZF=1 | Move if not above |
| `CMOVNAE` | CF=1 | Move if not above or equal |
| `CMOVNB` | CF=0 | Move if not below |
| `CMOVNBE` | CF=0 and ZF=0 | Move if not below or equal |
| `CMOVNC` | CF=0 | Move if not carry |
| `CMOVNE` | ZF=0 | Move if not equal |
| `CMOVNG` | ZF=1 or SF≠OF | Move if not greater |
| `CMOVNGE` | SF≠OF | Move if not greater or equal |
| `CMOVNL` | SF=OF | Move if not less |
| `CMOVNLE` | ZF=0 and SF=OF | Move if not less or equal |
| `CMOVNO` | OF=0 | Move if not overflow |
| `CMOVNP` | PF=0 | Move if not parity |
| `CMOVNS` | SF=0 | Move if not sign |
| `CMOVNZ` | ZF=0 | Move if not zero |
| `CMOVO` | OF=1 | Move if overflow |
| `CMOVP` | PF=1 | Move if parity |
| `CMOVPE` | PF=1 | Move if parity even |
| `CMOVPO` | PF=0 | Move if parity odd |
| `CMOVS` | SF=1 | Move if sign |
| `CMOVZ` | ZF=1 | Move if zero |

---

## 2. Arithmetic Instructions

| Instruction | Syntax | Description | Flags Affected |
|-------------|--------|-------------|----------------|
| `ADD` | `ADD dest, src` | Add source to destination | OF, SF, ZF, AF, PF, CF |
| `ADC` | `ADC dest, src` | Add with carry | OF, SF, ZF, AF, PF, CF |
| `SUB` | `SUB dest, src` | Subtract source from destination | OF, SF, ZF, AF, PF, CF |
| `SBB` | `SBB dest, src` | Subtract with borrow | OF, SF, ZF, AF, PF, CF |
| `INC` | `INC dest` | Increment by 1 | OF, SF, ZF, AF, PF |
| `DEC` | `DEC dest` | Decrement by 1 | OF, SF, ZF, AF, PF |
| `NEG` | `NEG dest` | Two's complement negation | OF, SF, ZF, AF, PF, CF |
| `MUL` | `MUL src` | Unsigned multiply (AX = AL * src8, DX:AX = AX * src16) | OF, CF (SF, ZF, AF, PF undefined) |
| `IMUL` | `IMUL src` | Signed multiply | OF, CF (SF, ZF, AF, PF undefined) |
| `IMUL` | `IMUL dest, src` | Signed multiply (2 operand) | OF, CF |
| `IMUL` | `IMUL dest, src, imm` | Signed multiply (3 operand) | OF, CF |
| `DIV` | `DIV src` | Unsigned divide (AX/src8 → AL rem AH) | Undefined |
| `IDIV` | `IDIV src` | Signed divide | Undefined |
| `CBW` | `CBW` | Convert byte to word (sign-extend AL → AX) | None |
| `CWD` | `CWD` | Convert word to doubleword (sign-extend AX → DX:AX) | None |
| `CWDE` | `CWDE` | Convert word to doubleword (sign-extend AX → EAX) | None |
| `CDQ` | `CDQ` | Convert doubleword to quadword (sign-extend EAX → EDX:EAX) | None |
| `AAA` | `AAA` | ASCII adjust after addition | AF, CF (others undefined) |
| `AAS` | `AAS` | ASCII adjust after subtraction | AF, CF (others undefined) |
| `AAM` | `AAM` | ASCII adjust after multiplication | SF, ZF, PF (others undefined) |
| `AAD` | `AAD` | ASCII adjust before division | SF, ZF, PF (others undefined) |
| `DAA` | `DAA` | Decimal adjust after addition | SF, ZF, AF, PF, CF (OF undefined) |
| `DAS` | `DAS` | Decimal adjust after subtraction | SF, ZF, AF, PF, CF (OF undefined) |

---

## 3. Logical Instructions

| Instruction | Syntax | Description | Flags Affected |
|-------------|--------|-------------|----------------|
| `AND` | `AND dest, src` | Bitwise AND | OF=0, CF=0, SF, ZF, PF (AF undefined) |
| `OR` | `OR dest, src` | Bitwise OR | OF=0, CF=0, SF, ZF, PF (AF undefined) |
| `XOR` | `XOR dest, src` | Bitwise exclusive OR | OF=0, CF=0, SF, ZF, PF (AF undefined) |
| `NOT` | `NOT dest` | Bitwise NOT (one's complement) | None |
| `TEST` | `TEST op1, op2` | Bitwise AND (result discarded, flags set) | OF=0, CF=0, SF, ZF, PF (AF undefined) |

---

## 4. Shift and Rotate Instructions

| Instruction | Syntax | Description | Flags Affected |
|-------------|--------|-------------|----------------|
| `SHL` / `SAL` | `SHL dest, count` | Shift left (multiply by 2^count) | OF, SF, ZF, PF, CF (AF undefined) |
| `SHR` | `SHR dest, count` | Shift right logical (unsigned divide) | OF, SF, ZF, PF, CF (AF undefined) |
| `SAR` | `SAR dest, count` | Shift right arithmetic (signed divide) | OF, SF, ZF, PF, CF (AF undefined) |
| `ROL` | `ROL dest, count` | Rotate left | OF, CF |
| `ROR` | `ROR dest, count` | Rotate right | OF, CF |
| `RCL` | `RCL dest, count` | Rotate left through carry | OF, CF |
| `RCR` | `RCR dest, count` | Rotate right through carry | OF, CF |
| `SHLD` | `SHLD dest, src, count` | Double precision shift left (386+) | OF, SF, ZF, PF, CF (AF undefined) |
| `SHRD` | `SHRD dest, src, count` | Double precision shift right (386+) | OF, SF, ZF, PF, CF (AF undefined) |

---

## 5. Control Flow Instructions

### Unconditional Jumps and Calls

| Instruction | Syntax | Description | Flags Affected |
|-------------|--------|-------------|----------------|
| `JMP` | `JMP target` | Unconditional jump | None |
| `JMP` | `JMP FAR seg:offset` | Far jump (change CS:IP) | None |
| `CALL` | `CALL target` | Call procedure (push return address) | None |
| `CALL` | `CALL FAR seg:offset` | Far call (push CS:IP) | None |
| `RET` | `RET` / `RET imm16` | Return from near procedure | None |
| `RETF` | `RETF` / `RETF imm16` | Return from far procedure | None |
| `IRET` | `IRET` | Return from interrupt | All (restored from stack) |
| `IRETD` | `IRETD` | Return from interrupt (32-bit) | All (restored from stack) |

### Conditional Jumps (Jcc)

| Instruction | Condition | Description |
|-------------|-----------|-------------|
| `JA` / `JNBE` | CF=0 and ZF=0 | Jump if above (unsigned) |
| `JAE` / `JNB` / `JNC` | CF=0 | Jump if above or equal |
| `JB` / `JNAE` / `JC` | CF=1 | Jump if below (unsigned) |
| `JBE` / `JNA` | CF=1 or ZF=1 | Jump if below or equal |
| `JE` / `JZ` | ZF=1 | Jump if equal / zero |
| `JNE` / `JNZ` | ZF=0 | Jump if not equal / not zero |
| `JG` / `JNLE` | ZF=0 and SF=OF | Jump if greater (signed) |
| `JGE` / `JNL` | SF=OF | Jump if greater or equal |
| `JL` / `JNGE` | SF≠OF | Jump if less (signed) |
| `JLE` / `JNG` | ZF=1 or SF≠OF | Jump if less or equal |
| `JO` | OF=1 | Jump if overflow |
| `JNO` | OF=0 | Jump if not overflow |
| `JP` / `JPE` | PF=1 | Jump if parity / parity even |
| `JNP` / `JPO` | PF=0 | Jump if not parity / parity odd |
| `JS` | SF=1 | Jump if sign (negative) |
| `JNS` | SF=0 | Jump if not sign (positive) |
| `JCXZ` | CX=0 | Jump if CX is zero |
| `JECXZ` | ECX=0 | Jump if ECX is zero (386+) |

### Loop Instructions

| Instruction | Syntax | Description | Flags Affected |
|-------------|--------|-------------|----------------|
| `LOOP` | `LOOP target` | Decrement CX/ECX, jump if not zero | None |
| `LOOPE` / `LOOPZ` | `LOOPE target` | Loop while equal (CX≠0 and ZF=1) | None |
| `LOOPNE` / `LOOPNZ` | `LOOPNE target` | Loop while not equal (CX≠0 and ZF=0) | None |

---

## 6. Comparison and Test Instructions

| Instruction | Syntax | Description | Flags Affected |
|-------------|--------|-------------|----------------|
| `CMP` | `CMP op1, op2` | Compare (subtract without storing) | OF, SF, ZF, AF, PF, CF |
| `TEST` | `TEST op1, op2` | Test bits (AND without storing) | OF=0, CF=0, SF, ZF, PF |
| `BT` | `BT base, offset` | Bit test | CF |
| `BTS` | `BTS base, offset` | Bit test and set | CF |
| `BTR` | `BTR base, offset` | Bit test and reset | CF |
| `BTC` | `BTC base, offset` | Bit test and complement | CF |
| `BSF` | `BSF dest, src` | Bit scan forward (find first 1) | ZF |
| `BSR` | `BSR dest, src` | Bit scan reverse (find last 1) | ZF |
| `SETcc` | `SETcc dest` | Set byte on condition | None |

### SETcc Instructions

| Instruction | Condition | Description |
|-------------|-----------|-------------|
| `SETA` | CF=0 and ZF=0 | Set if above |
| `SETAE` | CF=0 | Set if above or equal |
| `SETB` | CF=1 | Set if below |
| `SETBE` | CF=1 or ZF=1 | Set if below or equal |
| `SETC` | CF=1 | Set if carry |
| `SETE` / `SETZ` | ZF=1 | Set if equal / zero |
| `SETG` | ZF=0 and SF=OF | Set if greater |
| `SETGE` | SF=OF | Set if greater or equal |
| `SETL` | SF≠OF | Set if less |
| `SETLE` | ZF=1 or SF≠OF | Set if less or equal |
| `SETNA` | CF=1 or ZF=1 | Set if not above |
| `SETNAE` | CF=1 | Set if not above or equal |
| `SETNB` | CF=0 | Set if not below |
| `SETNBE` | CF=0 and ZF=0 | Set if not below or equal |
| `SETNC` | CF=0 | Set if not carry |
| `SETNE` / `SETNZ` | ZF=0 | Set if not equal / not zero |
| `SETNG` | ZF=1 or SF≠OF | Set if not greater |
| `SETNGE` | SF≠OF | Set if not greater or equal |
| `SETNL` | SF=OF | Set if not less |
| `SETNLE` | ZF=0 and SF=OF | Set if not less or equal |
| `SETNO` | OF=0 | Set if not overflow |
| `SETNP` | PF=0 | Set if not parity |
| `SETNS` | SF=0 | Set if not sign |
| `SETO` | OF=1 | Set if overflow |
| `SETP` | PF=1 | Set if parity |
| `SETPE` | PF=1 | Set if parity even |
| `SETPO` | PF=0 | Set if parity odd |
| `SETS` | SF=1 | Set if sign |

---

## 7. String Instructions

All string instructions use implicit operands based on DS:SI (source) and ES:DI (destination).

| Instruction | Syntax | Description | Flags Affected |
|-------------|--------|-------------|----------------|
| `MOVSB` | `MOVSB` | Move byte [DS:SI] → [ES:DI] | None |
| `MOVSW` | `MOVSW` | Move word [DS:SI] → [ES:DI] | None |
| `MOVSD` | `MOVSD` | Move doubleword [DS:SI] → [ES:DI] | None |
| `LODSB` | `LODSB` | Load byte [DS:SI] → AL | None |
| `LODSW` | `LODSW` | Load word [DS:SI] → AX | None |
| `LODSD` | `LODSD` | Load doubleword [DS:SI] → EAX | None |
| `STOSB` | `STOSB` | Store byte AL → [ES:DI] | None |
| `STOSW` | `STOSW` | Store word AX → [ES:DI] | None |
| `STOSD` | `STOSD` | Store doubleword EAX → [ES:DI] | None |
| `CMPSB` | `CMPSB` | Compare bytes [DS:SI] vs [ES:DI] | OF, SF, ZF, AF, PF, CF |
| `CMPSW` | `CMPSW` | Compare words | OF, SF, ZF, AF, PF, CF |
| `CMPSD` | `CMPSD` | Compare doublewords | OF, SF, ZF, AF, PF, CF |
| `SCASB` | `SCASB` | Scan byte AL vs [ES:DI] | OF, SF, ZF, AF, PF, CF |
| `SCASW` | `SCASW` | Scan word AX vs [ES:DI] | OF, SF, ZF, AF, PF, CF |
| `SCASD` | `SCASD` | Scan doubleword EAX vs [ES:DI] | OF, SF, ZF, AF, PF, CF |
| `INSB` | `INSB` | Input byte from port DX → [ES:DI] | None |
| `INSW` | `INSW` | Input word from port DX → [ES:DI] | None |
| `INSD` | `INSD` | Input doubleword from port DX → [ES:DI] | None |
| `OUTSB` | `OUTSB` | Output byte [DS:SI] → port DX | None |
| `OUTSW` | `OUTSW` | Output word [DS:SI] → port DX | None |
| `OUTSD` | `OUTSD` | Output doubleword [DS:SI] → port DX | None |

### Repeat Prefixes

| Prefix | Usage | Description |
|--------|-------|-------------|
| `REP` | `REP MOVSB` | Repeat while CX≠0 (used with MOVS, STOS, LODS, INS, OUTS) |
| `REPE` / `REPZ` | `REPE CMPSB` | Repeat while equal/zero (CX≠0 and ZF=1) |
| `REPNE` / `REPNZ` | `REPNE SCASB` | Repeat while not equal/not zero (CX≠0 and ZF=0) |

### Direction Flag

| Instruction | Description |
|-------------|-------------|
| `CLD` | Clear direction flag (SI/DI increment) |
| `STD` | Set direction flag (SI/DI decrement) |

---

## 8. I/O Instructions

| Instruction | Syntax | Description | Flags Affected |
|-------------|--------|-------------|----------------|
| `IN` | `IN AL, imm8` | Input byte from port (immediate) | None |
| `IN` | `IN AX, imm8` | Input word from port (immediate) | None |
| `IN` | `IN EAX, imm8` | Input doubleword from port (immediate) | None |
| `IN` | `IN AL, DX` | Input byte from port (DX) | None |
| `IN` | `IN AX, DX` | Input word from port (DX) | None |
| `IN` | `IN EAX, DX` | Input doubleword from port (DX) | None |
| `OUT` | `OUT imm8, AL` | Output byte to port (immediate) | None |
| `OUT` | `OUT imm8, AX` | Output word to port (immediate) | None |
| `OUT` | `OUT imm8, EAX` | Output doubleword to port (immediate) | None |
| `OUT` | `OUT DX, AL` | Output byte to port (DX) | None |
| `OUT` | `OUT DX, AX` | Output word to port (DX) | None |
| `OUT` | `OUT DX, EAX` | Output doubleword to port (DX) | None |

---

## 9. Flag Manipulation Instructions

| Instruction | Syntax | Description | Flags Affected |
|-------------|--------|-------------|----------------|
| `CLC` | `CLC` | Clear carry flag | CF=0 |
| `STC` | `STC` | Set carry flag | CF=1 |
| `CMC` | `CMC` | Complement carry flag | CF=!CF |
| `CLD` | `CLD` | Clear direction flag | DF=0 |
| `STD` | `STD` | Set direction flag | DF=1 |
| `CLI` | `CLI` | Clear interrupt flag (disable interrupts) | IF=0 |
| `STI` | `STI` | Set interrupt flag (enable interrupts) | IF=1 |
| `LAHF` | `LAHF` | Load AH from FLAGS (SF, ZF, AF, PF, CF) | None |
| `SAHF` | `SAHF` | Store AH into FLAGS | SF, ZF, AF, PF, CF |
| `PUSHF` | `PUSHF` | Push FLAGS onto stack | None |
| `PUSHFD` | `PUSHFD` | Push EFLAGS onto stack (32-bit) | None |
| `POPF` | `POPF` | Pop FLAGS from stack | All |
| `POPFD` | `POPFD` | Pop EFLAGS from stack (32-bit) | All |

---

## 10. Stack Instructions

| Instruction | Syntax | Description | Flags Affected |
|-------------|--------|-------------|----------------|
| `PUSH` | `PUSH src` | Push value onto stack | None |
| `POP` | `POP dest` | Pop value from stack | None |
| `PUSHA` | `PUSHA` | Push all general registers (16-bit) | None |
| `PUSHAD` | `PUSHAD` | Push all general registers (32-bit) | None |
| `POPA` | `POPA` | Pop all general registers (16-bit) | None |
| `POPAD` | `POPAD` | Pop all general registers (32-bit) | None |
| `ENTER` | `ENTER imm16, imm8` | Create stack frame | None |
| `LEAVE` | `LEAVE` | Destroy stack frame (MOV SP,BP; POP BP) | None |

---

## 11. Segment and Address Instructions

| Instruction | Syntax | Description | Flags Affected |
|-------------|--------|-------------|----------------|
| `LEA` | `LEA reg, mem` | Load effective address | None |
| `LDS` | `LDS reg, mem` | Load far pointer into DS:reg | None |
| `LES` | `LES reg, mem` | Load far pointer into ES:reg | None |
| `LFS` | `LFS reg, mem` | Load far pointer into FS:reg | None |
| `LGS` | `LGS reg, mem` | Load far pointer into GS:reg | None |
| `LSS` | `LSS reg, mem` | Load far pointer into SS:reg | None |

### Segment Override Prefixes

| Prefix | Description |
|--------|-------------|
| `CS:` | Use CS segment |
| `DS:` | Use DS segment |
| `ES:` | Use ES segment |
| `FS:` | Use FS segment |
| `GS:` | Use GS segment |
| `SS:` | Use SS segment |

---

## 12. System Instructions

### Descriptor Table Instructions

| Instruction | Syntax | Description | Flags Affected |
|-------------|--------|-------------|----------------|
| `LGDT` | `LGDT mem48` | Load Global Descriptor Table Register | None |
| `SGDT` | `SGDT mem48` | Store GDTR | None |
| `LIDT` | `LIDT mem48` | Load Interrupt Descriptor Table Register | None |
| `SIDT` | `SIDT mem48` | Store IDTR | None |
| `LLDT` | `LLDT reg/mem16` | Load Local Descriptor Table Register | None |
| `SLDT` | `SLDT reg/mem16` | Store LDTR | None |
| `LTR` | `LTR reg/mem16` | Load Task Register | None |
| `STR` | `STR reg/mem16` | Store Task Register | None |

### Control Register Instructions

| Instruction | Syntax | Description | Flags Affected |
|-------------|--------|-------------|----------------|
| `MOV` | `MOV CRn, reg` | Move to control register | None |
| `MOV` | `MOV reg, CRn` | Move from control register | None |
| `MOV` | `MOV DRn, reg` | Move to debug register | None |
| `MOV` | `MOV reg, DRn` | Move from debug register | None |
| `LMSW` | `LMSW reg/mem16` | Load machine status word (CR0 low 16 bits) | None |
| `SMSW` | `SMSW reg/mem16` | Store machine status word | None |
| `CLTS` | `CLTS` | Clear task-switched flag in CR0 | None |

### Cache and TLB Instructions

| Instruction | Syntax | Description | Flags Affected |
|-------------|--------|-------------|----------------|
| `INVD` | `INVD` | Invalidate cache (no writeback) | None |
| `WBINVD` | `WBINVD` | Write back and invalidate cache | None |
| `INVLPG` | `INVLPG mem` | Invalidate TLB entry | None |

### Miscellaneous System Instructions

| Instruction | Syntax | Description | Flags Affected |
|-------------|--------|-------------|----------------|
| `HLT` | `HLT` | Halt processor until interrupt | None |
| `NOP` | `NOP` | No operation | None |
| `LOCK` | `LOCK` | Lock prefix for atomic operations | None |
| `WAIT` / `FWAIT` | `WAIT` | Wait for FPU | None |
| `INT` | `INT imm8` | Software interrupt | IF, TF cleared |
| `INT3` | `INT3` | Breakpoint interrupt (debug) | IF, TF cleared |
| `INTO` | `INTO` | Interrupt on overflow (if OF=1) | IF, TF cleared |
| `BOUND` | `BOUND reg, mem` | Check array bounds | None (or #BR exception) |
| `CPUID` | `CPUID` | CPU identification | EAX, EBX, ECX, EDX |
| `RDTSC` | `RDTSC` | Read time-stamp counter → EDX:EAX | None |
| `RDMSR` | `RDMSR` | Read model-specific register → EDX:EAX | None |
| `WRMSR` | `WRMSR` | Write EDX:EAX to MSR | None |
| `SYSENTER` | `SYSENTER` | Fast system call entry | None |
| `SYSEXIT` | `SYSEXIT` | Fast system call exit | None |

---

## 13. Miscellaneous Instructions

| Instruction | Syntax | Description | Flags Affected |
|-------------|--------|-------------|----------------|
| `NOP` | `NOP` | No operation | None |
| `XCHG` | `XCHG EAX, EAX` | Encoded as NOP | None |
| `UD2` | `UD2` | Undefined instruction (causes #UD exception) | None |
| `PAUSE` | `PAUSE` | Spin-loop hint (improves spinlock performance) | None |
| `PREFETCH` | `PREFETCHx mem` | Prefetch data into cache | None |
| `LFENCE` | `LFENCE` | Load fence (serialize loads) | None |
| `SFENCE` | `SFENCE` | Store fence (serialize stores) | None |
| `MFENCE` | `MFENCE` | Memory fence (serialize all memory ops) | None |
| `CRC32` | `CRC32 dest, src` | Compute CRC-32C | None |
| `POPCNT` | `POPCNT dest, src` | Count set bits | ZF |
| `LZCNT` | `LZCNT dest, src` | Count leading zeros | CF, ZF |
| `TZCNT` | `TZCNT dest, src` | Count trailing zeros | CF, ZF |

---

## 14. x86 Registers

### General Purpose Registers

| 64-bit | 32-bit | 16-bit | 8-bit High | 8-bit Low | Purpose |
|--------|--------|--------|------------|-----------|---------|
| RAX | EAX | AX | AH | AL | Accumulator |
| RBX | EBX | BX | BH | BL | Base register |
| RCX | ECX | CX | CH | CL | Counter |
| RDX | EDX | DX | DH | DL | Data register |
| RSI | ESI | SI | - | SIL | Source index |
| RDI | EDI | DI | - | DIL | Destination index |
| RBP | EBP | BP | - | BPL | Base pointer |
| RSP | ESP | SP | - | SPL | Stack pointer |
| R8-R15 | R8D-R15D | R8W-R15W | - | R8B-R15B | Extended (64-bit only) |

### Segment Registers

| Register | Description |
|----------|-------------|
| CS | Code Segment |
| DS | Data Segment |
| ES | Extra Segment |
| FS | Additional Segment (386+) |
| GS | Additional Segment (386+) |
| SS | Stack Segment |

### Special Registers

| Register | Description |
|----------|-------------|
| IP / EIP / RIP | Instruction Pointer |
| FLAGS / EFLAGS / RFLAGS | Flags Register |
| CR0-CR4 | Control Registers |
| DR0-DR7 | Debug Registers |
| GDTR | Global Descriptor Table Register |
| IDTR | Interrupt Descriptor Table Register |
| LDTR | Local Descriptor Table Register |
| TR | Task Register |

---

## 15. FLAGS Register Bits

| Bit | Flag | Name | Description |
|-----|------|------|-------------|
| 0 | CF | Carry Flag | Set on unsigned overflow |
| 1 | - | Reserved | Always 1 |
| 2 | PF | Parity Flag | Set if low byte has even parity |
| 3 | - | Reserved | |
| 4 | AF | Auxiliary Flag | BCD carry from bit 3 to 4 |
| 5 | - | Reserved | |
| 6 | ZF | Zero Flag | Set if result is zero |
| 7 | SF | Sign Flag | Set if result is negative (MSB=1) |
| 8 | TF | Trap Flag | Single-step mode for debugging |
| 9 | IF | Interrupt Flag | Enable/disable hardware interrupts |
| 10 | DF | Direction Flag | String operation direction |
| 11 | OF | Overflow Flag | Set on signed overflow |
| 12-13 | IOPL | I/O Privilege Level | (Protected mode) |
| 14 | NT | Nested Task | (Protected mode) |
| 15 | - | Reserved | |
| 16 | RF | Resume Flag | (386+) Debug exception control |
| 17 | VM | Virtual 8086 Mode | (386+) |
| 18 | AC | Alignment Check | (486+) |
| 19 | VIF | Virtual Interrupt Flag | (Pentium+) |
| 20 | VIP | Virtual Interrupt Pending | (Pentium+) |
| 21 | ID | ID Flag | CPUID available if can toggle |

---

## 16. Common BIOS Interrupts

### INT 0x10 — Video Services

| AH | Function | Description |
|----|----------|-------------|
| 0x00 | Set video mode | AL = mode number |
| 0x01 | Set cursor shape | CH/CL = start/end scanline |
| 0x02 | Set cursor position | DH/DL = row/column, BH = page |
| 0x03 | Get cursor position | BH = page → DH/DL = row/col |
| 0x05 | Set active page | AL = page number |
| 0x06 | Scroll up | AL = lines, BH = attribute |
| 0x07 | Scroll down | AL = lines, BH = attribute |
| 0x08 | Read char/attr | BH = page → AL = char, AH = attr |
| 0x09 | Write char/attr | AL = char, BL = attr, CX = count |
| 0x0A | Write character | AL = char, CX = count |
| 0x0E | Teletype output | AL = char (TTY mode) |
| 0x0F | Get video mode | → AL = mode, AH = columns, BH = page |
| 0x13 | Write string | ES:BP = string, CX = length |

### INT 0x13 — Disk Services

| AH | Function | Description |
|----|----------|-------------|
| 0x00 | Reset disk | DL = drive |
| 0x01 | Get status | → AL = last status |
| 0x02 | Read sectors | AL = count, CH = cyl, CL = sector, DH = head, DL = drive, ES:BX = buffer |
| 0x03 | Write sectors | Same as above |
| 0x08 | Get drive params | DL = drive → CX, DX = geometry |
| 0x15 | Get disk type | DL = drive → AH = type |
| 0x41 | Check extensions | BX = 0x55AA, DL = drive |
| 0x42 | Extended read | DL = drive, DS:SI = DAP |
| 0x43 | Extended write | DL = drive, DS:SI = DAP |

### INT 0x15 — System Services

| AX | Function | Description |
|----|----------|-------------|
| 0x2401 | Enable A20 | Enable A20 gate via BIOS |
| 0x2402 | Get A20 status | → AL = status |
| 0x2403 | Query A20 support | → BX = support bitmap |
| 0xE820 | Get memory map | EBX = continuation, ES:DI = buffer, ECX = size |
| 0xE801 | Get extended memory | → AX/BX or CX/DX = memory size |
| 0x88 | Get extended memory (old) | → AX = KB above 1MB |

### INT 0x16 — Keyboard Services

| AH | Function | Description |
|----|----------|-------------|
| 0x00 | Wait for keypress | → AH = scan code, AL = ASCII |
| 0x01 | Check for keypress | ZF=1 if none, else AH/AL = key |
| 0x02 | Get shift flags | → AL = shift flags |
| 0x10 | Extended wait | (enhanced keyboards) |
| 0x11 | Extended check | (enhanced keyboards) |
| 0x12 | Extended shift flags | → AX = extended flags |

---

## Control Registers (CR0-CR4)

### CR0 Bits

| Bit | Name | Description |
|-----|------|-------------|
| 0 | PE | Protection Enable (1 = protected mode) |
| 1 | MP | Monitor Coprocessor |
| 2 | EM | Emulation (1 = no FPU) |
| 3 | TS | Task Switched |
| 4 | ET | Extension Type (1 = 387) |
| 5 | NE | Numeric Error |
| 16 | WP | Write Protect |
| 18 | AM | Alignment Mask |
| 29 | NW | Not Write-through |
| 30 | CD | Cache Disable |
| 31 | PG | Paging Enable |

### CR3 (PDBR)

| Bits | Description |
|------|-------------|
| 12-31 | Page Directory Base (physical address, 4KB aligned) |
| 3 | PWT (Page-level Write-Through) |
| 4 | PCD (Page-level Cache Disable) |

### CR4 Bits

| Bit | Name | Description |
|-----|------|-------------|
| 0 | VME | Virtual-8086 Mode Extensions |
| 1 | PVI | Protected-mode Virtual Interrupts |
| 2 | TSD | Time Stamp Disable |
| 3 | DE | Debugging Extensions |
| 4 | PSE | Page Size Extension (4MB pages) |
| 5 | PAE | Physical Address Extension |
| 6 | MCE | Machine Check Exception |
| 7 | PGE | Page Global Enable |
| 8 | PCE | Performance Counter Enable |
| 9 | OSFXSR | OS FXSAVE/FXRSTOR Support |
| 10 | OSXMMEXCPT | OS Unmasked SIMD FP Exceptions |

---

## GDT Entry Format (8 bytes)

```
Byte 0-1: Limit (bits 0-15)
Byte 2-3: Base (bits 0-15)
Byte 4:   Base (bits 16-23)
Byte 5:   Access byte
Byte 6:   Flags (4 bits) + Limit (bits 16-19)
Byte 7:   Base (bits 24-31)
```

### Access Byte (Byte 5)

| Bit | Name | Description |
|-----|------|-------------|
| 0 | A | Accessed |
| 1 | RW | Readable (code) / Writable (data) |
| 2 | DC | Direction (data) / Conforming (code) |
| 3 | E | Executable (1 = code, 0 = data) |
| 4 | S | Descriptor type (1 = code/data, 0 = system) |
| 5-6 | DPL | Descriptor Privilege Level (0-3) |
| 7 | P | Present |

### Flags (Upper 4 bits of Byte 6)

| Bit | Name | Description |
|-----|------|-------------|
| 0 | - | Reserved |
| 1 | L | Long mode (64-bit) |
| 2 | DB | Size (0 = 16-bit, 1 = 32-bit) |
| 3 | G | Granularity (0 = byte, 1 = 4KB) |

---

## Quick Reference: Mode Transitions

### Real Mode → Protected Mode

```asm
cli                     ; Disable interrupts
lgdt [gdt_descriptor]   ; Load GDT
mov eax, cr0
or eax, 1               ; Set PE bit
mov cr0, eax
jmp CODE_SEG:protected_mode  ; Far jump to flush pipeline

[BITS 32]
protected_mode:
    mov ax, DATA_SEG
    mov ds, ax
    mov es, ax
    mov fs, ax
    mov gs, ax
    mov ss, ax
    ; Now in 32-bit protected mode
```

### Enable A20 (Keyboard Controller Method)

```asm
call wait_kbd
mov al, 0xAD        ; Disable keyboard
out 0x64, al
call wait_kbd
mov al, 0xD0        ; Read output port
out 0x64, al
call wait_kbd_data
in al, 0x60
push ax
call wait_kbd
mov al, 0xD1        ; Write output port
out 0x64, al
call wait_kbd
pop ax
or al, 2            ; Set A20 bit
out 0x60, al
call wait_kbd
mov al, 0xAE        ; Enable keyboard
out 0x64, al
call wait_kbd
```



---

*This reference is part of the Nyx bootloader project. See the main [Readme.md](Readme.md) for project overview and build instructions.*
