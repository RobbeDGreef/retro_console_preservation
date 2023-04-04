#include "sail.h"

unit print_instruction(const sail_int addr, const sail_string assembly)
{
    printf("%04x\t%s\n", mpz_get_ui(addr), assembly);
    return UNIT;
}

unit print_string(sail_string s1, sail_string s2)
{
    printf("%s %s\n", s1, s2);
    return UNIT;
}