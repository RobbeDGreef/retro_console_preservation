#include <pthread.h>
#include "screen.h"
#include "memory.h"

int model_main(int argc, char *argv[]);

int main(int argc, char *argv[])
{
    memory_init();
    timer_init();
    screen_init();

    pthread_t thread;
    pthread_create(&thread, NULL, screen_loop, NULL);

    // Start the main sail code
    model_main(argc, argv);
}
