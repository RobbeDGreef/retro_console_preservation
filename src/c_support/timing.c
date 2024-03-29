#include <unistd.h>
#include <time.h>

#include "support.h"
#include "timing.h"
#include "timer.h"

/* Sail stuff */
extern sail_int zpassed_cycles;

#define PASSED_CYCLES zpassed_cycles

struct timer_callback
{
    int start_ms;
    int cycles;
    void *arg;
    timer_callback_t cb;

    struct timer_callback *next;
};

struct timer_callback *g_timer_callbacks = NULL;
unsigned long g_excess = 0;

/* I know this is the same function as the sleep_micro sail one but
 * it doesn't use the bigint and this is just easier.
 */
unsigned long micros()
{
    struct timespec t;
    clock_gettime(CLOCK_REALTIME, &t);
    return t.tv_sec * 1000000 + (t.tv_nsec / 1000);
}

unit sleep_micro(const sail_int micros)
{
    usleep(mpz_get_ui(micros));
    return UNIT;
}

/**
 * Get the actual passed (real) milliseconds. 
 */
void get_time_micro(sail_int *rop, unit u)
{
    struct timespec t;
    clock_gettime(CLOCK_REALTIME, &t);
    mpz_set_si(*rop, t.tv_sec);
    mpz_mul_ui(*rop, *rop, 1000000);
    mpz_add_ui(*rop, *rop, t.tv_nsec / 1000);
}

/**
 * Get the amount of passed cycles from the timing.sail file. 
 */
unsigned long get_passed_cycles()
{
    return mpz_get_ui(PASSED_CYCLES);
}

/**
 * Register a callback that will be called after a certain amount of cycles
 */
void register_cycle_timing_callback(int cycles, timer_callback_t cb, void *arg)
{
    struct timer_callback *timer = malloc(sizeof(struct timer_callback));
    timer->cycles = cycles;
    timer->start_ms = get_passed_cycles();
    timer->cb = cb;
    timer->arg = arg;
    timer->next = g_timer_callbacks;

    g_timer_callbacks = timer;
}

void deregister_cycle_timing_callback(timer_callback_t cb)
{
    struct timer_callback *iter = g_timer_callbacks;
    struct timer_callback *prev = NULL;

    while (iter)
    {
        if (iter->cb == cb) {
            if (prev == NULL)
                g_timer_callbacks = iter->next;
            else
                prev->next = iter->next;

            /* Set next iter */
            struct timer_callback *old = iter;
            iter = iter->next;

            /* Memory management */
            free(old);
        }
        else
        {
            prev = iter;
            iter = iter->next;
        }
    }
}

unit cycle_timer_update()
{
    unsigned long cycle = get_passed_cycles();

    /* Update the timer */
    timer_update(cycle);

    struct timer_callback *iter = g_timer_callbacks;
    struct timer_callback *prev = NULL;

    while (iter)
    {
        if (cycle - iter->start_ms >= iter->cycles)
        {
            /* Remove from list */
            if (prev == NULL)
                g_timer_callbacks = iter->next;
            else
                prev->next = iter->next;

            /* Set next iter */
            struct timer_callback *old = iter;
            iter = iter->next;

            /* Call callback */
            old->cb(old->arg);

            /* Memory management */
            free(old);
        }
        else
        {
            prev = iter;
            iter = iter->next;
        }
    }

    return UNIT;
}

void timing_init()
{
    /* Pre init passed_cycles so we dont segfault on first cycle use */
    mpz_init(PASSED_CYCLES);
}