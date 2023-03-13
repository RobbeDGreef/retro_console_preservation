FILES = hello_world.asm
NAME = hello_world

RGBASM = rgbasm
RGBLINK = rgblink
RGBFIX = rgbfix

ROM = $(NAME).gb
ROM_OBJ = $(NAME).o


$(ROM): $(ROM_OBJ)
	$(RGBLINK) -o $@ $<
	$(RGBFIX) -v -p 0xFF $@

$(ROM_OBJ): ${FILES}
	$(RGBASM) -L -o $@ $<