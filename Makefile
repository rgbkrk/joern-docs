all: joern-docs.pdf

%.pdf: %.md
	pandoc -f markdown $(basename $<).md -o $(basename $<).pdf

.PHONY: clean

clean:
	rm -f *~
	rm -f *.pdf
