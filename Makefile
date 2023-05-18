SAIL_DIR ?= $(HOME)/.opam/default/share/sail
C_OUT_DIR = ./output
EMULATOR = emulator
LATEX_OUT = latex_docs/
C_SUPPORT_SOURCES = $(shell find src/c_support -name "*.c")
C_SUPPORT_HEADERS = src/c_support/


# Whole bunch of other tests roms to test instructions individually

#ROM = test_roms/mooneye-test-suite/build/acceptance/div_timing.gb
#ROM = test_roms/mooneye-test-suite/build/acceptance/add_sp_e_timing.gb
#ROM = test_roms/mooneye-test-suite/build/acceptance/jp_timing.gb
#ROM = test_roms/mooneye-test-suite/build/acceptance/push_timing.gb
#ROM = test_roms/mooneye-test-suite/build/acceptance/ret_timing.gb
#ROM = test_roms/mooneye-test-suite/build/acceptance/oam_dma_timing.gb
#ROM = test_roms/mooneye-test-suite/build/acceptance/jp_cc_timing.gb
#ROM = test_roms/mooneye-test-suite/build/acceptance/call_cc_timing.gb
#ROM = test_roms/mooneye-test-suite/build/acceptance/call_cc_timing2.gb
#ROM = test_roms/gb-test-roms/cpu_instrs/individual/06-ldr,r.gb
#ROM = test_roms/mooneye-test-suite/build/acceptance/div_timing.gb

#ROM = test_roms/gb-test-roms/cpu_instrs/individual/01-special.gb
#ROM = test_roms/gb-test-roms/cpu_instrs/individual/03-opsp,hl.gb
#ROM = test_roms/mooneye-test-suite/build/acceptance/div_timing.gb
#ROM = test_roms/mooneye-test-suite/build/acceptance/pop_timing.gb
#ROM = test_roms/mooneye-test-suite/build/acceptance/call_timing.gb

#ROM = test_roms/mooneye-test-suite/build/acceptance/timer/div_write.gb
#ROM = test_roms/mooneye-test-suite/build/acceptance/timer/tim00.gb
#ROM = test_roms/mooneye-test-suite/build/acceptance/timer/tim01.gb
#ROM = test_roms/mooneye-test-suite/build/acceptance/timer/tim11.gb
#ROM = test_roms/mooneye-test-suite/build/acceptance/timer/tim10.gb
#ROM = test_roms/mooneye-test-suite/build/acceptance/timer/tim00_div_trigger.gb
#ROM = test_roms/mooneye-test-suite/build/acceptance/timer/tim01_div_trigger.gb
#ROM = test_roms/mooneye-test-suite/build/acceptance/timer/tim11_div_trigger.gb
#ROM = test_roms/mooneye-test-suite/build/acceptance/timer/tim10_div_trigger.gb
#ROM = test_roms/mooneye-test-suite/build/acceptance/timer/tima_reload.gb
#ROM = test_roms/gb-test-roms/interrupt_time/interrupt_time.gb

# Some game roms to test for fun

#ROM = test_roms/Tetris.gb
#ROM = test_roms/drmario.gb

# GB test roms
# ROM = test_roms/gb-test-roms/cpu_instrs/cpu_instrs.gb
#ROM = test_roms/gb-test-roms/instr_timing/instr_timing.gb
#ROM = test_roms/gb-test-roms/mem_timing/individual/01-read_timing.gb
#ROM = test_roms/gb-test-roms/mem_timing/individual/02-write_timing.gb
ROM = test_roms/gb-test-roms/mem_timing/individual/03-modify_timing.gb

# Individual CPU instr roms
# ROM = test_roms/gb-test-roms/cpu_instrs/individual/01-special.gb
# ROM = test_roms/gb-test-roms/cpu_instrs/individual/02-interrupts.gb
# ROM = test_roms/gb-test-roms/cpu_instrs/individual/03-opsp,hl.gb

.PHONY: build run

all: build

run_simple:
	$(MAKE) run ROM=test_roms/simple_increment_loop/simple.gb

run_helloworld:
	$(MAKE) run ROM=test_roms/hello_world/hello_world.gb

run: $(ROM)
	./$(EMULATOR) --binary=0x0,$<

build: $(EMULATOR)

docs:
	sail -o $(LATEX_OUT) -latex src/main.sail

c_files:
	sail -c -O src/main.sail -o $(C_OUT_DIR)/main -c_include "support.h" -c_no_main # -verbose 1 -dtc_verbose 1

$(EMULATOR): c_files
	gcc -Ofast -Wno-format -Werror $(C_OUT_DIR)/main.c $(C_SUPPORT_SOURCES) $(SAIL_DIR)/lib/*.c -lgmp -lz -lSDL2 -I $(C_SUPPORT_HEADERS) -I $(SAIL_DIR)/lib/ -o $(EMULATOR)

clean:
	rm $(C_OUT_DIR)/* -rf
	rm emulator