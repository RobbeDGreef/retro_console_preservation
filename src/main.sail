default Order dec
$include <prelude.sail>

/* prelude */

val print = "print_endline" : string -> unit

/* wrong implementation to make compiler happy */
function print_string (s1, s2) : (string, string) -> unit = {
    print(s1);
    print(s2);
}

/* Register definitions */

type wordlen : Int = 8
type dwordlen : Int = 16

type wordlen_bytes : Int = 1
type dwordlen_bytes : Int = 2

type wordbits = bits(wordlen)
type dwordbits = bits(dwordlen)

type regtype = wordbits
type dregtype = dwordbits

/* registers */
register PC : dregtype
register AF : dregtype
register BC : dregtype
register DE : dregtype
register HL : dregtype
register SP : dregtype

/* Exceptions */

union exception = {
  error_not_implemented : string,
  error_internal_error  : unit
}

/* Code */
function loop () : unit -> unit = {
    while true do {
        print_bits("PC = ", PC);
        PC = PC + 1;
    }
}

function main () : unit -> unit = {

    PC = sail_zero_extend(0x000, sizeof(dwordlen));
    
    try {
        loop();
    } catch {
        error_not_implemented(s) => print_string("Error: Not implemented: ", s),
        error_internal_error() => print("Error: internal error")
    }
}
