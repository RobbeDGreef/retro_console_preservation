#ifndef __DEBUG_H
#define __DEBUG_H

#include <stdio.h>
#include <stdlib.h>

#define DEBUG 1
#define UNIMPLEMENTED(msg) do { printf("Unimplemented: %s\n", msg); exit(0); } while (0)

#endif /* __DEBUG_H */