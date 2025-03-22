SHELL := /bin/sh

## Directories
## ================================================================================

rootdir := .


## Programs
## ================================================================================

emacsbin := /usr/bin/emacs
texi2dvibin := /usr/bin/texi2dvi
envbin  := /usr/bin/env
pythonbin := /usr/bin/python3
Rscriptbin := /usr/local/bin/Rscript

-include local.mk

## Variables
## ================================================================================
EMACS := $(emacsbin) -Q -nw --batch

org-to-pdf := --eval "(org-latex-export-to-pdf)"

src-dirs := \
	01-vote \
	02-bwght \
	03-hprice1 \
	04-loanapp \
	05-wagegap \
	06-cons

bare-name = $(lastword $(subst -, ,$(1)))

org-files := $(foreach dir,$(src-dirs),$(dir)/$(call bare-name,$(dir))-instr.org)
pdf-files := $(patsubst %.org,%.pdf,$(org-files))

zip-files := $(foreach dir,$(src-dirs),$(dir)/$(call bare-name,$(dir)).zip)

VPATH := $(src-dirs)


all: $(zip-files)

%.pdf: %.org setup.org setup-emacs.el
	$(EMACS) --load=./setup-emacs.el --visit=$< $(org-to-pdf)

%.zip: %-instr.pdf
	./make-zip -o $@ -d $(call bare-name,$(@D)) $^

%.bbl: %.aux
	bibtex $<

## Cleaning rules
## --------------------------------------------------------------------------------
.PHONY: clean
clean:
	-@rm $(pdf-files)
	-@rm $(zip-files)


01-vote/vote.zip: vote.gdt

02-bwght/bwght.zip: bwght.gdt

03-hprice1/hprice1.zip: hprice1.gdt

04-loanapp/loanapp.zip: loanapp.csv

05-wagegap/wagegap.zip: esp.csv

06-cons/cons.zip: cons.csv

# TODO: org compiles pdf and removes aux file. That file is needed to
# rebuild the bibliography if the bib file changes. So, bibliography is
# not updated when the bib file changes.
06-cons/cons-instr.pdf: cons-instr.bbl
06-cons/cons-instr.bbl: awm.bib
