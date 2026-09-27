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
;; emacs -nw (WSL, SSH): send copies to the system clipboard with OSC 52, which Windows Terminal understands
(defun my/copy-to-clipboard (text)
  "Copy TEXT to the system clipboard: the GUI's own way, or OSC 52 in a terminal."
  (if (display-graphic-p)
      (gui-select-text text)
    (send-string-to-terminal
     (concat "\e]52;c;" (base64-encode-string (encode-coding-string text 'utf-8) t) "\a"))))
(setq interprogram-cut-function #'my/copy-to-clipboard)

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

;; --- C-c r: review pull request N (fetched as pr/N) as one read-only diff, like the PR page ---
(defun my/pr-review (n)
  "Fetch pull request N as pr/N and show it as one diff, like the PR page."
  (interactive "nPull request number: ")
  (let* ((root (or (locate-dominating-file default-directory ".git")
                   (user-error "Not in a git repository")))
         (default-directory root)
         (base (string-trim (shell-command-to-string
                             "git symbolic-ref --quiet --short refs/remotes/origin/HEAD || echo origin/main")))
         (buf (get-buffer-create (format "*PR %d*" n))))
    (unless (zerop (call-process "git" nil nil nil "fetch" "-f" "origin" (format "pull/%d/head:pr/%d" n n)))
      (user-error "Could not fetch pull request %d" n))
    (with-current-buffer buf
      (setq default-directory root)
      (let ((inhibit-read-only t))
        (erase-buffer)
        (call-process "git" nil t nil "diff" (format "%s...pr/%d" base n)))
      (diff-mode)
      (read-only-mode 1)                    ; so n, p, o, k work
      (goto-char (point-min)))
    (pop-to-buffer buf)))
(global-set-key (kbd "C-c r") #'my/pr-review)
