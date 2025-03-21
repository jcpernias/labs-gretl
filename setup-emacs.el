(require 'org)

;; Export settings
;; --------------------------------------------------------------------------------

(setq org-list-allow-alphabetical t)

;; Allow opening question or exclamation marks before emphasis
;; Allow matches spanning 5 lines
(setcar org-emphasis-regexp-components " \t('\"{¿¡[")
(setcar (nthcdr 4 org-emphasis-regexp-components) 2)
(org-set-emph-re 'org-emphasis-regexp-components org-emphasis-regexp-components)

;; Babel
;; --------------------------------------------------------------------------------

(defun my-org-confirm-babel-evaluate (lang body)
  (not (string-match "^\\(R\\|emacs-lisp\\)$" lang)))
(setq org-confirm-babel-evaluate 'my-org-confirm-babel-evaluate)
(setq ess-ask-for-ess-directory nil)
(org-babel-do-load-languages
 'org-babel-load-languages
 '((emacs-lisp . t)
   (shell . t)
   (R . t)
   (python . t)
   (latex . t)
   (ditaa . t)))

(add-to-list 'org-src-lang-modes
   '("r" . R))
