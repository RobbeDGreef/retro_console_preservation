LATEX_OUT = instructions/

all: gameboy.pdf

gameboy.pdf:
	sail -o $(LATEX_OUT) -latex ../src/main.sail
	python3 gendocs.py $(LATEX_OUT) ./gameboy.tex
	pdflatex gameboy.tex