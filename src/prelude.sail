val EXTS : forall 'n 'm, 'm >= 'n. (implicit('m), bits('n)) -> bits('m)
val EXTZ : forall 'n 'm, 'm >= 'n. (implicit('m), bits('n)) -> bits('m)

function EXTS(m, v) = sail_sign_extend(v, m)
function EXTZ(m, v) = sail_zero_extend(v, m)

infix 7 >>
infix 7 <<

val "shift_bits_right" : forall 'n 'm. (bits('n), bits('m)) -> bits('n)
val "shift_bits_left"  : forall 'n 'm. (bits('n), bits('m)) -> bits('n)

val "shiftl" : forall 'm 'n, 'n >= 0. (bits('m), atom('n)) -> bits('m)
val "shiftr" : forall 'm 'n, 'n >= 0. (bits('m), atom('n)) -> bits('m)

overload operator >> = {shift_bits_right, shiftr}
overload operator << = {shift_bits_left, shiftl}

val get_time_micro = {
  c: "get_time_micro"
} : unit -> int

val sleep_micro = {
    c: "sleep_micro"
} : int -> unit
val debug_hook = pure {
  c: "debug_hook"
} : unit -> unit
