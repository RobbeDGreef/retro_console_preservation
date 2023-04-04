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
val write : (address, word) -> unit
function write(addr, value) = custom_write_ram(32, 1, 32^0x0, EXTZ(addr), value)

val write16 : (address, dword) -> unit
function write16(addr, value) = custom_write_ram(32, 2, 32^0x0, EXTZ(addr), value)

val read : (address) -> word
function read(addr) = custom_read_ram(32, 1, 32^0x0, EXTZ(addr))

val read16 : (address) -> dword
function read16(addr) = custom_read_ram(32, 2, 32^0x0, EXTZ(addr))
