#include <stdbool.h>

#include "memory.h"
#include "debug.h"
#include "timing.h"
#include "interrupts.h"

/** 
 * Recreated behavior of timer circuit as described in https://gbdev.io/pandocs/Timer_Obscure_Behaviour.html 
 * code inspired by mooneye-gb https://github.com/Gekkio/mooneye-gb
 */

#define SYS_CLOCKS_PER_TICK 4

#define INTERNAL_COUNTER_DIV_OFFSET 8

#define TAC_ENABLE (1 << 2)
#define TAC_DEFAULT_CLOCK_ID 0b00
#define TAC_CLOCK_MASK 0b11

int g_tima = 0;
int g_tma = 0;
int g_tac = 0;

uint16_t g_internal_counter = 0;
bool g_overflow_occured = false;

/* Returns whether the current tac counter bit is set in the internal counter */
static bool is_counter_bit_set() {
    /* There bits represent the different timer speeds, they are defined inside the timer circuit https://gbdev.io/pandocs/Timer_Obscure_Behaviour.html */
    int bit_lookup[] = {
        [0b00] = 9,
        [0b01] = 3,
        [0b10] = 5,
        [0b11] = 7,
    };
    return g_internal_counter & (1 << bit_lookup[g_tac & TAC_CLOCK_MASK]);
}

static void tima_increment() {
    g_tima++;

    /* Check whether the timer overflowed the 8 bit boundary */
    if (g_tima == 0x100) {
        g_overflow_occured = true;
        g_tima = 0;
    }
}

static bool is_tac_enabled() {
    return (g_tac & TAC_ENABLE);
}

void io_write_div(uint64_t addr, int bytes, uint64_t val)
{
    /* Writing any value resets the internal counter (and thus the div). */

    /** 
     * When the current counter bit is set to high, the tima will not increment until it goes
     * low (see the falling edge detector in the circuit), this means that when this bit is high
     * and the internal counter is reset, the bit will go low and thus the tima should increment.
    */
    if (is_counter_bit_set()) {
        tima_increment();
    }

    g_internal_counter = 0;
}

uint64_t io_read_div(uint64_t addr, int bytes)
{
    return g_internal_counter >> INTERNAL_COUNTER_DIV_OFFSET;
}

void io_write_tima(uint64_t addr, int bytes, uint64_t val)
{
    /* todo: I am pretty sure there is some obscure behavior that should be checked here */
    g_tima = val;
}

uint64_t io_read_tima(uint64_t addr, int bytes)
{
    return g_tima;
}

void io_write_tma(uint64_t addr, int bytes, uint64_t val)
{
    g_tma = val;
    //if (g_overflow_occured) {
    //    tima_increment();
    //}
}

uint64_t io_read_tma(uint64_t addr, int bytes)
{
    return g_tma;
}

void io_write_tac(uint64_t addr, int bytes, uint64_t val)
{
    bool should_update = is_tac_enabled() && is_counter_bit_set();
    g_tac = val;

    /* According to mooneye-gb this is necessary */
    if (!(is_tac_enabled() && is_counter_bit_set()) && should_update) {
        tima_increment();
    }
}

uint64_t io_read_tac(uint64_t addr, int bytes)
{
    return g_tac;
}

/* Called from timing.c:cycle_timer_update (updated every tick) */
void timer_update(unsigned long current_cycle)
{
    if (g_overflow_occured) {
        g_internal_counter += SYS_CLOCKS_PER_TICK;

        /* Set the timer to the modulo register and notify the system of the timing interrupt */
        g_tima = g_tma;
        interrupt(INTERRUPT_TIMER);

        g_overflow_occured = false;
    } else if (is_tac_enabled() && is_counter_bit_set()) {
        g_internal_counter += SYS_CLOCKS_PER_TICK;
        if (!is_counter_bit_set()) {
            tima_increment();
        }
    } else {
        g_internal_counter += SYS_CLOCKS_PER_TICK;
    }
}

void timer_init()
{
    /* This first write is as a setup */
    io_write_tac(0, 0, TAC_DEFAULT_CLOCK_ID | TAC_ENABLE);

    register_io_read_handler(0xFF04, io_read_div);
    register_io_write_handler(0xFF04, io_write_div);

    register_io_read_handler(0xFF05, io_read_tima);
    register_io_write_handler(0xFF05, io_write_tima);

    register_io_read_handler(0xFF06, io_read_tma);
    register_io_write_handler(0xFF06, io_write_tma);

    register_io_read_handler(0xFF07, io_read_tac);
    register_io_write_handler(0xFF07, io_write_tac);
}