type regname = bits(3)
type regname16 = bits(2)

type dst = regname
type src = regname
type dst16 = regname16
type src16 = regname16

type rst_addr = bits(3)

type imm8 = bits(8)
type imm3 = bits(3)
type imm16 = bits(16)
type cond = bits(2)

mapping reg8_name : reg8_enum <-> regname = {
    B <-> 0b000,
    C <-> 0b001,
    D <-> 0b010,
    E <-> 0b011,
    H <-> 0b100,
    L <-> 0b101,
    A <-> 0b111
}

mapping reg16_name : reg16_enum <-> regname16 = {
    BC <-> 0b00,
    DE <-> 0b01,
    HL <-> 0b10,
    SP <-> 0b11
}

// todo: this should not use these raw bitvalues and we should map to some enum or mapping first
mapping reg8_str : regname <-> string = {
    0b000 <-> "B",
    0b001 <-> "C",
    0b010 <-> "D",
    0b011 <-> "E",
    0b100 <-> "H",
    0b101 <-> "L",
    0b110 <-> "(HL)",
    0b111 <-> "A"
}

mapping reg16_str : regname16 <-> string = {
    0b00 <-> "BC",
    0b01 <-> "DE",
    0b10 <-> "HL",
    0b11 <-> "SP"
}

mapping reg16_wAF_str : regname16 <-> string = {
    0b00 <-> "BC",
    0b01 <-> "DE",
    0b10 <-> "HL",
    0b11 <-> "AF"
}

mapping cond_str : cond <-> string = {
    0b01 <-> "z",
    0b00 <-> "nz",
    0b10 <-> "nc",
    0b11 <-> "c"
}

val read_reg8 : regname -> word
function read_reg8(r) = {
    // todo: try match reg8_name(r) and then match over the enum

    match r {
        0b000 => reg_BC.higher(),
        0b001 => reg_BC.lower(),
        0b010 => reg_DE.higher(),
        0b011 => reg_DE.lower(),
        0b100 => reg_HL.higher(),
        0b101 => reg_HL.lower(),
        0b110 => { 
            timing_tick_cycle();
            read(reg_HL.bits())
        },
        0b111 => reg_AF.higher()
    };
}

val write_reg8 : (regname, word) -> unit
function write_reg8(r, w) = {
    match r {
        0b000 => reg_BC->higher() = w,
        0b001 => reg_BC->lower() = w,
        0b010 => reg_DE->higher() = w,
        0b011 => reg_DE->lower() = w,
        0b100 => reg_HL->higher() = w,
        0b101 => reg_HL->lower() = w,
        0b110 => { 
            timing_tick_cycle();
            write(reg_HL.bits(), w)
        },
        0b111 => reg_AF->higher() = w
    };
}

val read_reg16 : regname16 -> dword
function read_reg16(r) = {
    match r {
        0b00 => reg_BC.bits(),
        0b01 => reg_DE.bits(),
        0b10 => reg_HL.bits(),
        0b11 => reg_SP
    };
}

val read_reg16_wAF : regname16 -> dword
function read_reg16_wAF(r) = {
    match r {
        0b00 => reg_BC.bits(),
        0b01 => reg_DE.bits(),
        0b10 => reg_HL.bits(),
        0b11 => reg_AF.bits()
    };
}

val write_reg16 : (regname16, dword) -> unit
function write_reg16(r, w) = {
    match r {
        0b00 => reg_BC->bits() = w,
        0b01 => reg_DE->bits() = w,
        0b10 => reg_HL->bits() = w,
        0b11 => reg_SP = w
    };
}
val write_reg16_wAF : (regname16, dword) -> unit
function write_reg16_wAF(r, w) = {
    match r {
        0b00 => reg_BC->bits() = w,
        0b01 => reg_DE->bits() = w,
        0b10 => reg_HL->bits() = w,
        0b11 => reg_AF->bits() = w & 0xFFF0 /* Bottom 4 bits of F are unwritable */
    };
}

val set_PC : (dword) -> unit
function set_PC(addr) = {
    PC = addr;
}

val condition_true : (cond) -> bool
function condition_true(c) = {
    match c {
        0b01 => reg_AF.z() == 0b1,
        0b00 => reg_AF.z() != 0b1,
        0b10 => reg_AF.c() != 0b1,
        0b11 => reg_AF.c() == 0b1
    }
} 

val set_flags : (bits(1), bits(1), bits(1), bits(1)) -> unit
function set_flags(z, n, h, c) = {
    reg_AF->z() = z;
    reg_AF->n() = n;
    reg_AF->h() = h;
    reg_AF->c() = c;
}

function flag_z() : (unit) -> bits(1) = reg_AF.z()
function flag_n() : (unit) -> bits(1) = reg_AF.n()
function flag_h() : (unit) -> bits(1) = reg_AF.h()
function flag_c() : (unit) -> bits(1) = reg_AF.c()

scattered union ast

union clause ast = INVALID : (bits(24))

union clause ast = JPCNN : (cond, imm16) /* Jump to absolute address PC=addr conditionally */
union clause ast = LDRR : (dst, src) /* r=r */
union clause ast = LDRN : (dst, imm8) /* r=n */
union clause ast = LDABC : (unit) /* A=(BC) */
union clause ast = LDADE : (unit) /* A=(DE) */
union clause ast = LDANN : (imm16) /* A=(nn) */
union clause ast = LDBCA : (unit) /* (BC)=A */
union clause ast = LDDEA : (unit) /* (DE)=A */
union clause ast = LDNNA : (imm16) /* (nn)=A */
union clause ast = LDIHLA : (unit) /* (HL)=A, HL=HL+1 */
union clause ast = LDIAHL : (unit) /* A=(HL), HL=HL+1 */
union clause ast = LDDHLA : (unit) /* (HL)=A, HL=HL-1 */
union clause ast = LDDAHL : (unit) /* A=(HL), HL=HL-1 */
union clause ast = LDRRNN : (dst16, imm16) /* rr=nn (rr may be BC,DE,HL or SP) */
union clause ast = LDNNSP : (imm16) /* (nn)=SP */
union clause ast = LDSPHL : (unit) /* SP=HL */
union clause ast = LDAFF00NN : (imm8) /* read from io-port n (memory FF00+n) */
union clause ast = LDFF00NNA : (imm8) /* write to io-port n (memory FF00+n) */
union clause ast = LDAFF00C : (unit) /* read from io-port C (memory FF00+C) */
union clause ast = LDFF00CA : (unit) /* write to io-port C (memory FF00+C) */
union clause ast = PUSHRR : (dst16) /* SP=SP-2  (SP)=rr ; rr may be BC,DE,HL,AF */
union clause ast = POPRR : (dst16) /* rr=(SP)  SP=SP+2 ; rr may be BC,DE,HL,AF */
union clause ast = ADDAR : (dst) /* A=A+r */
union clause ast = ADDAN : (imm8) /* A=A+n */
union clause ast = ADCAR : (dst) /* A=A+r+cy */
union clause ast = ADCAN : (imm8) /* A=A+n+cy */
union clause ast = SUBR : (dst) /* A=A-r */
union clause ast = SUBN : (imm8) /* A=A-n */
union clause ast = SBCAR : (dst) /* A=A-r-cy */
union clause ast = SBCAN : (imm8) /* A=A-n-cy */
union clause ast = ANDR : (dst) /* A=A & r */
union clause ast = ANDN : (imm8) /* A=A & n */
union clause ast = XORR : (dst) /* A=A xor r */
union clause ast = XORN : (imm8) /* A=A xor n */
union clause ast = ORR : (dst) /* A=A \ */
union clause ast = ORN : (imm8) /* A=A \ */
union clause ast = CPR : (dst) /* compare A-r */
union clause ast = CPN : (imm8) /* compare A-n */
union clause ast = INCR : (dst) /* r=r+1 */
union clause ast = DECR : (dst) /* r=r-1 */
union clause ast = DAA : (unit) /* decimal adjust A */
union clause ast = CPL : (unit) /* A = A xor FF */
union clause ast = ADDHLRR : (dst16) /* HL = HL+rr     ; rr may be BC,DE,HL,SP */
union clause ast = INCRR : (dst16) /* rr = rr+1      ; rr may be BC,DE,HL,SP */
union clause ast = DECRR : (dst16) /* rr = rr-1      ; rr may be BC,DE,HL,SP */
union clause ast = RLCA : (unit) /* rotate A left */
union clause ast = RLA : (unit) /* rotate A left through carry */
union clause ast = RRCA : (unit) /* rotate A right */
union clause ast = RRA : (unit) /* rotate A right through carry */
union clause ast = RLCR : (dst) /* rotate left */
union clause ast = RLR : (dst) /* rotate left through carry */
union clause ast = RRCR : (dst) /* rotate right */
union clause ast = RRR : (dst) /* rotate right through carry */
union clause ast = SLAR : (dst) /* shift left arithmetic (b0=0) */
union clause ast = SWAPR : (dst) /* exchange low/hi-nibble */
union clause ast = SRAR : (dst) /* shift right arithmetic (b7=b7) */
union clause ast = SRLR : (dst) /* shift right logical (b7=0) */
union clause ast = BITNR : (imm3, src) /* test bit n */
union clause ast = SETNR : (imm3, src) /* set bit n */
union clause ast = RESNR : (imm3, src) /* reset bit n */
union clause ast = CCF : (unit) /* cy=cy xor 1 */
union clause ast = SCF : (unit) /* cy=1 */
union clause ast = NOP : (unit) /* no operation */
union clause ast = HALT : (unit) /* halt until interrupt occurs (low power) */
union clause ast = STOP : (unit) /* low power standby mode (VERY low power) */
union clause ast = DI : (unit) /* disable interrupts, IME=0 */
union clause ast = EI : (unit) /* enable interrupts, IME=1 */
union clause ast = JPNN : (imm16) /* jump to nn, PC=nn */
union clause ast = JPHL : (unit) /* jump to HL, PC=HL */
union clause ast = JPFNN : (cond, imm16) /* conditional jump if nz,z,nc,c */
union clause ast = CALLNN : (imm16) /* call to nn, SP=SP-2, (SP)=PC, PC=nn */
union clause ast = CALLFNN : (cond, imm16) /* conditional call if nz,z,nc,c */
union clause ast = RET : (unit) /* return, PC=(SP), SP=SP+2 */
union clause ast = RETF : (cond) /* conditional return if nz,z,nc,c */
union clause ast = RETI : (unit) /* return and enable interrupts (IME=1) */
union clause ast = RSTN : (rst_addr) /* call to 00,08,10,18,20,28,30,38 */
union clause ast = JRNN : (imm8) /* relative jump to nn (PC=PC+8-bit signed) */
union clause ast = JRCN : (cond, imm8) /* conditional relative jump if nz,z,nc,c */
union clause ast = ADDSPD : (imm8) /* SP = SP +/- dd ; dd is 8-bit signed number */
union clause ast = LDHLSPDD : (imm8) /* HL = SP +/- dd ; dd is 8-bit signed number */


/**
 * Since this CPU has variable length instructions we need to parse 8 bit
 * instructions seperately from 16 or 24 bit instructions.
 */
type instruction8 = bits(8)
type instruction16 = bits(16)
type instruction24 = bits(24)

val decode : instruction8 -> option(ast)
val decode16 : instruction16 -> option(ast)
val decode24 : instruction24 -> option(ast)

/* 1 byte instructions */
scattered function decode

function clause decode (0b01 @ r1 : regname @ r2 : regname)
    = Some(LDRR(r1, r2))
function clause decode (0b00001010)
    = Some(LDABC())
function clause decode (0b00011010)
    = Some(LDADE())
function clause decode (0b00000010)
    = Some(LDBCA())
function clause decode (0b00010010)
    = Some(LDDEA())
function clause decode (0b00100010)
    = Some(LDIHLA())
function clause decode (0b00101010)
    = Some(LDIAHL())
function clause decode (0b00110010)
    = Some(LDDHLA())
function clause decode (0b00111010)
    = Some(LDDAHL())
function clause decode (0b11111001)
    = Some(LDSPHL())
function clause decode (0b11 @ rr : regname16 @ 0b0101)
    = Some(PUSHRR(rr))
function clause decode (0b11 @ rr : regname16 @ 0b0001)
    = Some(POPRR(rr))
function clause decode (0b10000 @ r : regname)
    = Some(ADDAR(r))
function clause decode (0b10001 @ r : regname)
    = Some(ADCAR(r))
function clause decode (0b10010 @ r : regname)
    = Some(SUBR(r))
function clause decode (0b10011 @ r : regname)
    = Some(SBCAR(r))
function clause decode (0b10100 @ r : regname)
    = Some(ANDR(r))
function clause decode (0b10101 @ r : regname)
    = Some(XORR(r))
function clause decode (0b10110 @ r : regname)
    = Some(ORR(r))
function clause decode (0b10111 @ r : regname)
    = Some(CPR(r))
function clause decode (0b00 @ r : regname @ 0b100)
    = Some(INCR(r))
function clause decode (0b00 @ r : regname @ 0b101)
    = Some(DECR(r))
function clause decode (0b00100111)
    = Some(DAA())
function clause decode (0b00101111)
    = Some(CPL())
function clause decode (0b00 @ rr : regname16 @ 0b1001)
    = Some(ADDHLRR(rr))
function clause decode (0b00 @ rr : regname16 @ 0b0011)
    = Some(INCRR(rr))
function clause decode (0b00 @ rr : regname16 @ 0b1011)
    = Some(DECRR(rr))
function clause decode (0b00000111)
    = Some(RLCA())
function clause decode (0b00010111)
    = Some(RLA())
function clause decode (0b00001111)
    = Some(RRCA())
function clause decode (0b00011111)
    = Some(RRA())
function clause decode (0b00111111)
    = Some(CCF())
function clause decode (0b00110111)
    = Some(SCF())
function clause decode (0b00000000)
    = Some(NOP())
function clause decode (0b01110110)
    = Some(HALT())
function clause decode (0b11110011)
    = Some(DI())
function clause decode (0b11111011)
    = Some(EI())
function clause decode (0b11101001)
    = Some(JPHL())
function clause decode (0b11001001)
    = Some(RET())
function clause decode (0b110 @ c : cond @ 0b000)
    = Some(RETF(c))
function clause decode (0b11011001)
    = Some(RETI())
function clause decode (0b11 @ r : rst_addr @ 0b111)
    = Some(RSTN(r))
function clause decode (0b11110010)
    = Some(LDAFF00C())
function clause decode (0b11100010)
    = Some(LDFF00CA())

function clause decode (inst8) = {
    /* Reading the next instruction takes a cycle */
    timing_tick_cycle();
    let next : word = read(PC);
    PC = PC + 1;

    decode16((EXTZ(inst8) << 8) | EXTZ(next))
}

/* 2 byte instructions */
scattered function decode16

function clause decode16 (0b00 @ r : regname @ 0b110 @ n : imm8)
    = Some(LDRN(r, n))
function clause decode16 (0b11110110 @ n : imm8)
    = Some(ORN(n))
function clause decode16 (0b11111110 @ n : imm8)
    = Some(CPN(n))
function clause decode16 (0b11101110 @ n : imm8)
    = Some(XORN(n))
function clause decode16 (0b11000110 @ n : imm8)
    = Some(ADDAN(n))
function clause decode16 (0b11001110 @ n : imm8)
    = Some(ADCAN(n))
function clause decode16 (0b11010110 @ n : imm8)
    = Some(SUBN(n))
function clause decode16 (0b11011110 @ n : imm8)
    = Some(SBCAN(n))
function clause decode16 (0b11100110 @ n : imm8)
    = Some(ANDN(n))
function clause decode16 (0b11001011 @ 0b00000 @ r : regname)
    = Some(RLCR(r))
function clause decode16 (0b11001011 @ 0b00010 @ r : regname)
    = Some(RLR(r))
function clause decode16 (0b11001011 @ 0b00001 @ r : regname)
    = Some(RRCR(r))
function clause decode16 (0b11001011 @ 0b00011 @ r : regname)
    = Some(RRR(r))
function clause decode16 (0b11001011 @ 0b00100 @ r : regname)
    = Some(SLAR(r))
function clause decode16 (0b11001011 @ 0b00110 @ r : regname)
    = Some(SWAPR(r))
function clause decode16 (0b11001011 @ 0b00101 @ r : regname)
    = Some(SRAR(r))
function clause decode16 (0b11001011 @ 0b00111 @ r : regname)
    = Some(SRLR(r))
function clause decode16 (0b00011000 @ n : imm8)
    = Some(JRNN(n))
function clause decode16 (0b001 @ c : cond @ 0b000 @ n : imm8)
    = Some(JRCN(c, n))
function clause decode16 (0b11100000 @ n : imm8)
    = Some(LDFF00NNA(n))
function clause decode16 (0b11110000 @ n : imm8)
    = Some(LDAFF00NN(n))
function clause decode16 (0b11101000 @ d : imm8)
    = Some(ADDSPD(d))
function clause decode16 (0b11111000 @ d : imm8)
    = Some(LDHLSPDD(d))
function clause decode16 (0b1100101101 @ d : imm3 @ r : regname)
    = Some(BITNR(d, r))
function clause decode16 (0b1100101111 @ d : imm3 @ r : regname)
    = Some(SETNR(d, r))
function clause decode16 (0b1100101110 @ d : imm3 @ r : regname)
    = Some(RESNR(d, r))
function clause decode16 (0b0001000000000000)
    = Some(STOP())

function clause decode16 (inst16) = {
    /* Reading the next instructions takes a cycle */
    timing_tick_cycle();
    let next : word = read(PC);
    PC = PC + 1;

    decode24((EXTZ(inst16) << 8) | EXTZ(next))
}

/* 3 byte instructions */
scattered function decode24

function clause decode24 (0b11000011 @ n1 : imm8 @ n2 : imm8)
    = Some(JPNN(EXTZ(n2) << 8 | EXTZ(n1)))
function clause decode24 (0b110  @ c : cond @ 0b010 @ n1 : imm8 @ n2 : imm8)
    = Some(JPCNN(c, EXTZ(n2) << 8 | EXTZ(n1)))
function clause decode24 (0b11101010 @ n1 : imm8 @ n2 : imm8)
    = Some(LDNNA(EXTZ(n2) << 8 | EXTZ(n1)))
function clause decode24 (0b11111010 @ n1 : imm8 @ n2 : imm8)
    = Some(LDANN(EXTZ(n2) << 8 | EXTZ(n1)))
function clause decode24 (0b00 @ rr : regname16 @ 0b0001 @ n1 : imm8 @ n2 : imm8)
    = Some(LDRRNN(rr, EXTZ(n2) << 8 | EXTZ(n1)))
function clause decode24 (0b00001000 @ n1 : imm8 @ n2 : imm8)
    = Some(LDNNSP(EXTZ(n2) << 8 | EXTZ(n1)))
function clause decode24 (0b110 @ c : cond @ 0b010 @ n1 : imm8 @ n2 : imm8)
    = Some(JPFNN(c, EXTZ(n2) << 8 | EXTZ(n1)))
function clause decode24 (0b11001101 @ n1 : imm8 @ n2 : imm8)
    = Some(CALLNN(EXTZ(n2) << 8 | EXTZ(n1)))
function clause decode24 (0b110 @ c : cond @ 0b100 @ n1 : imm8 @ n2 : imm8)
    = Some(CALLFNN(c, EXTZ(n2) << 8 | EXTZ(n1)))
function clause decode24 (not_supported) 
    = Some(INVALID(not_supported))

// todo: rename n and nn because of confusion with the nibble concept

/* Execute instruction code */
val execute : ast -> bool
scattered function execute

/* Instruction clock cycle count */

val assembly : ast -> string
scattered function assembly

function clause assembly(INVALID(instr)) = concat_str("Invalid instruction: ", bits_str(instr))
function clause execute(INVALID(instr)) = {
    false
}

function clause assembly(JPCNN(c, nn)) = concat_str("JP\t, ", concat_str(cond_str(c), concat_str(", ", bits_str(nn))))
/* if c: PC = nn */
function clause execute(JPCNN(c, nn)) = {
    timing_tick_cycle();
    if condition_true(c) then { 
        timing_tick_cycle();
        set_PC(nn);
    };
    true
}

function clause assembly(LDRR(r1, r2)) = concat_str(concat_str("ld", concat_str("\t", reg8_str(r1))), concat_str(", ", reg8_str(r2)))
/* r=r */
function clause execute(LDRR(r1, r2)) = {
    timing_tick_cycle();
    write_reg8(r1) = read_reg8(r2);
    true
}
function clause assembly(LDRN(r, n)) = concat_str(concat_str("ld", concat_str("\t", reg8_str(r))), concat_str(", ", bits_str(n)))
/* r=n */
function clause execute(LDRN(r, n)) = {
    timing_tick_cycle();
    write_reg8(r) = n;
    true
}
function clause assembly(LDABC()) = concat_str(concat_str("ld", concat_str("\t", "A")), concat_str(", ", "(BC)"))
/* A=(BC) */
function clause execute(LDABC()) = {
    timing_tick_cycle();
    let addr = read_reg16(reg16_name(BC));
    timing_tick_cycle();
    write_reg8(reg8_name(A)) = read(addr);
    true
}
function clause assembly(LDADE()) = concat_str(concat_str("ld", concat_str("\t", "A")), concat_str(", ", "(DE)"))
/* A=(DE) */
function clause execute(LDADE()) = {
    timing_tick_cycle();
    let addr = read_reg16(reg16_name(DE));
    timing_tick_cycle();
    write_reg8(reg8_name(A)) = read(addr);
    true
}
function clause assembly(LDANN(nn)) = concat_str(concat_str("ld", concat_str("\t", "A")), concat_str(", ", concat_str(concat_str("(", bits_str((nn))), ")")))
/* A=(nn) */
function clause execute(LDANN(nn)) = {
    timing_tick_cycle();
    /* in real cpu this would probably set the addr on the line */
    timing_tick_cycle();
    write_reg8(reg8_name(A)) = read(nn);
    true
}
function clause assembly(LDBCA()) = concat_str(concat_str("ld", concat_str("\t", "(BC)")), concat_str(", ", "A"))
/* (BC)=A */
function clause execute(LDBCA()) = {
    timing_tick_cycle();
    let addr = read_reg16(reg16_name(BC));
    timing_tick_cycle();
    write(addr) = read_reg8(reg8_name(A));
    true
}
function clause assembly(LDDEA()) = concat_str(concat_str("ld", concat_str("\t", "(DE)")), concat_str(", ", "A"))
/* (DE)=A */
function clause execute(LDDEA()) = {
    timing_tick_cycle();
    let addr = read_reg16(reg16_name(DE));
    timing_tick_cycle();
    write(addr) = read_reg8(reg8_name(A));
    true
}
function clause assembly(LDNNA(nn)) = concat_str(concat_str("ld", concat_str("\t", concat_str(concat_str("(", bits_str((nn))), ")"))), concat_str(", ", "A"))
/* (nn)=A */
function clause execute(LDNNA(nn)) = {
    timing_tick_cycle();
    let addr = nn;
    timing_tick_cycle();
    write(addr) = read_reg8(reg8_name(A));
    true
}
function clause assembly(LDIHLA()) = concat_str(concat_str("ldi", concat_str("\t", "(HL)")), concat_str(", ", "A"))
/* (HL)=A, HL=HL+1 */
function clause execute(LDIHLA()) = {
    timing_tick_cycle();
    let hlval = read_reg16(reg16_name(HL));
    timing_tick_cycle();
    write(hlval) = read_reg8(reg8_name(A));
    write_reg16(reg16_name(HL)) = hlval + 1;
    true
}
function clause assembly(LDIAHL()) = concat_str(concat_str("ldi", concat_str("\t", "A")), concat_str(", ", "(HL)"))
/* A=(HL), HL=HL+1 */
function clause execute(LDIAHL()) = {
    timing_tick_cycle();
    let hlval = read_reg16(reg16_name(HL));
    timing_tick_cycle();
    write_reg8(reg8_name(A)) = read(hlval);
    write_reg16(reg16_name(HL)) = hlval + 1;
    true
}
function clause assembly(LDDHLA()) = concat_str(concat_str("ldd", concat_str("\t", "(HL)")), concat_str(", ", "A"))
/* (HL)=A, HL=HL-1 */
function clause execute(LDDHLA()) = {
    timing_tick_cycle();
    let hlval = read_reg16(reg16_name(HL));
    timing_tick_cycle();
    write(hlval) = read_reg8(reg8_name(A));
    write_reg16(reg16_name(HL)) = hlval + -1;
    true
}
function clause assembly(LDDAHL()) = concat_str(concat_str("ldd", concat_str("\t", "A")), concat_str(", ", "(HL)"))
/* A=(HL), HL=HL-1 */
function clause execute(LDDAHL()) = {
    timing_tick_cycle();
    let hlval = read_reg16(reg16_name(HL));
    timing_tick_cycle();
    write_reg8(reg8_name(A)) = read(hlval);
    write_reg16(reg16_name(HL)) = hlval + -1;
    true
}
function clause assembly(LDRRNN(rr, nn)) = concat_str(concat_str("ld", concat_str("\t", reg16_str(rr))), concat_str(", ", bits_str(nn)))
/* rr=nn (rr may be BC,DE,HL or SP) */
function clause execute(LDRRNN(rr, nn)) = {
    timing_tick_cycle();
    write_reg16(rr) = nn;
    true
}
function clause assembly(LDNNSP(nn)) = concat_str(concat_str("ld", concat_str("\t", concat_str(concat_str("(", bits_str((nn))), ")"))), concat_str(", ", "SP"))
/* (nn)=SP */
function clause execute(LDNNSP(nn)) = {
    let sp = read_reg16(reg16_name(SP));
    timing_tick_cycle();
    write(nn) = truncate(sp, 8);
    timing_tick_cycle();
    write(nn+1) = truncate((sp >> 8), 8);
    timing_tick_cycle();
    true
}
function clause assembly(LDSPHL()) = concat_str(concat_str("ld", concat_str("\t", "SP")), concat_str(", ", "HL"))
/* SP=HL */
function clause execute(LDSPHL()) = {
    /* todo: implement me */
    timing_tick_cycle();
    let res = read_reg16(reg16_name(HL));
    timing_tick_cycle();
    write_reg16(reg16_name(SP)) = res;
    true
}
function clause assembly(PUSHRR(rr)) = concat_str("push", concat_str("\t", reg16_wAF_str(rr)))
/* SP=SP-2  (SP)=rr ; rr may be BC,DE,HL,AF */
function clause execute(PUSHRR(rr)) = {
    /* Cycle to put SP on the addr line */
    timing_tick_cycle();

    /* Im pretty sure doing this in one go here is accurate enough */
    write_reg16(reg16_name(SP)) = read_reg16(reg16_name(SP)) + -2;
    let addr = read_reg16(reg16_name(SP));

    timing_tick_cycle();
    write(addr + 1, truncate((read_reg16_wAF(rr) >> 8), 8));
    timing_tick_cycle();
    write(addr + 0, truncate(read_reg16_wAF(rr), 8));
    timing_tick_cycle();

    true
}
function clause assembly(POPRR(rr)) = concat_str("pop", concat_str("\t", reg16_wAF_str(rr)))
/* rr=(SP)  SP=SP+2 ; rr may be BC,DE,HL,AF */
function clause execute(POPRR(rr)) = {
    let addr = read_reg16(reg16_name(SP));
    timing_tick_cycle();
    let lsb = read(addr);
    timing_tick_cycle();
    let msb = read(addr + 1);

    timing_tick_cycle();
    write_reg16_wAF(rr) = (EXTZ(msb) << 8) + EXTZ(lsb);
    write_reg16(reg16_name(SP)) = read_reg16(reg16_name(SP)) + 2;

    true
}

val add : (word, word) -> word
function add(a, b) = {
    let res = a + b;
    let long_res : bits(16) = EXTZ(a) + EXTZ(b);

    set_flags(
        if res == 0x00 then 0b1 else 0b0,
        0b0,
        if (((a & 0x0f) + (b & 0x0f)) & 0x10) != 0x00 then 0b1 else 0b0,
        if (long_res & 0x0100) != 0x0000 then 0b1 else 0b0
    );

    return res;
}

function clause assembly(ADDAR(r)) = concat_str(concat_str("add", concat_str("\t", "A")), concat_str(", ", reg8_str(r)))
/* A=A+r */
function clause execute(ADDAR(r)) = {
    timing_tick_cycle();
    write_reg8(reg8_name(A)) = add(read_reg8(reg8_name(A)), read_reg8(r));
    true
}
function clause assembly(ADDAN(n)) = concat_str(concat_str("add", concat_str("\t", "A")), concat_str(", ", bits_str(n)))
/* A=A+n */
function clause execute(ADDAN(n)) = {
    timing_tick_cycle();
    write_reg8(reg8_name(A)) = add(read_reg8(reg8_name(A)), n);
    true
}

val adc : (word, word, word) -> word
function adc(a, b, c) = {
    let res = a + b + c;
    let long_res : bits(16) = EXTZ(a) + EXTZ(b) + EXTZ(c);

    set_flags(
        if res == 0x00 then 0b1 else 0b0,
        0b0,
        if (((a & 0x0f) + (b & 0x0f) + (c & 0x0f)) & 0x10) != 0x00 then 0b1 else 0b0,
        if (long_res & 0x0100) != 0x0000 then 0b1 else 0b0
    );

    return res;
}

function clause assembly(ADCAR(r)) = concat_str(concat_str("adc", concat_str("\t", "A")), concat_str(", ", reg8_str(r)))
/* A=A+r+cy */
function clause execute(ADCAR(r)) = {
    timing_tick_cycle();
    write_reg8(reg8_name(A)) = adc(read_reg8(reg8_name(A)), read_reg8(r), EXTZ(flag_c()));
    true
}
function clause assembly(ADCAN(n)) = concat_str(concat_str("adc", concat_str("\t", "A")), concat_str(", ", bits_str(n)))
/* A=A+n+cy */
function clause execute(ADCAN(n)) = {
    timing_tick_cycle();
    write_reg8(reg8_name(A)) = adc(read_reg8(reg8_name(A)), n, EXTZ(flag_c()));
    true
}
function clause assembly(SUBR(r)) = concat_str("sub", concat_str("\t", reg8_str(r)))
/* A=A-r */
function clause execute(SUBR(r)) = {
    timing_tick_cycle();
    write_reg8(reg8_name(A)) = add(read_reg8(reg8_name(A)), 0x00 - read_reg8(r));
    set_flags(
        flag_z(),
        0b1,
        ~(flag_h()),
        ~(flag_c())
    );
    true
}
function clause assembly(SUBN(n)) = concat_str("sub", concat_str("\t", bits_str(n)))
/* A=A-n */
function clause execute(SUBN(n)) = {
    timing_tick_cycle();
    write_reg8(reg8_name(A)) = add(read_reg8(reg8_name(A)), 0x00 - n);
    set_flags(
        flag_z(),
        0b1,
        ~(flag_h()),
        ~(flag_c())
    );
    true
}

function clause assembly(SBCAR(r)) = concat_str(concat_str("sbc", concat_str("\t", "A")), concat_str(", ", reg8_str(r)))
/* A=A-r-cy */
function clause execute(SBCAR(r)) = {
    timing_tick_cycle();
    write_reg8(reg8_name(A)) = adc(read_reg8(reg8_name(A)), 0x00 - read_reg8(r), 0x00 - EXTZ(flag_c()));
    set_flags(
        flag_z(),
        0b1,
        ~(flag_h()),
        ~(flag_c())
    );
    true
}
function clause assembly(SBCAN(n)) = concat_str(concat_str("sbc", concat_str("\t", "A")), concat_str(", ", bits_str(n)))
/* A=A-n-cy */
function clause execute(SBCAN(n)) = {
    timing_tick_cycle();
    write_reg8(reg8_name(A)) = adc(read_reg8(reg8_name(A)), 0x00 - n, 0x00 - EXTZ(flag_c()));
    set_flags(
        flag_z(),
        0b1,
        ~(flag_h()),
        ~(flag_c())
    );
    true
}
function clause assembly(ANDR(r)) = concat_str("and", concat_str("\t", reg8_str(r)))
/* A=A & r */
function clause execute(ANDR(r)) = {
    timing_tick_cycle();
    let res = read_reg8(reg8_name(A)) & read_reg8(r);

    set_flags(
        if res == 0x00 then 0b1 else 0b0,
        0b0,
        0b1,
        0b0
    );

    write_reg8(reg8_name(A)) = res;
    true
}
function clause assembly(ANDN(n)) = concat_str("and", concat_str("\t", bits_str(n)))
/* A=A & n */
function clause execute(ANDN(n)) = {
    timing_tick_cycle();
    let res = read_reg8(reg8_name(A)) & n;
    set_flags(
        if res == 0x00 then 0b1 else 0b0,
        0b0,
        0b1,
        0b0
    );
    write_reg8(reg8_name(A)) = res;
    true
}
function clause assembly(XORR(r)) = concat_str("xor", concat_str("\t", reg8_str(r)))
/* A=A xor r */
function clause execute(XORR(r)) = {
    timing_tick_cycle();
    let res = read_reg8(reg8_name(A)) ^ read_reg8(r);
    set_flags(
        if res == 0x00 then 0b1 else 0b0,
        0b0,
        0b0,
        0b0
    );
    write_reg8(reg8_name(A)) = res;
    true
}
function clause assembly(XORN(n)) = concat_str("xor", concat_str("\t", bits_str(n)))
/* A=A xor n */
function clause execute(XORN(n)) = {
    timing_tick_cycle();
    let res = read_reg8(reg8_name(A)) ^ n;

    set_flags(
        if res == 0x00 then 0b1 else 0b0,
        0b0,
        0b0,
        0b0
    );
    write_reg8(reg8_name(A)) = res;

    true
}
function clause assembly(ORR(r)) = concat_str("or", concat_str("\t", reg8_str(r)))
/* A=A \ */
function clause execute(ORR(r)) = {
    timing_tick_cycle();
    let res = read_reg8(reg8_name(A)) | read_reg8(r);
    
    set_flags(
        if res == 0x00 then 0b1 else 0b0,
        0b0,
        0b0,
        0b0
    );
    write_reg8(reg8_name(A)) = res;
    true
}
function clause assembly(ORN(n)) = concat_str("or", concat_str("\t", bits_str(n)))
/* A=A \ */
function clause execute(ORN(n)) = {
    timing_tick_cycle();
    let res = read_reg8(reg8_name(A)) | n;

    set_flags(
        if res == 0x00 then 0b1 else 0b0,
        0b0,
        0b0,
        0b0
    );
    write_reg8(reg8_name(A)) = res;
    true
}
function clause assembly(CPR(r)) = concat_str("cp", concat_str("\t", reg8_str(r)))
/* compare A-r */
function clause execute(CPR(r)) = {
    timing_tick_cycle();
    let useless = add(read_reg8(reg8_name(A)), 0x00 - read_reg8(r));

    set_flags(
        flag_z(),
        0b1,
        ~(flag_h()),
        ~(flag_c())
    );

    true
}

function clause assembly(CPN(n)) = concat_str("cp", concat_str("\t", bits_str(n)))
/* compare A-n */
function clause execute(CPN(n)) = {
    timing_tick_cycle();
    let useless = add(read_reg8(reg8_name(A)), 0x00 - n);

    set_flags(
        flag_z(),
        0b1,
        ~(flag_h()),
        ~(flag_c())
    );

    true
}
function clause assembly(INCR(r)) = concat_str("inc", concat_str("\t", reg8_str(r)))
/* r=r+1 */
function clause execute(INCR(r)) = {
    timing_tick_cycle();
    let regval = read_reg8(r);
    let res = regval + 1;

    set_flags(
        if res == 0x00 then 0b1 else 0b0,
        0b0,
        if (((regval & 0x0F) + 0x01) & 0x10) != 0x00 then 0b1 else 0b0,
        flag_c()
    );

    write_reg8(r) = res;
    true
}
function clause assembly(DECR(r)) = concat_str("dec", concat_str("\t", reg8_str(r)))
/* r=r-1 */
function clause execute(DECR(r)) = {
    timing_tick_cycle();
    let regval = read_reg8(r);
    let res = regval + -1;

    set_flags(
        if res == 0x00 then 0b1 else 0b0,
        0b1,
        if (((regval & 0x0F) + 0x0F) & 0x10) != 0x00 then 0b1 else 0b0,
        flag_c()
    );

    write_reg8(r) = res;
    true
}
function clause assembly(ADDSPD(d)) = concat_str("add\tSP, ", bits_str(d))
/* SP = SP +/- dd ; dd is 8-bit signed number */
function clause execute(ADDSPD(d)) = {
    /* I am not yet sure if this is correct because I could not find docs */
    timing_tick_cycle();
    timing_tick_cycle();
    let res = read_reg16(reg16_name(SP)) + EXTS(d);    
    write_reg16(reg16_name(SP)) = res;
    
    set_flags(
        0b0,
        0b0,
        0b0, /* todo: h register */
        if signed(d) < 0 then 0b1 else 0b0
    );
    timing_tick_cycle();

    true
}

function clause assembly(LDHLSPDD(d)) = concat_str("ld\tHL, SP+", bits_str(d))
/* HL = SP +/- dd ; dd is 8-bit signed number */
function clause execute(LDHLSPDD(d)) = {
    timing_tick_cycle();

    write_reg16(reg16_name(HL)) = read_reg16(reg16_name(SP)) + EXTS(d);
    
    set_flags(
        0b0,
        0b0,
        0b0, /* todo: h register */
        if signed(d) < 0 then 0b1 else 0b0
    );

    timing_tick_cycle();
    true
}

function clause assembly(DAA()) = "daa"
/* decimal adjust A */
function clause execute(DAA()) = {
    timing_tick_cycle();

    /* Code taken from mooneye-gb emulator (and converted to sail ofcourse) */
    var carry = 0b0;
    var acc = read_reg8(reg8_name(A));

    if (flag_n() == 0b0) then {
        if ((flag_c() == 0b1) & (unsigned(acc) > unsigned(0x99))) then {
            acc = acc + 0x60;
            carry = 0b1;
        };
        if ((flag_h() == 0b1) | (unsigned(acc & 0x0F) > unsigned(0x09))) then {
            acc = acc + 0x06;
        };
    } else if (flag_c() == 0b1) then {
        carry = 0b1;
        acc = acc + (if (flag_h() == 0b1) then 0x9a else 0xa0);
    } else if (flag_h() == 0b1) then {
        acc = acc + 0xfa;
    };

    set_flags(
        if (acc == 0x00) then 0b1 else 0b0,
        flag_n(),
        0b0,
        carry
    );

    write_reg8(reg8_name(A)) = acc;
    true
}
function clause assembly(CPL()) = "cpl"
/* A = A xor FF */
function clause execute(CPL()) = {
    timing_tick_cycle();
    let res = read_reg8(reg8_name(A)) ^ 0xFF;

    set_flags(
        flag_z(),
        0b1,
        0b1,
        flag_c()
    );
    write_reg8(reg8_name(A)) = res;

    true
}
function clause assembly(ADDHLRR(rr)) = concat_str(concat_str("add", concat_str("\t", "HL")), concat_str(", ", reg16_str(rr)))
/* HL = HL+rr     ; rr may be BC,DE,HL,SP */
function clause execute(ADDHLRR(rr)) = {
    timing_tick_cycle();
    
    /* there must be a better way but this is an easy way to check for integer overflows */
    let large_res : bits(32) = EXTZ(read_reg16(reg16_name(HL))) + EXTZ(read_reg16(rr));

    set_flags(
        flag_z(),
        0b0,
        0b0, /* todo: h flag */
        if unsigned(large_res) > unsigned(0xffff) then 0b1 else 0b0
    );

    write_reg16(reg16_name(HL)) = read_reg16(reg16_name(HL)) + read_reg16(rr);
    timing_tick_cycle();
    true
}
function clause assembly(INCRR(rr)) = concat_str("inc", concat_str("\t", reg16_str(rr)))
/* rr = rr+1      ; rr may be BC,DE,HL,SP */
function clause execute(INCRR(rr)) = {
    timing_tick_cycle();
    let res = read_reg16(rr) + 1;
    timing_tick_cycle();
    write_reg16(rr) = res;
    true
}
function clause assembly(DECRR(rr)) = concat_str("dec", concat_str("\t", reg16_str(rr)))
/* rr = rr-1      ; rr may be BC,DE,HL,SP */
function clause execute(DECRR(rr)) = {
    timing_tick_cycle();
    let res = read_reg16(rr) + -1;
    timing_tick_cycle();
    write_reg16(rr) = res;
    true
}
function clause assembly(RLCA()) = "rlca"
/* rotate A left */
function clause execute(RLCA()) = {
    let useless = execute(RLCR(reg8_name(A)));
    set_flags(
        0b0,
        0b0,
        0b0,
        flag_c()
    );
    true
}
function clause assembly(RLA()) = "rla"
/* rotate A left through carry */
function clause execute(RLA()) = {
    let useless = execute(RLR(reg8_name(A)));
    set_flags(
        0b0,
        0b0,
        0b0,
        flag_c()
    );
    true
}
function clause assembly(RRCA()) = "rrca"
/* rotate A right */
function clause execute(RRCA()) = {
    let useless = execute(RRCR(reg8_name(A)));
    set_flags(
        0b0,
        0b0,
        0b0,
        flag_c()
    );
    true
}
function clause assembly(RRA()) = "rra"
/* rotate A right through carry */
function clause execute(RRA()) = {
    /* Todo better way to get rid of this bool value? */
    let useless = execute(RRR(reg8_name(A)));
    set_flags(
        0b0,
        0b0,
        0b0,
        flag_c()
    );
    true
}
function clause assembly(RLCR(r)) = concat_str("rlc", concat_str("\t", reg8_str(r)))
/* rotate left */
function clause execute(RLCR(r)) = {
    timing_tick_cycle();
    let regval = read_reg8(r);
    let new_carry = truncate((regval >> 7) & 0x01, 1);
    let new_reg = (regval << 1);
    write_reg8(r) = new_reg;
    set_flags(
        if new_reg == 0x00 then 0b1 else 0b0,
        0b0,
        0b0,
        new_carry
    );

    true
}
function clause assembly(RLR(r)) = concat_str("rl", concat_str("\t", reg8_str(r)))
/* rotate left through carry */
function clause execute(RLR(r)) = {
    timing_tick_cycle();
    let regval = read_reg8(r);
    let new_carry = truncate(regval >> 7, 1);
    let new_reg = (regval << 1) | EXTZ(flag_c());
    write_reg8(r) = new_reg;
    set_flags(
        if new_reg == 0x00 then 0b1 else 0b0,
        0b0,
        0b0,
        new_carry
    );

    true
}
function clause assembly(RRCR(r)) = concat_str("rrc", concat_str("\t", reg8_str(r)))
/* rotate right */
function clause execute(RRCR(r)) = {
    timing_tick_cycle();
    let regval = read_reg8(r);
    let new_carry = truncate(regval, 1);
    let new_reg = (regval >> 1);
    write_reg8(r) = new_reg;
    set_flags(
        if new_reg == 0x00 then 0b1 else 0b0,
        0b0,
        0b0,
        new_carry
    );

    true
}
function clause assembly(RRR(r)) = concat_str("rr", concat_str("\t", reg8_str(r)))
/* rotate right through carry */
function clause execute(RRR(r)) = {
    timing_tick_cycle();
    let regval = read_reg8(r);
    let new_carry = truncate(regval & 0x01, 1);
    let new_reg = (regval >> 1) |  (EXTZ(flag_c()) << 7);
    write_reg8(r) = new_reg;
    set_flags(
        if new_reg == 0x00 then 0b1 else 0b0,
        0b0,
        0b0,
        new_carry
    );

    true
}
function clause assembly(SLAR(r)) = concat_str("sla", concat_str("\t", reg8_str(r)))
/* shift left arithmetic (b0=0) */
function clause execute(SLAR(r)) = {
    timing_tick_cycle();
    let regval = read_reg8(r);
    let new_carry = truncate(regval >> 7, 1);
    let new_reg = (regval << 1);
    write_reg8(r) = new_reg;
    set_flags(
        if new_reg == 0x00 then 0b1 else 0b0,
        0b0,
        0b0,
        new_carry
    );
    true
}
function clause assembly(SWAPR(r)) = concat_str("swap", concat_str("\t", reg8_str(r)))
/* exchange low/hi-nibble */
function clause execute(SWAPR(r)) = {
    timing_tick_cycle();
    let regval = read_reg8(r);
    let low = regval & 0x0F;
    let high = (regval & 0xF0) >> 4;
    let newval = (low << 4) | high;
    write_reg8(r) = newval;

    set_flags(
        if newval == 0x00 then 0b1 else 0b0,
        0b0,
        0b0,
        0b0
    );
    true
}
function clause assembly(SRAR(r)) = concat_str("sra", concat_str("\t", reg8_str(r)))
/* shift right arithmetic (b7=b7) */
function clause execute(SRAR(r)) = {
    timing_tick_cycle();
    let regval = read_reg8(r);
    let new_carry = truncate(regval, 1);
    let new_reg = (regval >> 1) | (regval & 0x80);
    write_reg8(r) = new_reg;
    set_flags(
        if new_reg == 0x00 then 0b1 else 0b0,
        0b0,
        0b0,
        new_carry
    );

    true
}
function clause assembly(SRLR(r)) = concat_str("srl", concat_str("\t", reg8_str(r)))
/* shift right logical (b7=0) */
function clause execute(SRLR(r)) = {
    timing_tick_cycle();
    let regval = read_reg8(r);
    let res = regval >> 1;
    set_flags(
        if res == 0x00 then 0b1 else 0b0,
        0b0,
        0b0,
        if (regval & 0x01) == 0x01 then 0b1 else 0b0 /* I think the least significant bit is rotated to the cary flag */
    );
    write_reg8(r) = res;
    true
}
function clause assembly(JRNN(d)) = "JR    PC+nn"
/* relative jump to nn (PC=PC+8-bit signed) */
function clause execute(JRNN(d)) = {
    timing_tick_cycle();
    timing_tick_cycle();
    set_PC(PC + EXTS(d));
    true
}
function clause assembly(JRCN(c, n)) = concat_str("jr\t", concat_str(cond_str(c), concat_str(", PC+", concat_str(bits_str(n), concat_str("\t# ", bits_str(PC + EXTS(n)))))))
/* conditional relative jump if nz,z,nc,c */
function clause execute(JRCN(c, n)) = {
    timing_tick_cycle();
    if condition_true(c) then {
        timing_tick_cycle();
        set_PC(PC + EXTS(n));
    };

    true
}
function clause assembly(LDFF00NNA(n)) = concat_str("LD\t(", concat_str(bits_str(0xFF00 + EXTZ(n)), "), A"))
/* write to io-port n (memory FF00+n) */
function clause execute(LDFF00NNA(n)) = {
    timing_tick_cycle();
    let addr = 0xFF00 + EXTZ(n);
    timing_tick_cycle();
    write(addr) = read_reg8(reg8_name(A)); 
    true
}
function clause assembly(LDAFF00NN(n)) = concat_str("LD\tA, (", concat_str(bits_str(0xFF00 + EXTZ(n)), ")"))
/* read from io-port n (memory FF00+n) */
function clause execute(LDAFF00NN(n)) = {
    timing_tick_cycle();
    let addr = 0xFF00 + EXTZ(n);
    timing_tick_cycle();
    write_reg8(reg8_name(A)) = read(addr);
    true
}
function clause assembly(LDFF00CA(n)) = concat_str("LD\t(", concat_str(bits_str(0xFF00), "+C), A"))
/* write to io-port C (memory FF00+C) */
function clause execute(LDFF00CA()) = {
    timing_tick_cycle();
    let addr = 0xFF00 + EXTZ(read_reg8(reg8_name(C)));
    timing_tick_cycle();
    write(addr) = read_reg8(reg8_name(A));
    true
}
function clause assembly(LDAFF00C(n)) = concat_str("LD\tA, (", concat_str(bits_str(0xFF00), "+C)"))
/* read from io-port n (memory FF00+n) */
function clause execute(LDAFF00C(n)) = {
    timing_tick_cycle();
    let addr = 0xFF00 + EXTZ(read_reg8(reg8_name(C)));
    timing_tick_cycle();
    write_reg8(reg8_name(A)) = read(addr);
    true
}
function clause assembly(BITNR(n, r)) = concat_str(concat_str("bit", concat_str("\t", bits_str(n))), concat_str(", ", reg8_str(r)))
/* test bit n */
function clause execute(BITNR(n, r)) = {
    timing_tick_cycle();
    let regval = read_reg8(r);
    let res = regval & (0x01 << n);
    set_flags(
        if res != 0x00 then 0b0 else 0b1,
        0b0,
        0b1,
        flag_c()
    );
    true
}
function clause assembly(SETNR(n, r)) = concat_str(concat_str("set", concat_str("\t", bits_str(n))), concat_str(", ", reg8_str(r)))
/* set bit n */
function clause execute(SETNR(n, r)) = {
    timing_tick_cycle();
    write_reg8(r) = read_reg8(r) | (0x01 << n);
    true
}
function clause assembly(RESNR(n, r)) = concat_str(concat_str("res", concat_str("\t", bits_str(n))), concat_str(", ", reg8_str(r)))
/* reset bit n */
function clause execute(RESNR(n, r)) = {
    timing_tick_cycle();
    
    write_reg8(r) = read_reg8(r) & ~(0x01 << n);
    true
}
function clause assembly(CCF()) = "ccf"
/* cy=cy xor 1 */
function clause execute(CCF()) = {
    timing_tick_cycle();
    
    set_flags(
        flag_z(),
        0b0,
        0b0,
        if flag_c() == 0b1 then 0b0 else 0b1
    );
    true
}
function clause assembly(SCF()) = "scf"
/* cy=1 */
function clause execute(SCF()) = {
    timing_tick_cycle();
    set_flags(
        flag_z(),
        0b0,
        0b0,
        0b1
    );
    true
}
function clause assembly(NOP()) = "nop"
/* no operation */
function clause execute(NOP()) = {
    timing_tick_cycle();
    true
}
function clause assembly(HALT()) = "halt"
/* halt until interrupt occurs (low power) */
function clause execute(HALT()) = {
    /* todo: implement me */
    throw(error_not_implemented("HALT"));
    true
}
function clause assembly(STOP()) = "stop"
/* low power standby mode (VERY low power) */
function clause execute(STOP()) = {
    /* todo: implement me */
    true
}
function clause assembly(DI()) = "di"
/* disable interrupts, IME=0 */
function clause execute(DI()) = {
    timing_tick_cycle();
    print("interrupts off");
    interrupt_master = 0x00;
    true
}
function clause assembly(EI()) = "ei"
/* enable interrupts, IME=1 */
function clause execute(EI()) = {
    timing_tick_cycle();
    print("interrupts on");
    interrupt_master = 0x01;
    true
}
function clause assembly(JPNN(nn)) = concat_str("jp", concat_str("\t", bits_str(nn)))
/* jump to nn, PC=nn */
function clause execute(JPNN(nn)) = {
    timing_tick_cycle();
    timing_tick_cycle();
    set_PC(nn);
    true
}
function clause assembly(JPHL()) = concat_str("jp", concat_str("\t", "HL"))
/* jump to HL, PC=HL */
function clause execute(JPHL()) = {
    timing_tick_cycle();
    set_PC(read_reg16(reg16_name(HL)));
    true
}
function clause assembly(JPFNN(c, nn)) = "JP    c, nn"
/* conditional jump if nz,z,nc,c */
function clause execute(JPFNN(c, nn)) = {
    /* todo: implement me */
    throw(error_not_implemented("JPFNN"));
    true
}
function clause assembly(CALLNN(nn)) = concat_str("call", concat_str("\t", bits_str(nn)))
/* call to nn, SP=SP-2, (SP)=PC, PC=nn */
function clause execute(CALLNN(nn)) = {
    timing_tick_cycle();

    let addr = read_reg16(reg16_name(SP)) + -2;
    write_reg16(reg16_name(SP)) = addr;

    timing_tick_cycle();
    write(addr + 1, truncate((PC >> 8) & 0x00FF, 8));
    timing_tick_cycle();
    write(addr + 0, truncate(PC & 0x00FF, 8));
    timing_tick_cycle();
    set_PC(nn);
    true
}
function clause assembly(CALLFNN(c, nn)) = concat_str("call", concat_str("\t", concat_str(concat_str(cond_str(c), ", "), bits_str(nn))))
/* conditional call if nz,z,nc,c */
function clause execute(CALLFNN(c, nn)) = {
    if condition_true(c) then 
        execute(CALLNN(nn))
    else
    {
        timing_tick_cycle();
        true
    }
}
function clause assembly(RET()) = "ret"
/* return, PC=(SP), SP=SP+2 */
function clause execute(RET()) = {
    timing_tick_cycle();
    let addr = read_reg16(reg16_name(SP));
    let lsb = read(addr);
    timing_tick_cycle();
    let msb = read(addr + 1);
    
    write_reg16(reg16_name(SP)) = addr + 2;
    
    timing_tick_cycle();
    set_PC(EXTZ(msb) << 8 + EXTZ(lsb));
    
    timing_tick_cycle();
    true
}
function clause assembly(RETF(c)) = concat_str("ret\t", cond_str(c))
/* conditional return if nz,z,nc,c */
function clause execute(RETF(c)) = {
    timing_tick_cycle();
    if condition_true(c) then 
        execute(RET())
    else
    {
        timing_tick_cycle();
        true
    }
}
function clause assembly(RETI()) = "reti"
/* return and enable interrupts (IME=1) */
function clause execute(RETI()) = {    
    timing_tick_cycle();
    interrupt_master = 0x01;
    let addr = read_reg16(reg16_name(SP));
    let lsb = read(addr);
    timing_tick_cycle();
    let msb = read(addr + 1);
    
    write_reg16(reg16_name(SP)) = addr + 2;
    
    timing_tick_cycle();
    set_PC(EXTZ(msb) << 8 + EXTZ(lsb));
    
    timing_tick_cycle();
    true

}
function clause assembly(RSTN(n)) = concat_str("rst", concat_str("\t", bits_str(n)))
/* call to 00,08,10,18,20,28,30,38 */
function clause execute(RSTN(n)) = {
    /* todo: I think this is correct but I am not sure */
    execute(CALLNN(EXTZ(n) << 3));
}
