SAIL_DIR ?= $(HOME)/.opam/4.13.1/share/sail
C_OUT_DIR = ./output
EMULATOR = emulator

.PHONY: build run

all: build

run:
	./$(EMULATOR)

build: $(EMULATOR)

c_files:
	sail -c src/main.sail -o $(C_OUT_DIR)/main -verbose 1 -dtc_verbose 1

$(EMULATOR): c_files
	gcc -O3 $(C_OUT_DIR)/main.c $(SAIL_DIR)/lib/*.c -lgmp -lz -I $(SAIL_DIR)/lib/ -o $(EMULATOR)

clean:
	rm $(C_OUT_DIR)/* -rf
	rm emulator