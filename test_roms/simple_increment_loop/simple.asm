INCLUDE "hardware.inc"

SECTION "Header", ROM0[$100]

	jp entry_point

	ds $150 - @, 0 ; Make room for the header

entry_point:
	ld a, 0
	ld b, 1
	ld c, 2
	ld d, 3
	ld e, 4
	ld h, 5
	ld l, 6

inc_loop:
	add a, 1
	jp inc_loop