#include "memory.h"
#include "timing.h"
#include "debug.h"

#define CPU_CLOCK 4194304UL
#define TIMA_CLOCK_1 (4096UL * 100000000UL / CPU_CLOCK)
#define TIMA_CLOCK_2 (262144UL * 100000000UL / CPU_CLOCK)
#define TIMA_CLOCK_3 (65536UL * 100000000UL / CPU_CLOCK)
#define TIMA_CLOCK_4 (16384UL * 100000000UL / CPU_CLOCK)

#define TAC_ENABLE (1 << 2)
#define TAC_DEFAULT_CLOCK_ID 0b00
#define TAC_CLOCK_MASK 0b11

#define TIMER_DIV_CLOCK 16384UL
#define TIMER_TICKS_PER_10MIL_CYCLES (TIMER_DIV_CLOCK * 100000000 / CPU_CLOCK)

int g_tima = 0;
unsigned long g_tima_clock_per_million = 0;
unsigned long g_last_tima_reset_cycle = 0;

int g_div = 0;
unsigned long g_last_div_read_cycle = 0;

int g_tma = 0;
int g_tac = 0;

void io_write_div(uint64_t addr, int bytes, uint64_t val)
{
    // Writing any value to this register resets it to 0
    g_div = 0;
    /* -4 -4 because our cycle timing sets adds the cycle before executing the instruction*/
    g_last_div_read_cycle = get_passed_cycles() - 8;
}

uint64_t io_read_div(uint64_t addr, int bytes)
{
    /* Get current cycle, calculate what the timer should be */
    unsigned long diff = (get_passed_cycles() - g_last_div_read_cycle);
    printf("diff: %lu (%lu - %lu)\n", diff, get_passed_cycles(), g_last_div_read_cycle);
    diff *= TIMER_TICKS_PER_10MIL_CYCLES;
    printf("diff: %lu\n", diff);
    diff /= 100000000;

    printf("current time: %lu\n", diff);

    return diff & 0xFF;
}

void io_write_tima(uint64_t addr, int bytes, uint64_t val)
{
    UNIMPLEMENTED("write to TIMA");
}

uint64_t io_read_tima(uint64_t addr, int bytes)
{
    /* Calculate the value the timer should have */
    unsigned long diff = (get_passed_cycles() - g_last_tima_reset_cycle);
    diff *= g_tima_clock_per_million;
    diff /= 100000000;

    return diff & 0xFF;
}

void io_write_tma(uint64_t addr, int bytes, uint64_t val)
{
    g_tma = val;
}

uint64_t io_read_tma(uint64_t addr, int bytes)
{
    return g_tma;
}


void io_write_tac(uint64_t addr, int bytes, uint64_t val)
{
    static unsigned long lookup[] = {
        [0b00] = TIMA_CLOCK_1,
        [0b01] = TIMA_CLOCK_2,
        [0b10] = TIMA_CLOCK_3,
        [0b11] = TIMA_CLOCK_4,
    };

    g_tac = val;
    if (!(g_tac & TAC_ENABLE))
    {
        // disable timer interrupt
    }

    g_tima_clock_per_million = lookup[g_tac & TAC_CLOCK_MASK];
}

uint64_t io_read_tac(uint64_t addr, int bytes)
{
    return g_tac;
}

void timer_init()
{
    g_tac = TAC_ENABLE | TAC_DEFAULT_CLOCK_ID;
    g_tima_clock_per_million = TIMA_CLOCK_1;

    register_io_read_handler(0xFF04, io_read_div);
    register_io_write_handler(0xFF04, io_write_div);
    
    register_io_read_handler(0xFF05, io_read_tima);
    register_io_write_handler(0xFF05, io_write_tima);

    register_io_read_handler(0xFF05, io_read_tma);
    register_io_write_handler(0xFF05, io_write_tma);

    register_io_read_handler(0xFF07, io_read_tac);
    register_io_write_handler(0xFF07, io_write_tac);
    
}