#include "memory.h"
#include "interrupts.h"
#include <SDL2/SDL.h>

#define JOYP_RIGHT 0
#define JOYP_LEFT 1
#define JOYP_UP 2
#define JOYP_DOWN 3
#define JOYP_A 0
#define JOYP_B 1
#define JOYP_SELECT 2
#define JOYP_START 3
#define JOYP_DIRECTION_BTNS 4
#define JOYP_ACTION_BTNS 5

#define KEYSYM_UP 1073741906
#define KEYSYM_DOWN 1073741905
#define KEYSYM_LEFT 1073741904
#define KEYSYM_RIGHT 1073741903

#define SET(val, bit) (val | (1 << bit))
#define UNSET(val, bit) (val & ~(1 << bit))
#define KEYPRESS(val, bit) UNSET(val, bit)
#define KEYUP(val, bit) SET(val, bit)

int g_joyp = 0xFF;

uint64_t io_read_joyp(uint64_t addr, int bytes)
{
    return g_joyp;
}
void io_write_joyp(uint64_t addr, int bytes, uint64_t val)
{
    g_joyp = (val & 0b000011) | (g_joyp & 0b111100);
}

void joypad_update(SDL_Event *event)
{
    switch (event->type)
    {
    case SDL_KEYDOWN:
    {
        int key = event->key.keysym.sym;
        if (g_joyp & JOYP_ACTION_BTNS)
        {
            switch (key)
            {
            case 'a':
                g_joyp = KEYPRESS(g_joyp, JOYP_A);
                break;
            case 'b':
                g_joyp = KEYPRESS(g_joyp, JOYP_B);
                break;
            case 's':
                g_joyp = KEYPRESS(g_joyp, JOYP_START);
                break;
            case 'd':
                g_joyp = KEYPRESS(g_joyp, JOYP_SELECT);
                break;
            }
            interrupt(INTERRUPT_JOYPAD);
        }
        else if (g_joyp & JOYP_DIRECTION_BTNS)
        {
            switch (key)
            {
            case KEYSYM_UP:
                g_joyp = KEYPRESS(g_joyp, JOYP_UP);
                break;
            case KEYSYM_DOWN:
                g_joyp = KEYPRESS(g_joyp, JOYP_DOWN);
                break;
            case KEYSYM_LEFT:
                g_joyp = KEYPRESS(g_joyp, JOYP_LEFT);
                break;
            case KEYSYM_RIGHT:
                g_joyp = KEYPRESS(g_joyp, JOYP_RIGHT);
                break;
            }
            interrupt(INTERRUPT_JOYPAD);
        }
        break;
    }
    /*
    case SDL_KEYUP:
                int key = event->key.keysym.sym;
        switch (key) {
        case KEYSYM_UP:
            g_joyp = KEYUP(g_joyp, JOYP_UP, JOYP_DIRECTION_BTNS);
            break;
        case KEYSYM_DOWN:
            g_joyp = KEYUP(g_joyp, JOYP_DOWN, JOYP_DIRECTION_BTNS);
            break;
        case KEYSYM_LEFT:
            g_joyp = KEYUP(g_joyp, JOYP_LEFT, JOYP_DIRECTION_BTNS);
            break;
        case KEYSYM_RIGHT:
            g_joyp = KEYUP(g_joyp, JOYP_RIGHT, JOYP_DIRECTION_BTNS);
            break;
        case 'a':
            g_joyp = KEYUP(g_joyp, JOYP_A, JOYP_ACTION_BTNS);
            break;
        case 'b':
            g_joyp = KEYUP(g_joyp, JOYP_B, JOYP_ACTION_BTNS);
            break;
        case 's':
            g_joyp = KEYUP(g_joyp, JOYP_START, JOYP_ACTION_BTNS);
            break;
        case 'd':
            g_joyp = KEYUP(g_joyp, JOYP_SELECT, JOYP_ACTION_BTNS);
            break;
        }
        interrupt(INTERRUPT_JOYPAD);
        break;
    */
    default:
        break;
    }
}

void joypad_init()
{
    register_io_read_handler(0xFF00, io_read_joyp);
    register_io_write_handler(0xFF00, io_write_joyp);
}