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


org-files := \
	01-vote/vote-instr.org \
	02-bwght/bwght-instr.org \
	03-hprice1/hprice1-instr.org \
	04-loanapp/loanapp-instr.org \
	05-wagegap/wagegap-instr.org \
	06-cons/cons-instr.org

pdf-files := $(patsubst %.org,%.pdf,$(org-files))


all: $(pdf-files)


%.pdf: %.org setup.org setup-emacs.el
	$(EMACS) --load=./setup-emacs.el --visit=$< $(org-to-pdf)

01-vote/vote.zip: 01-vote/vote-instr.pdf 01-vote/vote.gdt
	./make-zip -o $@ -d $(lastword $(subst -, ,$(@D))) $^
