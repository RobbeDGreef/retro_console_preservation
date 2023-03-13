SAIL_DIR ?= $(HOME)/.opam/4.13.1/share/sail
C_OUT_DIR = ./output
EMULATOR = emulator

C_SUPPORT_SOURCES = $(shell find src/c_support -name "*.c")
C_SUPPORT_HEADERS = src/c_support/

.PHONY: build run

all: build

run:
	./$(EMULATOR)

build: $(EMULATOR)

c_files:
	sail -c src/main.sail -o $(C_OUT_DIR)/main -c_include "support.h" # -verbose 1 -dtc_verbose 1

$(EMULATOR): c_files
	gcc -O3 $(C_OUT_DIR)/main.c $(C_SUPPORT_SOURCES) $(SAIL_DIR)/lib/*.c -lgmp -lz -I $(C_SUPPORT_HEADERS) -I $(SAIL_DIR)/lib/ -o $(EMULATOR)

clean:
	rm $(C_OUT_DIR)/* -rf
	rm emulator