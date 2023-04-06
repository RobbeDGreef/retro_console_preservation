#ifndef __SUPPORT_H
#define __SUPPORT_H

#include <sail.h>

/* Timing functions */

unit sleep_micro(const sail_int micros);
void get_time_micro(sail_int *rop, const unit u);

unit debug_hook(unit u);

bool custom_write_ram(const mpz_t addr_size,
					  const mpz_t data_size_mpz,
					  const lbits hex_ram,
					  const lbits addr_bv,
					  const lbits data);
void custom_read_ram(lbits *data,
					 const mpz_t addr_size,
					 const mpz_t data_size_mpz,
					 const lbits hex_ram,
					 const lbits addr_bv);

unit print_instruction(const sail_int addr, const sail_string assembly);
unit print_string(sail_string s1, sail_string s2);

unit cycle_timer_update();

#endif /* __SUPPORT_H */