val interrupt_service_routine : (word, word) -> unit
function interrupt_service_routine(int_addr, bit) = {
    /* Reset IF */
    interrupt_flag = interrupt_flag & (~(0x01 << bit));
    interrupt_master = 0x00;

    /* 2 NOPs */
    timing_tick_cycle();
    timing_tick_cycle();

    /* Push PC onto the stack */
    timing_tick_cycle();
    let addr = read_reg16(reg16_name(SP)) + -2;
    write_reg16(reg16_name(SP)) = addr;

    write(addr + 1, truncate((PC >> 8) & 0x00FF, 8));
    timing_tick_cycle();
    write(addr + 0, truncate(PC & 0x00FF, 8));

    /* Set pc to handler */
    timing_tick_cycle();
    set_PC(EXTZ(int_addr));
}

val check_for_interrupts : unit -> unit
function check_for_interrupts() = {
    if interrupt_master != 0x00 then {
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
    };
}