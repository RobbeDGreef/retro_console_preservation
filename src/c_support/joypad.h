#ifndef __JOYPAD_H
#define __JOYPAD_H

#include <SDL2/SDL.h>

void joypad_update(SDL_Event *event);
void joypad_init();

#endif /* __JOYPAD_H */