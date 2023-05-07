register interrupt_flag : word
register interrupt_enable : word
register interrupt_master : word

val interrupt_service_routine : (word, word) -> unit
function interrupt_service_routine(addr, bit) = {
    /* Reset IF and IE */
    interrupt_flag = interrupt_flag & (~(0x01 << bit));
    interrupt_enable = interrupt_enable & (~(0x01 << bit));

    /* 2 NOPs */
    timing_add_cycles(8);

    /* Push PC onto the stack */
    timing_add_cycles(4);
    let addr = read_reg16(reg16_name(SP)) + -2;
    write_reg16(reg16_name(SP)) = addr;

    write(addr + 1, truncate((PC >> 8) & 0x00FF, 8));
    timing_add_cycles(4);
    write(addr + 0, truncate(PC & 0x00FF, 8));

    /* Set pc to handler */
    timing_add_cycles(4);
    set_PC(EXTZ(addr));
}

val check_for_interrupts : unit -> unit
function check_for_interrupts() = {
    if interrupt_master == 0x00 then
        return

    /* This cannot be a match since multiple interrupts can be waiting 
       and thus multiple interrupts can be triggered here */
    if ((interrupt_flag   & (0x01 << 0)) != 0x00) &
       ((interrupt_enable & (0x01 << 0)) != 0x00) then {
        /* vblank interrupt */
        interrupt_service_routine(0x40, 0x00);
    };
    if ((interrupt_flag   & (0x01 << 1)) != 0x00) &
       ((interrupt_enable & (0x01 << 1)) != 0x00) then {
        /* LCD stat interrupt */
        interrupt_service_routine(0x48, 0x01);
    };
    if ((interrupt_flag   & (0x01 << 2)) != 0x00) &
       ((interrupt_enable & (0x01 << 2)) != 0x00) then {
        /* timer interrupt */
        interrupt_service_routine(0x50, 0x02);
    };
    if ((interrupt_flag   & (0x01 << 3)) != 0x00) &
       ((interrupt_enable & (0x01 << 3)) != 0x00) then {
        /* serial interrupt */
        interrupt_service_routine(0x58, 0x03);
    };
    if ((interrupt_flag   & (0x01 << 4)) != 0x00) &
       ((interrupt_enable & (0x01 << 4)) != 0x00) then {
        /* joypad interrupt */
        interrupt_service_routine(0x60, 0x04);
    };
}