SHELL := /bin/sh

## Source files
## ================================================================================
src-files := \
	vote.org \
	bwght.org \
	hprice1.org \
	loanapp.org \
	wagegap.org \
	cons.org \
	unemp.org

## Directories
## ================================================================================

root-dir := .
org-dir := $(root-dir)/org
build-dir := $(root-dir)/build
data-dir := $(root-dir)/data
pdf-dir := $(root-dir)/pdf
R-dir := $(root-dir)/R
tex-dir := $(root-dir)/tex
zip-dir := $(root-dir)/zip


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
USE_LUALATEX := no


## emacs ---------------------------------------------
EMACS := $(emacsbin) -Q -nw --batch
# org-to-pdf := --eval "(org-latex-export-to-pdf)"
# org-to-latex := --eval "(org-latex-export-to-latex)"


## latexmk -----------------------------------------
LATEX_ENGINE := -pdf
ifeq ($(USE_LUALATEX), yes)
LATEX_ENGINE := -lualatex
endif

LATEXMK_FLAGS := $(LATEX_ENGINE) -cd -nobibfudge
# -emulate-aux-dir

ifneq ($(LATEX_MESSAGES), yes)
LATEXMK_FLAGS += -quiet
endif

LATEXMK := $(envbin) TEXINPUTS=$(build-dir)/:$(data-dir)/: \
	BIBINPUTS=$(abspath $(root-dir)): \
	$(latexmkbin) $(LATEXMK_FLAGS)


## Targets ----------------------------------------

org-files := $(addprefix $(org-dir)/,$(src-files))
tex-files := $(addprefix $(build-dir)/,$(patsubst %.org,%.tex,$(src-files)))
pdf-files := $(addprefix $(pdf-dir)/,$(patsubst %.org,%.pdf,$(src-files)))
zip-files := $(addprefix $(zip-dir)/,$(patsubst %.org,%.zip,$(src-files)))


tex-deps := $(root-dir)/setup.org $(root-dir)/setup-emacs.el

pdf-deps := $(build-dir)/preamble.tex

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


$(build-dir)/%.pdf: $(build-dir)/%.tex $(pdf-deps) | $(build-dir)
	$(LATEXMK) $<

.PRECIOUS: $(pdf-dir)/%.pdf
$(pdf-dir)/%.pdf: $(build-dir)/%.pdf | $(pdf-dir)
	$(MV) $< $@

$(build-dir)/preamble.tex: $(root-dir)/preamble.tex | $(build-dir)
	$(CP) $< $@


%.zip: %-instr.pdf
	./make-zip -o $@ -d $(call bare-name,$(@D)) $^

$(pdf-dir)/cons.pdf: $(root-dir)/labs.bib


$(pdf-dir)/unemp.pdf: $(root-dir)/labs.bib


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
