#ifndef __SUPPORT_H
#define __SUPPORT_H

#include <sail.h>

/* Timing functions */

unit sleep_micro(const sail_int micros);
void get_time_micro(sail_int *rop, const unit u);

#endif /* __SUPPORT_H */