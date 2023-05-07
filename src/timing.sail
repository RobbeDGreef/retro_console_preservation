register passed_cycles : int = 0
register timing_excess : int = 0

val accuracte_sleep_ms : (int) -> unit
function accuracte_sleep_ms(duration) = {
    /* If delay is negative add it to the excess */
    if (duration < 0) then {
        timing_excess = timing_excess + (0 - duration);
        return ();
    };

    /* If the excess is larger than the requested delay dont sleep and just continue */
    if (timing_excess >= duration) then {
        timing_excess = timing_excess - duration;
        return ();
    };

    let start = get_time_micro();
    let sleep_delay = duration - timing_excess;
    sleep_micro(sleep_delay);

    /* Remove excess sleep */
    timing_excess = timing_excess - (duration - sleep_delay);
    
    let real_duration = get_time_micro() - start;

    /* Add the time our sleep "overslept" to the excess */
    if (real_duration > duration) then {
        timing_excess = timing_excess + (real_duration - duration)
    }
}

/**
 * This function will keep track of the amount of passed ms since the start of the
 * program. This will be used in C to align stuff like DMA transfers to the correct
 * cycle.
 */
val timing_sleep_cycles : (int, int) -> unit
function timing_sleep_cycles(cycles, start_micro) = {
    /* The sleeping that makes the emulator run at a perceived correct speed */
    let duration = cycles * g_micros_per_cycle - (get_time_micro() - start_micro);
    accuracte_sleep_ms(duration);
}

val timing_tick_cycle : (unit) -> unit 
function timing_tick_cycle(unit) = {
    passed_cycles = passed_cycles + g_sys_clock_tick_cycles;
    cycle_timer_update();
}