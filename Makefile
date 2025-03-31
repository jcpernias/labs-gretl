SHELL := /bin/sh

## Source files
## ================================================================================
src-files := \
	vote.org \
	bwght.org \
	hprice1.org \
	loanapp.org \
	wagegap.org \
	cons.org

## Directories
## ================================================================================

<<<<<<< HEAD
src-dirs := \
	01-vote \
	02-bwght \
	03-hprice1 \
	04-loanapp \
	05-wagegap \
	06-cons \
	07-unemp
||||||| parent of c0d06df (Build tex files from org sources)
src-dirs := \
	01-vote \
	02-bwght \
	03-hprice1 \
	04-loanapp \
	05-wagegap \
	06-cons
=======

root-dir := .
org-dir := $(root-dir)/org
build-dir := $(root-dir)/build
data-dir := $(root-dir)/data
pdf-dir := $(root-dir)/pdf
R-dir := $(root-dir)/R
tex-dir := $(root-dir)/tex
zip-dir := $(root-dir)/zip
>>>>>>> c0d06df (Build tex files from org sources)


## Programs
## ================================================================================

emacsbin := /usr/bin/emacs
texi2dvibin := /usr/bin/texi2dvi
envbin  := /usr/bin/env
pythonbin := /usr/bin/python3
Rscriptbin := /usr/local/bin/Rscript
latexmkbin := /Library/TeX/texbin/latexmk

-include local.mk

## Variables
## ================================================================================

## Print info ----------------------------------------
LATEX_MESSAGES := no
PRINT_INFO := no


## emacs ---------------------------------------------
EMACS := $(emacsbin) -Q -nw --batch
# org-to-pdf := --eval "(org-latex-export-to-pdf)"
# org-to-latex := --eval "(org-latex-export-to-latex)"


## texi2dvi -----------------------------------------
TEXI2DVI_FLAGS := --batch --pdf --build=tidy

# -I $(dir $(abspath $(root-dir)))

ifneq ($(LATEX_MESSAGES), yes)
TEXI2DVI_FLAGS += -q
endif

TEXI2DVI := $(envbin) TEXINPUTS=$(build-dir)/:$(data-dir)/:$(root-dir)/: \
	TEXI2DVI_USE_RECORDER=yes \
	$(texi2dvibin) $(TEXI2DVI_FLAGS)


## Targets ----------------------------------------

org-files := $(addprefix $(org-dir)/,$(src-files))
tex-files := $(addprefix $(build-dir)/,$(patsubst %.org,%.tex,$(src-files)))
pdf-files := $(addprefix $(pdf-dir)/,$(patsubst %.org,%.pdf,$(src-files)))
zip-files := $(addprefix $(zip-dir)/,$(patsubst %.org,%.zip,$(src-files)))


tex-deps := $(root-dir)/setup.org $(root-dir)/setup-emacs.el

pdf-deps := $(root-dir)/preamble.tex

VPATH := $(build-dirs)

dir-path = $(dir $(abspath $(1)))


ifeq ($(PRINT_INFO), yes)
$(info src-files: $(src-files))
$(info org-files: $(org-files))
$(info tex-files: $(tex-files))
$(info pdf-files: $(pdf-files))
$(info zip-files: $(zip-files))
endif


all: $(pdf-files)


.PRECIOUS: $(build-dir)/%.tex
$(build-dir)/%.tex: $(org-dir)/%.org $(tex-deps) | $(build-dir)
	$(EMACS) --load=./setup-emacs.el --visit=$< \
		--eval '(org-to-latex "$(call dir-path,$@)")'


.PRECIOUS: $(pdf-dir)/%.pdf
$(pdf-dir)/%.pdf: $(build-dir)/%.tex $(pdf-deps) | $(pdf-dir)
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


## Create directories
## --------------------------------------------------------------------------------

$(build-dir) $(pdf-dir):
	mkdir $@


## Cleaning rules
## --------------------------------------------------------------------------------
.PHONY: clean
clean:
	-@rm -r $(pdf-dir)

.PHONY: veryclean
veryclean: clean
	-@rm -r $(build-dir)


# Local Variables:
# mode: makefile-gmake
# eval: (flyspell-mode -1)
# End:
