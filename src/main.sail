default Order dec
$include <prelude.sail>
$include "prelude.sail"
$include "types.sail"
$include "exceptions.sail"
$include "utils.sail"
$include "memory.sail"
$include "instructions.sail"

/* Code */
function fetch_and_execute(prev_instruction): (bool) -> bool = {
    let start_micro = get_time_micro();
    let instruction = MEMr(PC);

    print_bits("PC = ", PC);
    print_bits("First 8 bits of instruction = ", instruction);
    
    PC = PC + 1;

    /* Check whether we successfully decoded our instruction, if not stop looping */
    let decoded = decode(instruction);

    let loop_again : bool = match decoded {
      Some(ast) => execute(ast),
      None() => { print("invalid instruction"); false }
    };

    print_cpu_state();

    // Todo: better way to do this?
    match decoded {
        Some(ast) => {
            var cycles = get_cycles_per_instruction(ast);
            if (prev_instruction) then
                cycles = cycles - 4;
            
            let real_duration = (get_time_micro() - start_micro);
            let ms_to_wait = cycles * micros_per_cycle - real_duration;
            sleep_micro(real_duration);
        }
    };
    

    return loop_again;
}

function cpu_loop () : unit -> unit = {
    /* The first cpu cycle doesnt have a previous instruction */
    // Q(Robbe):is there a better way to handle this
    let useless = fetch_and_execute(false);
    while (fetch_and_execute(true)) do
        debug_hook();
}

function setup (): unit -> unit = {
    /* setup registers */
    PC = EXTZ(0x100);

    /* Behavior of the DMG bios https://gbdev.io/pandocs/Power_Up_Sequence.html */
    reg_SP = 0xFFFE;
    reg_AF->bits() = 0x0100;
    reg_BC->bits() = 0x0013;
    reg_DE->bits() = 0x00D8;
    reg_HL->bits() = 0x014D;
    
    sound_ctrl_reg->bits() = 0xFF;
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
