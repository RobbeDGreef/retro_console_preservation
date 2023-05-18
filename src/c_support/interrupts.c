#include <stdint.h>
#include <stdio.h>
#include "memory.h"

extern uint64_t zinterrupt_flag;
extern uint64_t zinterrupt_master;
extern uint64_t zinterrupt_enable;

#define IM zinterrupt_master
#define IF zinterrupt_flag
#define IE zinterrupt_enable


/**
 * @brief Mark interrupt pending
 * 
 * @param interrupt the interrupt to mark
 */
void interrupt(int interrupt)
{
    IF |= interrupt;
}

void interrupts_enable()
{
    IM = 1;
}

void interrupts_disable()
{
    IM = 0;
}

void io_write_if(uint64_t addr, int bytes, uint64_t val)
{
    IF = val;
}

uint64_t io_read_if(uint64_t addr, int bytes)
{
    return IF;
}

void interrupt_set_ei(uint64_t val)
{
    IE = val;
}

uint64_t interrupt_get_ei()
{
    return IE;
}

void interrupts_init()
{
    register_io_read_handler(0xFF0F, io_read_if);
    register_io_write_handler(0xFF0F, io_write_if);

    /* The 0xFFFF interrupt enable register is not in IO memory 
       range and is thus not called via the register hook but rather
       from the switch statement in the custom_read_ram / custom_write_ram */
}