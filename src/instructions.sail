type regname = bits(3)
type regname16 = bits(2)

type dst = regname
type src = regname
type dst16 = regname16
type src16 = regname16


type imm8 = bits(8)
type imm16 = bits(16)

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

val read_reg8 : regname -> word effect {rreg}
function read_reg8(r) = {
    match r {
        reg8_name(B) => reg_BC.higher(),
        reg8_name(C) => reg_BC.lower(),
        reg8_name(D) => reg_DE.higher(),
        reg8_name(E) => reg_DE.lower(),
        reg8_name(H) => reg_HL.higher(),
        reg8_name(L) => reg_HL.lower(),
        reg8_name(A) => reg_AF.higher()
    };
}

val write_reg8 : (regname, word) -> unit effect {wreg}
function write_reg8(r, w) = {
    match r {
        reg8_name(B) => reg_BC->higher() = w,
        reg8_name(C) => reg_BC->lower() = w,
        reg8_name(D) => reg_DE->higher() = w,
        reg8_name(E) => reg_DE->lower() = w,
        reg8_name(H) => reg_HL->higher() = w,
        reg8_name(L) => reg_HL->lower() = w,
        reg8_name(A) => reg_AF->higher() = w
    };
}

val read_reg16 : regname16 -> dword effect {rreg}
function read_reg16(r) = {
    match r {
        reg16_name(BC) => reg_BC.bits(),
        reg16_name(DE) => reg_DE.bits(),
        reg16_name(HL) => reg_HL.bits(),
        reg16_name(SP) => reg_SP
    };
}

val write_reg16 : (regname16, dword) -> unit effect {wreg}
function write_reg16(r, w) = {
    // Q(Robbe): BUG??????
    /*
    match r {
        reg16_name(BC) => reg_BC->bits() = w,
        reg16_name(DE) => reg_DE->bits() = w,
        reg16_name(HL) => reg_HL->bits() = w,
        reg16_name(SP) => reg_SP = w
    };
    */
    match r {
        0b00 => reg_BC->bits() = w,
        0b01 => reg_DE->bits() = w,
        0b10 => reg_HL->bits() = w,
        0b11 => reg_SP = w
    };
}

val set_PC : (dword) -> unit effect {wreg}
function set_PC(addr) = {
    PC = addr;
}

scattered union ast
union clause ast = LDRN             : (dst, imm8)       /* Load immediate into register */
union clause ast = JPNN             : (imm16)           /* Jump to absolute address PC=addr */
union clause ast = ADDAN            : (imm8)            /* Add immediate to A register */

/**
 * Since this CPU has variable length instructions we need to parse 8 bit
 * instructions seperately from 16 or 24 bit instructions.
 */
type instruction8 = bits(8)
type instruction16 = bits(16)
type instruction24 = bits(24)

val decode : instruction8 -> option(ast) effect {rreg, wreg}
val decode16 : instruction16 -> option(ast) effect {rreg, wreg}
val decode24 : instruction24 -> option(ast) effect {rreg, wreg}

/* 1 byte instructions */
scattered function decode

function clause decode (inst8) = {
    let next : word = MEMr(PC);
    PC = PC + 1;
    decode16((EXTZ(inst8) << 8) | EXTZ(next))
}

/* 2 byte instructions */
scattered function decode16

function clause decode16 (0b00 @ r : dst @ 0b110 @ n : imm8) 
    = Some(LDRN(r, n))
function clause decode16 (0b11000110 @ n : imm8) 
    = Some(ADDAN(n))
    = Some(ADD(n))

function clause decode16 (inst16) = {
    let next : word = MEMr(PC);
    PC = PC + 1;
    decode24((EXTZ(inst16) << 8) | EXTZ(next))
}

/* 3 byte instructions */
scattered function decode24

/* Q(Robbe): why does n: imm16 give most significant bit result */
function clause decode24 (0b11000011 @ n1 : imm8 @ n2 : imm8)
    = Some(JPNN(EXTZ(n2) << 8 | EXTZ(n1)))
function clause decode24 (not_supported) 
    = None()

/* Execute instruction code */

val execute : ast -> bool effect {rreg, wreg}
scattered function execute

/* Instruction clock cycle count */
val get_cycles_per_instruction : ast -> int effect {rreg}
scattered function get_cycles_per_instruction

function clause get_cycles_per_instruction(LDRN(r, n)) = 8
function clause execute(LDRN(r, n)) = {
    write_reg8(r) = n;
    true
}

function clause execute(ADD(n)) = {
    write_reg8(0b111) = read_reg8(0b111) + n;
    true
}


function clause get_cycles_per_instruction(ADDAN(n)) = 12
function clause execute(ADDAN(n)) = {
    write_reg8(reg8_name(A)) = read_reg8(reg8_name(A)) + n;
    true
}

function clause get_cycles_per_instruction(JPNN(nn)) = 16
function clause execute(JPNN(nn)) = {
    set_PC(nn);
    true
}
