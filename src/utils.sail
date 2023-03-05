val print = "print_endline" : string -> unit

/* wrong implementation to make compiler happy */
function print_string (s1, s2) : (string, string) -> unit = {
    print(s1);
    print(s2);
}

val print_cpu_state : unit -> unit effect {rreg}
function print_cpu_state() = {
    print_bits("AF: ", AF.bits());
    print_bits("BC: ", BC.bits());
    print_bits("DE: ", DE.bits());
    print_bits("HL: ", HL.bits());
    print_bits("SP: ", SP);
}