SHELL := /bin/sh

## Directories
## ================================================================================

src-dirs := \
	01-vote \
	02-bwght \
	03-hprice1 \
	04-loanapp \
	05-wagegap \
	06-cons \
	07-unemp


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
org-to-latex := --eval "(org-latex-export-to-latex)"

LATEX_MESSAGES := no
TEXI2DVI_FLAGS := --batch --pdf --build=tidy

ifneq ($(LATEX_MESSAGES), yes)
TEXI2DVI_FLAGS += -q
endif

TEXI2DVI := $(envbin) TEXI2DVI_USE_RECORDER=yes \
	$(texi2dvibin) $(TEXI2DVI_FLAGS)



bare-name = $(lastword $(subst -, ,$(1)))

org-files := $(foreach dir,$(src-dirs),$(dir)/$(call bare-name,$(dir))-instr.org)
tex-files := $(patsubst %.org,%.tex,$(org-files))
pdf-files := $(patsubst %.org,%.pdf,$(org-files))

zip-files := $(foreach dir,$(src-dirs),$(dir)/$(call bare-name,$(dir)).zip)

build-dirs := $(join $(dir $(org-files)),\
	$(foreach dir,$(src-dirs),$(dir)!$(call bare-name,$(dir))-instr.t2d))

VPATH := $(src-dirs)


all: $(zip-files)

.PRECIOUS: %.tex
%.tex: %.org setup.org setup-emacs.el
	$(EMACS) --load=./setup-emacs.el --visit=$< $(org-to-latex)

.PRECIOUS: %.pdf
%.pdf: %.tex
	$(TEXI2DVI) --build-dir=$(@D) --output=$@ $<

%.zip: %-instr.pdf
	./make-zip -o $@ -d $(call bare-name,$(@D)) $^


01-vote/vote.zip: vote.gdt

02-bwght/bwght.zip: bwght.gdt

03-hprice1/hprice1.zip: hprice1.gdt

04-loanapp/loanapp.zip: loanapp.csv

05-wagegap/wagegap.zip: esp.csv

06-cons/cons.zip: cons.csv
06-cons/cons-instr.pdf: awm.bib

07-unemp/unemp.zip: unemp.csv
07-unemp/unemp-instr.pdf: unemp.bib


## Cleaning rules
## --------------------------------------------------------------------------------
.PHONY: clean
clean:
	-@rm $(pdf-files)
	-@rm $(tex-files)
	-@rm $(zip-files)

.PHONY: veryclean
veryclean: clean
	-@rm -r $(build-dirs)
