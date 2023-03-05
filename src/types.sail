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

register PC : dword
register AF : dreg
register BC : dreg
register DE : dreg
register HL : dreg
register SP : dword

let registers : vector(4, dec, register(dreg)) = [ ref AF, ref BC, ref DE, ref HL]

enum shortreg_name = {
    A,
    B,
    C,
    D,
    E,
    H,
    L
}