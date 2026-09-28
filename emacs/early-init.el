;;; early-init.el --- before the first frame  -*- lexical-binding: t -*-

;; Quiet, clean startup; flash instead of beeping
(setq visible-bell t
      inhibit-startup-screen t
      initial-scratch-message nil
      inhibit-startup-echo-area-message (user-login-name))

;; Activate packages from one pre-built file (faster startup; rebuilt when packages change)
(setopt package-quickstart t)

;; No backup~, #autosave#, or .#lock files next to the originals
(setq make-backup-files nil
      auto-save-default nil
      create-lockfiles nil)

;; Custom writes to its own file, not into init.el (which is in git); settings belong in init.el, so it is not loaded
(setq custom-file (locate-user-emacs-file "custom.el"))
