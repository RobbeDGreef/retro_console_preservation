#include <unistd.h>
#include <time.h>

#include "support.h"

unit sleep_micro(const sail_int micros) {
    usleep(mpz_get_ui(micros));
}

void get_time_micro(sail_int *rop, unit u) {
    struct timespec t;
    clock_gettime(CLOCK_REALTIME, &t);
    mpz_set_si(*rop, t.tv_sec);
    mpz_mul_ui(*rop, *rop, 1000000);
    mpz_add_ui(*rop, *rop, t.tv_nsec / 1000);
}

/* I know this is the same function as the sleep_micro sail one but
 * it doesn't use the bigint and this is just easier.
 */
unsigned long micros()
{
    struct timespec t;
    clock_gettime(CLOCK_REALTIME, &t);
    return t.tv_sec * 1000000 + (t.tv_nsec / 1000);
}
