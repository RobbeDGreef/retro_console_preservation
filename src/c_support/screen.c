#include <pthread.h>

#include <SDL2/SDL.h>

#include "rts.h"

#include "support.h"
#include "memory.h"
#include "debug.h"
#include "timing.h"

#define DBG_FAKE_VLINE 0
#define DBG_DISPLAY_TILES_ONLY 0

#define REAL_SCREEN_WIDTH 160
#define REAL_SCREEN_HEIGHT 144

#define TILE_SIZE 16
#define TILE_WIDTH 8

#define TILEMAP_WIDTH 256
#define TILEMAP_HEIGHT 256

#define VIRT_SCREEN_WIDTH 256
#define VIRT_SCREEN_HEIGHT 256

#define VSCAN_MAX 153
#define HSCAN_MAX 160

#define OBJTILES_ADDR 0x8000
#define OAM_SPRITE_COUNT 40

#define FRAME_DURATION 16742

#define LCD_AND_PPU_ENABLE (1 << 7)
#define WINDOW_TILE_MAP_AREA_9C00 (1 << 6)
#define WINDOW_ENABLE (1 << 5)
#define BG_WINDOW_TILE_DATA_AREA_8000 (1 << 4)
#define BG_TILE_MAP_AREA_9C00 (1 << 3)
#define OBJ_SIZE (1 << 2)
#define OBJ_ENABLE (1 << 1)
#define BG_WINDOW_PRIORITY_ENABLE (1 << 0)

struct sprite
{
    uint8_t y_pos;
    uint8_t x_pos;
    uint8_t tile_index;
    uint8_t attr_flags;
} __attribute__((packed));

pthread_t g_screen_thread;
SDL_Renderer *g_renderer = NULL;
SDL_Window *g_screen = NULL;
uint8_t g_vram[VRAM_LENGTH] = {0};
uint8_t g_oam[OAM_LENGTH] = {0};

/**
 * Why a spinlock instead of mutex? Because the critical section is so small a
 * mutex would create more overhead in putting the thread to sleep.
 */
pthread_spinlock_t g_vscan_lock;
int g_vscan = 0;
int g_hscan = 0;
uint32_t g_screen_buffer[VIRT_SCREEN_WIDTH * VIRT_SCREEN_HEIGHT];
uint8_t g_lcd_control = BG_WINDOW_PRIORITY_ENABLE | BG_WINDOW_TILE_DATA_AREA_8000 | LCD_AND_PPU_ENABLE;

static void stop_sdl()
{
    SDL_DestroyWindow(g_screen);
    SDL_Quit();
}

static void update_events()
{
    SDL_Event evt;

    // process OS events
    while (SDL_PollEvent(&evt) != 0)
    {
        switch (evt.type)
        {
        case SDL_QUIT:
            stop_sdl();
            exit(0);
            break;
        }
    }
}

static void copy_vram_and_oam()
{
    memory_copy(g_vram, VRAM_BASE, VRAM_LENGTH);
    memory_copy(g_oam, OAM_BASE, OAM_LENGTH);   
}

static uint8_t *get_tile_map()
{
    if (g_lcd_control & WINDOW_TILE_MAP_AREA_9C00)
        return &g_vram[0x9C00 - VRAM_BASE];
    else
        return &g_vram[0x9800 - VRAM_BASE];
}

static uint8_t *get_bg_win_tile_data()
{
    if (g_lcd_control & BG_WINDOW_TILE_DATA_AREA_8000)
        return &g_vram[0x8000 - VRAM_BASE];
    else
        return &g_vram[0x9000 - VRAM_BASE];
}

static void draw_tile(int x, int y, uint8_t *tile)
{
    /* todo: this should probably use palettes, however I dont think I need them for non-games */
    static uint32_t color_lookup[] = {
        [0b00] = 0xFFFFFFFF,
        [0b01] = 0xFFAAAAAA,
        [0b10] = 0xFF555555,
        [0b11] = 0xFF000000,
    };

    for (int i = 0; i < TILE_WIDTH; i++)
    {
        uint8_t byte1 = tile[i * 2];
        uint8_t byte2 = tile[i * 2 + 1];

        for (int j = 0; j < TILE_WIDTH; j++)
        {
            int val = ((byte1 >> j) & 1) | (((byte2 >> j) & 1) << 1);
            uint32_t color = color_lookup[val];

            /* We need to invert the tiles on the X axis for some reason */
            int x_inverted = x + (TILE_WIDTH - 1 - j);
            int y_loc = (y + i);
            
            /* todo there is a more efficient way to solve this but this works for now */
            /* Check if we would write out of bounds */
            if (y_loc < 0 || x_inverted < 0 || y_loc >= VIRT_SCREEN_WIDTH || x_inverted >= VIRT_SCREEN_WIDTH) continue;

            g_screen_buffer[y_loc * TILEMAP_WIDTH + x_inverted] = color;
        }
    }
}

static uint8_t *get_tile(int idx, int obj)
{
    uint8_t *tiles;
    if (obj)
        tiles = &g_vram[OBJTILES_ADDR - VRAM_BASE];
    else
        tiles = get_bg_win_tile_data();

    return &tiles[idx * TILE_SIZE];
}

static void draw_screen(unsigned long start_time)
{
    SDL_SetRenderDrawColor(g_renderer, 255, 255, 255, 255);


#if !(DBG_DISPLAY_TILES_ONLY)
    uint8_t *tilemap = get_tile_map();

    /* Drawing the background */
    for (int y = 0; y < TILEMAP_HEIGHT / TILE_WIDTH; y++)
    {
        for (int x = 0; x < TILEMAP_WIDTH / TILE_WIDTH; x++)
        {
            int tile_idx = (int8_t) tilemap[(TILEMAP_WIDTH / TILE_WIDTH) * y + x];
            draw_tile(x * TILE_WIDTH, y * TILE_WIDTH, get_tile(tile_idx, 0));
        }
    }

    /* todo: window is skipped, I dont think I need it for non games. */

    /* Drawing the objects */
    struct sprite *sprites = (struct sprite *)g_oam;
    for (int i = 0; i < OAM_SPRITE_COUNT; i++)
    {
        struct sprite sprite = sprites[i];
        if (sprite.tile_index != 0)
            draw_tile(sprite.x_pos - 8, sprite.y_pos - 16, get_tile(sprite.tile_index, 1));
    }
#else
    int x = 0;
    int y = 0;
    int non_empty = 0;
    for (int i = 0; i < 128; i++)
    {
        uint8_t* tile = get_tile(i, 1);
        if (*tile != 0) {
            non_empty++;
        }
        draw_tile(x, y, tile);
        x += 8;

        if (x >= REAL_SCREEN_WIDTH)
        {
            y += 8;
            x = 0;
        }
    }

#endif


    pthread_spin_lock(&g_vscan_lock);
    g_vscan = 0;
    pthread_spin_unlock(&g_vscan_lock);

    /**
     * We sleep during the scanlines and try to give the scanlines a certain time per
     * frame because if we didn't, the scanlines would take, say, <1ms and since the
     * cpu runs at >8ms per instruction, waiting for vblank could take quite a long
     * time.
     */

    /**
     * This /2 is a heuristic, it is necessary since the usleep often takes significantly longer
     * than the provided sleeptime. The excess time we lose we handle in the update_screen function.
     */
    unsigned long time_per_frame = ((FRAME_DURATION - (micros() - start_time)) / VSCAN_MAX) / 2;

    while (g_vscan < VSCAN_MAX)
    {
        unsigned long scan_start = micros();

        for (g_hscan = 0; g_hscan < HSCAN_MAX; g_hscan++)
        {
            uint32_t color = g_screen_buffer[g_vscan * VIRT_SCREEN_WIDTH + g_hscan];

            SDL_SetRenderDrawColor(g_renderer, (color >> 16) & 0xFF, (color >> 8) & 0xFF, (color >> 0) & 0xFF, (color >> 24) & 0xFF);
            SDL_RenderDrawPoint(g_renderer, g_hscan, g_vscan);
        }

        pthread_spin_lock(&g_vscan_lock);
        g_vscan++;
        pthread_spin_unlock(&g_vscan_lock);

        unsigned long scanline_duration = (micros() - scan_start);
    
        if (scanline_duration < time_per_frame)
            usleep(time_per_frame - scanline_duration);
    }
}

static void update_screen(unsigned long start_time)
{
    SDL_SetRenderDrawColor(g_renderer, 0, 0, 0, 255);
    SDL_RenderClear(g_renderer);

    draw_screen(start_time);

    SDL_RenderPresent(g_renderer);
}

void sdl_start()
{
    if (SDL_Init(SDL_INIT_VIDEO) != 0)
    {
        fprintf(stderr, "Could not init SDL: %s\n", SDL_GetError());
        exit(1);
    }

    g_screen = SDL_CreateWindow("Gameboy",
                                SDL_WINDOWPOS_UNDEFINED,
                                SDL_WINDOWPOS_UNDEFINED,
                                REAL_SCREEN_WIDTH, REAL_SCREEN_HEIGHT,
                                0);
    if (!g_screen)
    {
        fprintf(stderr, "Could not create window\n");
        exit(1);
    }

    g_renderer = SDL_CreateRenderer(g_screen, -1, SDL_RENDERER_SOFTWARE);
    if (!g_renderer)
    {
        fprintf(stderr, "Could not create renderer\n");
        exit(1);
    }
}

void *screen_start(void *arg)
{
    sdl_start();

    while (1)
    {
        unsigned long start = micros();

        update_events();

        copy_vram_and_oam();

        update_screen(start);

        /* Handle excess time we have to sleep */
        unsigned long duration = micros() - start;
        if (duration < FRAME_DURATION)
            usleep(FRAME_DURATION - duration);
    }
    return NULL;
}

uint64_t io_read_lcd_y(uint64_t addr, int bytes)
{
#if FAKE_VLINE
    // This will increment the line every time it is drawn, ugly but will work normally.
    // 0 until 153
    static int scanline = 0;
    if (scanline > 153)
        scanline = 0;

    return scanline++;
#else
    pthread_spin_lock(&g_vscan_lock);
    int val = g_vscan;
    pthread_spin_unlock(&g_vscan_lock);

    return val;
#endif
}

uint64_t io_read_lcd_stat(uint64_t addr, int bytes)
{
    UNIMPLEMENTED("lcd read stat register");
}

void io_write_lcd_control(uint64_t addr, int bytes, uint64_t val)
{
    g_lcd_control = (uint8_t)val;
}

uint64_t io_read_lcd_control(uint64_t addr, int bytes)
{
    return g_lcd_control;
}

void screen_init()
{
    // Init spinlock
    pthread_spin_init(&g_vscan_lock, 0);

    register_io_read_handler(0xFF44, io_read_lcd_y);
    register_io_read_handler(0xFF41, io_read_lcd_stat);
    register_io_read_handler(0xFF40, io_read_lcd_control);
    register_io_write_handler(0xFF40, io_write_lcd_control);

    UNUSED_IO_ADDR(0xFF42); /* SCY*/
    UNUSED_IO_ADDR(0xFF43); /* SCX*/
    UNUSED_IO_ADDR(0xFF4A); /* WY */
    UNUSED_IO_ADDR(0xFF4B); /* WX */
    UNUSED_IO_ADDR(0xFF47); /* Palette data */
}
