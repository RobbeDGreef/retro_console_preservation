val print = "print_endline" : string -> unit

val print_cpu_state : unit -> unit
function print_cpu_state() = {
    print_bits("AF: ", reg_AF.bits());
    print_bits("BC: ", reg_BC.bits());
    print_bits("DE: ", reg_DE.bits());
    print_bits("HL: ", reg_HL.bits());
    print_bits("SP: ", reg_SP);
}