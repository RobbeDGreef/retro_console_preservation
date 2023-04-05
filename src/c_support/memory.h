#ifndef __MEMORY_H
#define __MEMORY_H

#include <stdint.h>

#define IO_BASE 0xFF00
#define IO_LENGTH 0x80
#define ECHO_RAM_BASE 0xE000
#define ECHO_RAM_LENGTH 0x1E00
#define OAM_BASE 0xFE00
#define OAM_LENGTH 0xA0
#define VRAM_BASE 0x8000
#define VRAM_LENGTH 0x2000
#define WRAM_BASE 0xC000

typedef uint64_t (*io_read_handler_t)(uint64_t, int);
typedef void (*io_write_handler_t)(uint64_t, int, uint64_t);

void register_io_read_handler(uint64_t addr, io_read_handler_t handler);
void register_io_write_handler(uint64_t addr, io_write_handler_t handler);

io_read_handler_t get_io_read_handler(uint64_t addr);
io_write_handler_t get_io_write_handler(uint64_t addr);

void memory_init();
void memory_copy(void* dst, uint64_t addr, int bytecount);

#endif 
