default Order dec
$include <prelude.sail>
$include "prelude.sail"
$include "types.sail"
$include "exceptions.sail"
$include "utils.sail"
$include "memory.sail"
$include "instructions.sail"


/* Code */
function fetch_and_execute(): unit -> bool = {
    let instruction = MEMr(PC);

    print_bits("PC = ", PC);
    print_bits("First 8 bits of instruction = ", instruction);
    
    PC = PC + 1;

    /* Check whether we successfully decoded our instruction, if not stop looping */
    let loop_again : bool = match decode(instruction) {
      Some(ast) => execute(ast),
      None() => { print("invalid instruction"); false }
    };

    print_cpu_state();

    return loop_again;
}

function cpu_loop () : unit -> unit = {
    while (fetch_and_execute()) do
        ();
}

function setup (): unit -> unit = {
    /* setup registers */
    PC = EXTZ(0x100);
    SP = 0xFFFE;
}


function main () : unit -> unit = {
    setup();
    

    // pass in binary using flags
    // flag: "binary"
    // example: ./emulator --binary=0x0,test_roms/simple_increment_loop/simple.gb

    try {
        cpu_loop();
    } catch {
        error_not_implemented(s) => print_string("Error: Not implemented: ", s),
        error_internal_error() => print("Error: internal error")
    }
}
