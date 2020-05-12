
main_source = main.tex
target = main.pdf


all: doc

doc: $(target)

$(target): *.tex
	pdflatex --shell-escape $(main_source)

latex_generated = *.aux *.toc *.out *.log *.gz *.lof *.bbl *.blg *.glo *.glsdefs *.ist

clean:
	rm -f $(target) $(latex_generated)
