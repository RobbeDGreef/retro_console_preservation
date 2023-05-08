#include "sail.h"

#define PRINT_CYCLES 1

#define BLUE "\033[36;1m"
#define END "\033[m"

unit print_instruction(const sail_int addr, const sail_string assembly, sail_int passed_cycles)
{
    printf("%04x\t" BLUE "%s" END
#if PRINT_CYCLES
           "\t[cycle: %lu]"
#endif
           "\n",
           mpz_get_ui(addr), assembly, mpz_get_ui(passed_cycles));
    return UNIT;
}

unit print_string(sail_string s1, sail_string s2)
{
    printf("%s %s\n", s1, s2);
    return UNIT;
}