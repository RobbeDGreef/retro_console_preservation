type address_size : Int = 16
type address = bits(address_size)

type word_size : Int = 8
type word = bits(word_size)

type dword_size : Int = 16
type dword = bits(dword_size)

/* registers */

bitfield dreg : dword = {
    lower: 7 .. 0,
    higher: 15 .. 8
}

bitfield acc_flags : dword = {
    higher: 15 .. 8,
    c: 4,
    h: 5,
    n: 6,
    z: 7
}

register PC : dword
register reg_AF : acc_flags
register reg_BC : dreg
register reg_DE : dreg
register reg_HL : dreg
register reg_SP : dword

enum reg8_enum = {
    A,
    B,
    C,
    D,
    E,
    H,
    L
}

enum reg16_enum = {
    AF,
    BC,
    DE,
    HL,
    SP
}

register interrupt_flag : word
register interrupt_enable : word
register interrupt_master : word