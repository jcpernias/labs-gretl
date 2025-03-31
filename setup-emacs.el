(require 'package)
(package-initialize)

;; Export settings
;; --------------------------------------------------------------------------------
(require 'ox)
(setq org-list-allow-alphabetical t)

;; Allow opening question or exclamation marks before emphasis
;; Allow matches spanning 5 lines
(setcar org-emphasis-regexp-components " \t('\"{¿¡[")
(setcar (nthcdr 4 org-emphasis-regexp-components) 2)
(org-set-emph-re 'org-emphasis-regexp-components org-emphasis-regexp-components)

;; Recalculate tables before export
(defun tables-recalc (backend)
    (org-table-recalculate-buffer-tables))

;; (add-hook 'org-export-before-processing-hook #'tables-recalc)
(add-hook 'org-export-before-parsing-hook #'tables-recalc)

;; Babel
;; --------------------------------------------------------------------------------
(defun my-org-confirm-babel-evaluate (lang body)
  (not (string-match "^\\(R\\|emacs-lisp\\|latex\\)$" lang)))
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


;; Evaluate buffer
(defun eval-org-buffer (dir)
  "Export current org buffer to a latex file in directory DIR."
  (interactive "DDirectory: ")
  (org-export-expand-include-keyword)
  ;; (find-file (expand-file-name file))
  (cd (expand-file-name dir))
  (org-babel-execute-buffer))


;; Export functions
;; --------------------------------------------------------------------------------

(defun org-to-latex (&optional dir)
  "Export current org buffer to a latex file in directory DIR."
  (interactive "DDirectory: ")
  (let ((name (file-name-base (buffer-file-name))))
    (org-latex-export-as-latex)
    (write-file (concat dir name ".tex"))))

;; ESS
;; --------------------------------------------------------------------------------
(setq ess-ask-for-ess-directory nil)
(setq inferior-R-args "--no-save --no-restore")
(setq ess-history-file nil)
