# Retro console preservation with sail

## Building test ROM

The test roms will include a makefile that builds the rom file for you.

Alternatively,
[The following document contains all the necessary information](https://gbdev.io/gb-asm-tutorial/part1/hello_world.html) if you need
#to compile manually

## Building

Generate C emulator with

    sail -c src/main.sail > output/out.c

Then compile the emulator with

    gcc output/out.c $SAIL_DIR/lib/*.c -lgmp -lz -I $SAIL_DIR/lib/ -o emulator

Sail directory will in most cases be the path

    /home/robbe/.opam/<switch>/share/sail

    export SAIL_DIR=/home/robbe/.opam/4.13.1/share/sail

## Running third party gameboy emulator

    wine64 ./third_party_emulator/bgb.exe

## Gameboy assembler

According to [this](https://www.chibiakumas.com/z80/Gameboy.php) document the [VASM assembler](http://sun.hasenbraten.de/vasm/)
can compile gameboy assembly written in Z80 syntax (despite the gameboy not having a z80 
cpu).

However [rgbds](https://rgbds.gbdev.io/) is also a possibility and seems to be more widely used.
To install rgbds follow the instructions in [this](https://rgbds.gbdev.io/install) document. 

## Links

[Detailed GameBoy documentation](https://github.com/Gekkio/gb-ctr)
[Concise GameBoy (+ advance + color) documentation](https://gbdev.io/pandocs/)
[Some test roms](https://gbdev.gg8.se/wiki/articles/Test_ROMs)
[Thesis proposal](https://dinf.vub.ac.be/bthesis/?proposal=proposals%2FSOFT-Retro+console+preservation+and+emulation+with+Sail)
[Gameboy asm tutorial](https://eldred.fr/gb-asm-tutorial/index.html)
[Gameboy technical reference](https://gekkio.fi/files/gb-docs/gbctr.pdf)

### Papers

[QEMU, a Fast and Portable Dynamic Translator](https://www.usenix.org/legacy/event/usenix05/tech/freenix/full_papers/bellard/bellard.pdf)
[Efficient embedded software development using QEMU](https://static.lwn.net/lwn/images/conf/rtlws11/papers/proc/p09.pdf)
[Optimizing Control Transfer and Memory Virtualization in Full System Emulators](https://dl.acm.org/doi/pdf/10.1145/2837027)
[Optimizing Memory Translation Emulation in Full System Emulators](https://dl.acm.org/doi/pdf/10.1145/2686034)
[Fast cycle estimation methodology for instruction level emulation](https://ieeexplore.ieee.org/document/6176470)

### Examples
[RISCV in sail, handwritten](https://github.com/riscv/sail-riscv)


## CPU information
### Registers
| 16-bit | High bits | Low bits | Name
| ------ | --------- | -------- | ---- 
| AF     | A         | -        | Accumulator and flags  
| BC     | B         | C        | BC                     
| DE     | D         | E        | DE                     
| HL     | H         | L        | HL                     
| SP     | -         | -        | Stack pointer          
| PC     | -         | -        | Program counter        

### Most important instructions
| Mnemonic          | 16-bit | Encoding | Description
| ----------------- | ------ | -------- | -----------
| push      rr      | yes    | x5       | SP=SP-2  (SP)=rr ; rr may be BC,DE,HL,AF
| pop       rr      | yes    | x1       | rr=(SP)  SP=SP+2 ; rr may be BC,DE,HL,AF
| ld        r,r     | no     | xx       | r=r
| ld        r,n     | no     | xx nn    | r=n
| ld        rr,nn   | yes    | x1 nn nn | rr=nn (rr may be BC,DE,HL or SP)
| add       A,r     | no     | 8x       | A=A+r
| add       A,n     | no     | 6c nn    | A=A+n
| sub       r       | no     | 9x       | A=A-r
| sub       n       | no     | D6 nn    | A=A-n
| cp        r       | no     | Bx       | compare A-r
| cp        n       | no     | FE nn    | compare A-n
| jp        nn      | -      | C3 nn nn | Jump to nn (PC=nn)
| jp        f,nn    | -      | xx nn nn | Conditional jump if nz, z, nc, c
| jr        PC+dd   | -      | 18 dd    | Relative jump to nn (PC=PC+nn)
| jr        f,PC+dd | -      | xx dd    | Relative jump to nn (PC=PC+nn) if nz, z, nc, c
| call      nn      | -      | CD nn nn | Call to nn, SP=Sp-2 (SP) = PC, PC=nn
| call      f,nn    | -      | xx nn nn | Call to nn, SP=Sp-2 (SP) = PC, PC=nn (conditional)
| ret               | -      | C9       | Return, PC=(SP) SP=SP+2

## Todo
- write a dockerfile with a pinned specific version of sail
