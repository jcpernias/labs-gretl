SHELL := /bin/sh

## Source files
## ================================================================================
src-files := \
	vote \
	bwght \
	hprice1 \
	loanapp \
	wagegap \
	wagegap-sol \
	cons \
	unemp \
	unemp-sol \
	phillips \
	phillips-sol \
	exports \
	exports-sol \
	traffic2

ans-files := hprice1

## Directories
## ================================================================================

root-dir := .
org-dir := $(root-dir)/org
build-dir := $(root-dir)/build
data-dir := $(root-dir)/data
pdf-dir := $(root-dir)/pdf
R-dir := $(root-dir)/R
gretl-dir := $(root-dir)/gretl
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


## latexmk -----------------------------------------
LATEX_ENGINE := -pdf
ifeq ($(USE_LUALATEX), yes)
LATEX_ENGINE := -lualatex
endif

LATEXMK_FLAGS := $(LATEX_ENGINE) -cd -nobibfudge

ifneq ($(LATEX_MESSAGES), yes)
LATEXMK_FLAGS += -quiet
endif

LATEXMK := $(envbin) TEXINPUTS=$(build-dir)/:$(data-dir)/: \
	$(latexmkbin) $(LATEXMK_FLAGS)

## Rscript -----------------------------------------

RSCRIPT := $(Rscriptbin)


## Targets ----------------------------------------
org-files := $(addprefix $(org-dir)/,$(addsuffix .org,$(src-files)))
tex-files := $(addprefix $(build-dir)/,$(addsuffix .tex,$(src-files)))
pdf-files := $(addprefix $(pdf-dir)/,\
	$(addsuffix .pdf,$(src-files) $(addsuffix -ans, $(ans-files))))
zip-files := $(addprefix $(zip-dir)/,\
	$(addsuffix .zip,$(filter-out %-sol,$(src-files))))


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

# $(call ans-tex,texfile) -> write to a file
define ans-tex
\RequirePackage{etoolbox}
\providebool{answers}
\booltrue{answers}
\input{$(realpath $(build-dir))/$1}
endef


all: $(zip-files) $(filter %-sol.pdf,$(pdf-files)) $(filter %-ans.pdf,$(pdf-files))

## From .org to .tex
.PRECIOUS: $(build-dir)/%.tex
$(build-dir)/%.tex: $(org-dir)/%.org $(tex-deps) | $(build-dir)
	$(EMACS) --load=./setup-emacs.el --visit=$< \
		--eval '(org-to-latex "$(call dir-path,$@)")'

## From .tex to -ans.tex
.PRECIOUS: $(build-dir)/%-ans.tex
$(build-dir)/%-ans.tex: $(build-dir)/%.tex
	$(file > $@,$(call ans-tex,$*))

## From .tex to .pdf
$(build-dir)/%.pdf: $(build-dir)/%.tex $(pdf-deps) | $(build-dir)
	$(LATEXMK) $<

## Move .pdf to pdf dir
.PRECIOUS: $(pdf-dir)/%.pdf
$(pdf-dir)/%.pdf: $(build-dir)/%.pdf | $(pdf-dir)
	$(MV) $< $@

## Copy preamble.tex to build dir
$(build-dir)/preamble.tex: $(root-dir)/preamble.tex | $(build-dir)
	$(CP) $< $@

## Make zip file
$(zip-dir)/%.zip: $(pdf-dir)/%.pdf | $(zip-dir)
	./make-zip -o $@ -d $(basename $(@F)) $^



## hprice1 gretl output ----------------------------------------
hprice1-gretl-output := $(addsuffix .txt,\
  $(addprefix $(build-dir)/hprice1-,a b c1 c2 d1 d2 e1 e2))

$(hprice1-gretl-output): hprice1-gretl-output.intermediate
	@:

.INTERMEDIATE: hprice1-gretl-output.intermediate
hprice1-gretl-output.intermediate: \
	$(gretl-dir)/hprice1.inp $(data-dir)/hprice1.csv
	gretlcli -b -e $<

$(pdf-dir)/hprice1-sol.pdf: $(hprice1-gretl-output)


## wagegap gretl output -----------------------------------------
wagegap-gretl-output := $(addsuffix .txt,\
  $(addprefix $(build-dir)/wagegap-,a b c d e))

$(wagegap-gretl-output): wagegap-gretl-output.intermediate
	@:

.INTERMEDIATE: wagegap-gretl-output.intermediate
wagegap-gretl-output.intermediate: \
	$(gretl-dir)/wagegap.inp $(data-dir)/esp.csv
	gretlcli -b -e $<

$(pdf-dir)/wagegap-sol.pdf: $(wagegap-gretl-output)

# unemp gretl output -----------------------------------------
unemp-gretl-output := \
	$(addsuffix .txt,\
		$(addprefix $(build-dir)/unemp-, \
			static covid dl dyn-mult lr-mult cum-mult nat-rate)) \
	$(addsuffix .pdf,\
		$(addprefix $(build-dir)/unemp-,\
			d_unemp gY gYalt uhat corrgm-1))


$(unemp-gretl-output): unemp-gretl-output.intermediate
	@:

.INTERMEDIATE: unemp-gretl-output.intermediate
unemp-gretl-output.intermediate: \
	$(gretl-dir)/unemp.inp $(data-dir)/unemp.csv
	gretlcli -b -e $<

$(pdf-dir)/unemp-sol.pdf: $(unemp-gretl-output)


# phillips figure -----------------------------------------------
$(pdf-dir)/phillips.pdf: $(build-dir)/phillips-fig.csv
$(build-dir)/phillips-fig.csv: \
	$(gretl-dir)/phillips-fig.inp $(data-dir)/phillips.csv
	gretlcli -b -e $<

# phillips gretl output -----------------------------------------
phillips-gretl-output := \
	$(addsuffix .txt,\
		$(addprefix $(build-dir)/phillips-, \
			adf-infl adf-d_infl adf-paro adf-paroc \
			static lags dyn lr-mult lr-mult-0)) \
	$(addsuffix .pdf,\
		$(addprefix $(build-dir)/phillips-,infl d_infl paro paroc))


$(phillips-gretl-output): phillips-gretl-output.intermediate
	@:

.INTERMEDIATE: phillips-gretl-output.intermediate
phillips-gretl-output.intermediate: \
	$(gretl-dir)/phillips.inp $(data-dir)/phillips.csv
	gretlcli -b -e $<

$(pdf-dir)/phillips-sol.pdf: $(phillips-gretl-output)


# exports gretl output -----------------------------------------
exports-gretl-output := \
	$(addsuffix .txt,\
		$(addprefix $(build-dir)/exports-, \
			adf-lx adf-gx adf-ly adf-gy \
			lags dl dyn-mult ardl mult cum-mult chow)) \
	$(addsuffix .pdf,\
		$(addprefix $(build-dir)/exports-,ly gy lx gx))


$(exports-gretl-output): exports-gretl-output.intermediate
	@:

.INTERMEDIATE: exports-gretl-output.intermediate
exports-gretl-output.intermediate: \
	$(gretl-dir)/exports.inp $(data-dir)/exports.csv
	gretlcli -b -e $<

$(pdf-dir)/exports-sol.pdf: $(exports-gretl-output)


# traffic2 gretl output -----------------------------------------
traffic2-gretl-output := \
	$(addsuffix .txt,\
		$(addprefix $(build-dir)/traffic2-, \
			adf-l_total adf-unem \
			mco seas rho1 bgaux bgaux-hc bgaux-ar2 bg-ar2 pw)) \
	$(addsuffix .pdf,\
		$(addprefix $(build-dir)/traffic2-,l_total unem))


$(traffic2-gretl-output): traffic2-gretl-output.intermediate
	@:

.INTERMEDIATE: traffic2-gretl-output.intermediate
traffic2-gretl-output.intermediate: \
	$(gretl-dir)/traffic2.inp $(data-dir)/traffic2.csv
	gretlcli -b -e $<

$(pdf-dir)/traffic2.pdf: $(traffic2-gretl-output)



# bibliography ---------------------------------------------------
$(pdf-dir)/cons.pdf: $(root-dir)/labs.bib
$(pdf-dir)/unemp.pdf: $(root-dir)/labs.bib

# data files -----------------------------------------------------
$(zip-dir)/vote.zip: $(data-dir)/vote.csv
$(zip-dir)/bwght.zip: $(data-dir)/bwght.gdt
$(zip-dir)/hprice1.zip: $(data-dir)/hprice1.csv
$(zip-dir)/loanapp.zip: $(data-dir)/loanapp.csv
$(zip-dir)/wagegap.zip: $(data-dir)/esp.csv
$(zip-dir)/cons.zip: $(data-dir)/cons.csv
$(zip-dir)/unemp.zip: $(data-dir)/unemp.csv
$(zip-dir)/phillips.zip: $(data-dir)/phillips.csv
$(zip-dir)/exports.zip: $(data-dir)/exports.csv
$(zip-dir)/traffic2.zip: $(data-dir)/traffic2.csv


## Create directories
## --------------------------------------------------------------------------------

$(build-dir) $(pdf-dir) $(zip-dir):
	mkdir $@


## Cleaning rules
## --------------------------------------------------------------------------------
.PHONY: clean
clean:
	-@rm -r $(pdf-dir)
	-@rm -r $(zip-dir)


.PHONY: veryclean
veryclean: clean
	-@rm -r $(build-dir)


# Local Variables:
# mode: makefile-gmake
# eval: (flyspell-mode -1)
# End:
