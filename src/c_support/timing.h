#ifndef __TIMING_H
#define __TIMING_H

#include <unistd.h>

typedef void (*timer_callback_t)();

unsigned long micros();
void timing_sleep_ms(int delay);
void register_cycle_timing_callback(int cycles, timer_callback_t cb, void *arg);
void deregister_cycle_timing_callback(timer_callback_t cb);
unsigned long get_passed_cycles();
void timing_init();

#endif /* __TIMING_H */