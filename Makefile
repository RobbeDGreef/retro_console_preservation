SAIL_DIR ?= $(HOME)/.opam/4.13.1/share/sail
C_OUT_DIR = ./output
EMULATOR = emulator

C_SUPPORT_SOURCES = $(shell find src/c_support -name "*.c")
C_SUPPORT_HEADERS = src/c_support/

ROM ?= test_roms/mooneye-test-suite/build/acceptance/add_sp_e_timing.gb

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