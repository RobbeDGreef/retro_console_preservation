#ifndef __INTERRUPTS_H
#define __INTERRUPTS_H

#define INTERRUPT_ENABLE_ADDR 0xFFFF

#define INTERRUPT_JOYPAD (1 << 4)
#define INTERRUPT_VBLANK (1 << 0)
#define INTERRUPT_TIMER  (1 << 2)

void interrupts_enable();
void interrupt(int interrupt);
void interrupts_disable();
void interrupts_init();

void interrupt_set_ei(uint64_t val);
uint64_t interrupt_get_ei();

#endif /* __INTERRUPTS_H */