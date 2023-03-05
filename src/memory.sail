
/* write_ram(address_size, nr_of_bytes, hex_ram, address, data) */
val write_ram = "write_ram" : forall 'n 'm.
  (atom('m), atom('n), bits('m), bits('m), bits(8 * 'n)) -> unit

/* read_ram(address_size, nr_of_bytes, hex_ram, address) */
val read_ram = "read_ram" : forall 'n 'm.
  (atom('m), atom('n), bits('m), bits('m)) -> bits(8 * 'n)


/**
 * Memory addresses always need to be 32 or 64 bit. To abstract this from the code
 * we simply zero extend in the memw and memr functions.
 */
val MEMw : (address, word) -> unit
function MEMw(addr, value) = write_ram(32, 1, 32^0x0, EXTZ(addr), value)

val MEMr : address -> word
function MEMr(addr) = read_ram(32, 1, 32^0x0, EXTZ(addr))

val MEMri : address -> word