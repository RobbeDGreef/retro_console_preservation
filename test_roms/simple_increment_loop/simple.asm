INCLUDE "hardware.inc"

SECTION "Header", ROM0[$100]

	jp entry_point

	ds $150 - @, 0 ; Make room for the header

entry_point:
	ld a, 0

inc_loop:
	add a, 1
	jp inc_loop