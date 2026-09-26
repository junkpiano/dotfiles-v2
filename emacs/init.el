;;; init.el --- minimal Emacs 30 for reading files: built-ins first, everything else loads on first use  -*- lexical-binding: t -*-

;; The only packages. A fresh machine installs them on first start; nothing loads until it is used.
(require 'package)
(add-to-list 'package-archives '("melpa" . "https://melpa.org/packages/") t)
(dolist (p '(markdown-mode mozc))
  (unless (package-installed-p p)
    (unless package-archive-contents (package-refresh-contents))
    (package-install p)))
(setopt use-package-always-defer t)

;; --- built-ins ---
(fido-vertical-mode 1)                   ; vertical candidates for C-x C-f, M-x, C-x b
(which-key-mode 1)                       ; after a prefix key, show what comes next
(recentf-mode 1)                         ; M-x recentf-open: files opened before
(save-place-mode 1)                      ; reopen a file where you left it
(setopt auto-revert-verbose nil
        global-auto-revert-non-file-buffers t)
(global-auto-revert-mode 1)              ; follow files (and dired) as the AI changes them on disk
(setopt dired-listing-switches "-alh --group-directories-first"
        dired-kill-when-opening-new-dired-buffer t)
(declare-function dired-hide-details-mode "dired")
(add-hook 'dired-mode-hook #'dired-hide-details-mode) ; "(" shows sizes and dates

;; --- Markdown: .md opens read-only and rendered in place (M-x gfm-mode to edit) ---
(declare-function markdown-toggle-markup-hiding "markdown-mode")
(use-package markdown-mode
  :mode ("\\.md\\'" . gfm-view-mode)
  :hook (gfm-view-mode . (lambda () (markdown-toggle-markup-hiding 1))) ; hide #, **, ``` only when reading
  :custom
  (markdown-header-scaling t)
  (markdown-hide-urls t)
  (markdown-gfm-use-electric-backquote nil) ; typing ``` does not ask for a language
  (markdown-fontify-code-blocks-natively t))

;; --- Japanese input: C-\ (mozc_emacs_helper from emacs-mozc-bin) ---
(setq default-input-method "japanese-mozc")
(use-package mozc
  :commands mozc-mode
  :init (register-input-method "japanese-mozc" "Japanese" #'mozc-mode "[あ]")
  :custom (mozc-candidate-style (if (display-graphic-p) 'overlay 'echo-area)))

;; --- fonts: Ricty Diminished for ASCII, Noto CJK for Japanese ---
(when (display-graphic-p)
  (set-face-attribute 'default nil :family "Ricty Diminished" :height 120)
  (set-face-attribute 'fixed-pitch nil :family "Ricty Diminished") ; code blocks in the same font
  (dolist (script '(kana han cjk-misc))
    (set-fontset-font t script (font-spec :family "Noto Sans Mono CJK JP")))
  (set-fontset-font t 'emoji (font-spec :family "Noto Color Emoji") nil 'prepend))

;; Org (built in) settings apply when an .org file is first opened
(with-eval-after-load 'org
  (setopt org-log-done 'time
          org-table-number-fraction 3))
