val EXTS : forall 'n 'm, 'm >= 'n. (implicit('m), bits('n)) -> bits('m)
function EXTS(m, v) = sail_sign_extend(v, m)

val EXTZ : forall 'n 'm, 'm >= 'n. (implicit('m), bits('n)) -> bits('m)
function EXTZ(m, v) = sail_zero_extend(v, m)

infix 7 >>
infix 7 <<

val "shift_bits_right" : forall 'n 'm. (bits('n), bits('m)) -> bits('n)
val "shift_bits_left"  : forall 'n 'm. (bits('n), bits('m)) -> bits('n)

val "shiftl" : forall 'm 'n, 'n >= 0. (bits('m), atom('n)) -> bits('m)
val "shiftr" : forall 'm 'n, 'n >= 0. (bits('m), atom('n)) -> bits('m)

overload operator >> = {shift_bits_right, shiftr}
overload operator << = {shift_bits_left, shiftl}

val xor_vec = pure {c: "xor_bits", _: "xor_vec"} : forall 'n. (bits('n), bits('n)) -> bits('n)

overload operator ^ = {xor_vec}

val sub_vec = {c: "sub_bits", _: "sub_vec"} : forall 'n. (bits('n), bits('n)) -> bits('n)

val sub_vec_int = {c: "sub_bits_int", _: "sub_vec_int"} : forall 'n. (bits('n), int) -> bits('n)

overload operator - = {sub_vec, sub_vec_int}

val string_length = "string_length" : string -> nat
val string_startswith = "string_startswith" : (string, string) -> bool
val string_drop = "string_drop" : (string, nat) -> string
val string_take = "string_take" : (string, nat) -> string

overload ~ = {not_bool, not_vec, not_bit}
val not = pure {coq:"negb", _:"not"} : bool -> bool

/* C stuff */

val get_time_micro = pure {
  c: "get_time_micro"
} : unit -> int

val sleep_micro = pure {
    c: "sleep_micro"
} : int -> unit

val debug_hook = pure {
  c: "debug_hook"
} : unit -> unit

val print_instruction = pure {
  c: "print_instruction"
} : (int, string) -> unit

val print_string = pure {
  c: "print_string"
} : (string, string) -> unit