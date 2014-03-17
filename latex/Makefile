ASPELL = 	aspell
PDFLATEX = 	pdflatex
BIBTEX = 	bibtex

LATEX  =	latex
DVIPS  =	dvips
PS2PDF = 	ps2pdf14 -dPDFSETTINGS=/prepress -dEmbedAllFonts=true 


all:		joern-docs.pdf

%.pdf:		%.tex
		$(PDFLATEX) $(basename $<)
		$(BIBTEX) $(basename $<)
		$(PDFLATEX) $(basename $<)
		$(PDFLATEX) $(basename $<)

spell: 		joern-docs.tex 
		env LANG=en $(ASPELL) --repl=./aspell.en.prepl --lang=en \
			--personal=./aspell.en.pws --sug-mode=normal -c \
			--mode=tex $<

clean:
	rm -f *~ *.log *.aux *.bbl *.out *.blg *.rel *.ps *.dvi
	rm -f *.pdf *.bak *.dvi *.gz
