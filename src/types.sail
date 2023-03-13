type address_size : Int = 16
type address = bits(address_size)

type word_size : Int = 8
type word = bits(word_size)

type dword_size : Int = 16
type dword = bits(dword_size)

/* registers */

bitfield dreg : dword = {
    higher: 15 .. 8,
    lower: 7 .. 0
}

bitfield acc_flags : dword = {
    higher: 15 .. 8,
    z: 7,
    n: 6,
    h: 5,
    c: 4
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