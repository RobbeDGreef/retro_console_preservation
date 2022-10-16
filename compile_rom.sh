#!/bin/bash

# input argument is the asm file
# output is asm file with extension .gb

filename="${1%.*}"
rgbasm -L -o "${filename}.o" $1
rgblink -o "${filename}.gb" "${filename}.o"
rgbfix -v -p 0xFF "${filename}.gb"