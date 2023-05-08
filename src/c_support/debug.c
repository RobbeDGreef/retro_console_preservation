#include <stdio.h>
#include <stdlib.h>
#include <stdint.h>
#include <string.h>

#include "rts.h"
#include "sail.h"
#include "support.h"

/* Sail stuff, defined in the generated output/main.c */
extern uint64_t zreg_AF;
extern uint64_t zreg_BC;
extern uint64_t zreg_DE;
extern uint64_t zreg_HL;
extern uint64_t zPC;
extern uint64_t zreg_SP;

#define AF zreg_AF
#define BC zreg_BC
#define DE zreg_DE
#define HL zreg_HL
#define PC zPC
#define SP zreg_SP

#define A ((AF >> 8) & 0xFF)
#define F ((AF >> 0) & 0xFF)
#define B ((BC >> 8) & 0xFF)
#define C ((BC >> 0) & 0xFF)
#define D ((DE >> 8) & 0xFF)
#define E ((DE >> 0) & 0xFF)
#define H ((HL >> 8) & 0xFF)
#define L ((HL >> 0) & 0xFF)

#define ZERO_FLAG (F & (1 << 7))
#define N_FLAG (F & (1 << 6))
#define HCARRY_FLAG (F & (1 << 5))
#define CARRY_FLAG (F & (1 << 4))

#define MAX_INP 256
#define MAX_BREAKPOINTS 32

#define LOOP_AGAIN 1
#define STOP_LOOPING 0

enum commands
{
    UNKNOWN,
    NOP,
    NEXT,
    REG,
    CONTINUE,
    EXIT,
    DELETE_BREAKPOINT,
    HELP,
    EXAMINE_MEM,
    ADD_BREAKPOINT,
};

int g_prev_command = CONTINUE;

/* Normally I would create a list or something but this will do for now */
int breakpoints[MAX_BREAKPOINTS] = {
    /* Eg: 0x150 */
};

static int is_at_breakpoint(unsigned long pc)
{
    for (int i = 0; i < MAX_BREAKPOINTS; i++)
    {
        if (pc == breakpoints[i])
            return 1;
    }

    return 0;
}

static void print_registers()
{
    printf("A: %02X\tF: %02X\t(AF: %04X)\n", A, F, AF);
    printf("B: %02X\tC: %02X\t(BC: %04X)\n", B, C, BC);
    printf("D: %02X\tE: %02X\t(DE: %04X)\n", D, E, DE);
    printf("H: %02X\tL: %02X\t(HL: %04X)\n", H, L, HL);
    printf("PC: %04X\tSP: %04X\n", PC, SP);
    printf("FLAGS: [%c%c%c%c]\n", ZERO_FLAG ? 'Z' : '-', N_FLAG ? 'N' : '-', HCARRY_FLAG ? 'H' : '-', CARRY_FLAG ? 'C' : '-');
}

static void delete_breakpoint(int breakpoint)
{
    /* Breakpoints start at 1 */
    breakpoint -= 1;

    if (!breakpoints[breakpoint])
    {
        printf("ERROR, breakpoint %i doesn't exist\n", breakpoint);
        return;
    }

    breakpoints[breakpoint] = 0;
}

static void add_breakpoint(int addr)
{
    int i;
    for (i = 0; i < MAX_BREAKPOINTS; i++)
    {
        if (!breakpoints[i] == 0)
            break;
    }

    breakpoints[i] = addr;
    printf("Created breakpoint #%i at %x\n", i, addr);
}

static void examine_memory(int mem)
{
    printf("%04X: %04X (%d)\n", mem, read_mem(mem) | (read_mem(mem + 1) << 8));
}

static int console()
{
    static char input[MAX_INP];

    /* Read input */
    printf(" > ");
    fflush(stdout);

    fgets(input, MAX_INP, stdin);

    input[strlen(input) - 1] = '\0'; /* Remove trailing newline */

    int cmd = NOP;

    if (strcmp(input, "") == 0)
    {
        cmd = g_prev_command;
    }
    else if (strncmp(input, "n", 1) == 0)
    {
        cmd = NEXT;
    }
    else if (strncmp(input, "r", 1) == 0)
    {
        cmd = REG;
    }
    else if (strncmp(input, "c", 1) == 0)
    {
        cmd = CONTINUE;
    }
    else if (strncmp(input, "e", 1) == 0)
    {
        cmd = EXIT;
    }
    else if (strncmp(input, "d", 1) == 0)
    {
        cmd = DELETE_BREAKPOINT;
    }
    else if (strncmp(input, "h", 1) == 0)
    {
        cmd = HELP;
    }
    else if (strncmp(input, "x", 1) == 0)
    {
        cmd = EXAMINE_MEM;
    }
    else if (strncmp(input, "b", 1) == 0)
    {
        cmd = ADD_BREAKPOINT;
    }
    else
    {
        cmd = UNKNOWN;
    }

    g_prev_command = cmd;

    switch (cmd)
    {
    case UNKNOWN:
        printf("Unknown command '%s'\n", input);
        return LOOP_AGAIN;
    case NEXT: /* fall through */
    case CONTINUE:
        return STOP_LOOPING;
    case REG:
        print_registers();
        return LOOP_AGAIN;
    case EXIT:
        exit(0);
        return STOP_LOOPING;
    case NOP:
        return LOOP_AGAIN;
    case EXAMINE_MEM:
        if (strlen(input) < 2 || strtol(input + 2, NULL, 0) == 0)
        {
            printf("ERROR, please specify a breakpoint");
            return LOOP_AGAIN;
        }
        examine_memory(strtol(input + 2, NULL, 0));
        return LOOP_AGAIN;
    case HELP:
        printf("n\t-\tNext instruction\n");
        printf("r\t-\tPrint registers\n");
        printf("c\t-\tContinue until next breakpoint\n");
        printf("e\t-\tExit\n");
        printf("d\t-\tDelete breakpoint (ex: d 1)\n");
        printf("h\t-\tShow this help screen\n");
        break;
    case DELETE_BREAKPOINT:
        if (strlen(input) < 2 || atoi(input + 2) == 0)
        {
            printf("ERROR, please specify a breakpoint");
            return LOOP_AGAIN;
        }

        delete_breakpoint(atoi(input + 2));
        return LOOP_AGAIN;
    case ADD_BREAKPOINT:
        if (strlen(input) < 2 || strtol(input + 2, NULL, 0) == 0)
        {
            printf("ERROR, please specify a location to break on");
            return LOOP_AGAIN;
        }

        add_breakpoint(strtol(input + 2, NULL, 0));
        return LOOP_AGAIN;
    }

    return LOOP_AGAIN;
}

/**
 * Called from sail every instruction.
 */
unit debug_hook(sail_int sail_pc)
{
    unsigned long pc = mpz_get_ui(sail_pc);

    if (g_prev_command == CONTINUE && !is_at_breakpoint(pc))
        return 0;

    if (is_at_breakpoint(pc))
        printf("Breakpoint reached %x\n", PC);

    while (console())
        ;

    return UNIT;
}

void debug_init()
{
}