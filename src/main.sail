default Order dec
$include <prelude.sail>
$include "prelude.sail"
$include "const.sail"
$include "types.sail"
$include "exceptions.sail"
$include "timing.sail"
$include "utils.sail"
$include "memory.sail"
$include "instructions.sail" 
$include "interrupts.sail" 


val cycle_write = {
    c: "cycle_write"
} : (string, int, int) -> unit

/* Code */
function fetch_decode_execute(prev_instruction): (bool) -> bool = {
    /* First try to execute an interrupt */
    check_for_interrupts();

    let start_micro = get_time_micro();

    let instruction = read(PC);

    let inst_pc = unsigned(PC);

    PC = PC + 1;

    /* Store the passed cycles before the instruction */
    let cycles_before = passed_cycles;

    /* Decode instruction */
    let decoded = decode(instruction);

    /* Print assembly */
    let asm : string = match decoded {
        Some(ast) => assembly(ast),
        None(ast) => {throw error_internal_error(); "unknown instruction"}
    };
    //print_instruction(inst_pc, asm, cycles_before);

    /* Call debugger hook before the instruction is executed */
    debug_hook(inst_pc);

    /* Fetch the amount of cycles the instruction should take */
    var cycles : int = match(decoded) {
        Some(ast) => get_cycles_per_instruction(ast)
    };

    /* Fetch execute overlap handling */
    if (not(prev_instruction)) then {
        cycles = cycles + g_fetch_duration;
        timing_tick_cycle();
    };

    /* Execute instruction */
    let loop_again : bool = match decoded {
        Some(ast) => execute(ast)
    };

    /* Make sure the updated cycles is correct with the amount of cycles that should have passed */
    if (passed_cycles - cycles_before != cycles) then {
        throw error_cycles_incorrectly_updated(asm, cycles, passed_cycles - cycles_before)
    };

    //print_cpu_state();

    /* Finally the acutal sleep */
    timing_sleep_cycles(cycles, start_micro);

    return loop_again;
}

function cpu_loop () : unit -> unit = {
    /* The first cpu cycle doesnt have a previous instruction */
    // Q(Robbe):is there a better way to handle this
    let useless = fetch_decode_execute(false);
    while (fetch_decode_execute(true)) do
        ();
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

    interrupt_flag = 0x00;
    interrupt_enable = 0x01;
    interrupt_master = 0x01;
}

function main () : unit -> unit = {
    setup();

    /**
     * pass in binary using flags
     * flag: "binary"
     * example: ./emulator --binary=0x0,test_roms/simple_increment_loop/simple.gb
     */
    try {
        cpu_loop()
    } catch {
        error_not_implemented(s) => print_string("Error: Not implemented: ", s),
        error_internal_error() => print("Error: internal error"),
        error_cycles_incorrectly_updated(asm, correct_cycles, actual_passed_cycles) => {
            print_string("Incorrect amount of cycles passed in instruction ", asm);
            print_int("correct cycles: ", correct_cycles);
            print_int("actually passed: ", actual_passed_cycles);
        }
    };
}
