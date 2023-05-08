#include <pthread.h>
#include "screen.h"
#include "memory.h"
#include "debug.h"
#include "timer.h"
#include "timing.h"
#include "interrupts.h"

int model_main(int argc, char *argv[]);

int main(int argc, char *argv[])
{
    debug_init();
    interrupts_init();
    timing_init();
    memory_init();
    timer_init();
    screen_init();

    pthread_t thread;
    pthread_create(&thread, NULL, screen_start, NULL);

    // Start the main sail code
    model_main(argc, argv);
}
