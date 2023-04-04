/**
 * These custom functions are implemented in memory.c
 */

/* custom_write_ram(address_size, nr_of_bytes, hex_ram, address, data) */
val custom_write_ram = "custom_write_ram" : forall 'n 'm.
  (atom('m), atom('n), bits('m), bits('m), bits(8 * 'n)) -> unit

/* custom_read_ram(address_size, nr_of_bytes, hex_ram, address) */
val custom_read_ram = "custom_read_ram" : forall 'n 'm.
  (atom('m), atom('n), bits('m), bits('m)) -> bits(8 * 'n)


/**
 * Memory addresses always need to be 32 or 64 bit. To abstract this from the code
 * we simply zero extend in the memw and memr functions.
 */
val MEMw : (address, word) -> unit
function MEMw(addr, value) = write_ram(32, 1, 32^0x0, EXTZ(addr), value)

val MEMw16 : (address, dword) -> unit
function MEMw16(addr, value) = write_ram(32, 2, 32^0x0, EXTZ(addr), value)

val MEMr : address -> word
function MEMr(addr) = read_ram(32, 1, 32^0x0, EXTZ(addr))

val MEMr16 : (address) -> dword
function MEMr16(addr) = read_ram(32, 2, 32^0x0, EXTZ(addr))
