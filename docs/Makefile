LATEX_OUT = instructions/
LATEX_ARGS = -interaction nonstopmode -file-line-error

all: gameboy.pdf

gameboy.pdf:
	sail -o $(LATEX_OUT) -latex ../src/main.sail
	python3 gendocs.py $(LATEX_OUT) ./gameboy.tex
	pdflatex ${LATEX_ARGS} gameboy.tex
	pdflatex ${LATEX_ARGS} gameboy.tex

clean:
	rm -rf gameboy.out gameboy.tex gameboy.log gameboy.toc instructions/ gameboy.pdf