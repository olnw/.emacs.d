;; -*- lexical-binding: t -*-

(require 'package)
(add-to-list 'package-archives '("melpa" . "https://melpa.org/packages/") t)
(package-initialize)

(unless (package-installed-p 'use-package)
  (package-install 'use-package))

(eval-when-compile (require 'use-package))
(setq use-package-always-ensure t)

(use-package no-littering
  :config
  (setq backup-directory-alist
        `(("" . ,(no-littering-expand-var-file-name "emacs-backup/"))))

  (setq auto-save-file-name-transforms
        `((".*" ,(no-littering-expand-var-file-name "auto-save/") t)))

  (setq custom-file (no-littering-expand-etc-file-name "custom.el")))

(custom-set-variables
 '(backup-by-copying t)
 '(c-default-style '((java-mode . "java")
                     (awk-mode . "awk")
                     (other . "linux")))
 '(custom-safe-themes t)
 '(delete-old-versions t)
 '(eldoc-idle-delay 0.1)
 '(inferior-lisp-program "sbcl")
 '(inhibit-startup-screen t)
 '(initial-major-mode #'fundamental-mode)
 '(initial-scratch-message nil)
 '(native-comp-async-report-warnings-errors 'silent)
 '(org-src-preserve-indentation t)
 '(ring-bell-function #'ignore) ; shut up pls
 '(scroll-conservatively 1000)
 '(show-paren-delay 0)
 '(sly-db-focus-debugger t)
 '(tab-always-indent 'complete)
 '(vc-make-backup-files t)
 '(version-control t)
 '(whitespace-style '(tab-mark)))

;; By default, don't allow indentation to insert tab characters.
(setq-default indent-tabs-mode nil)

;; Use tabs for indentation in some languages.
(add-hook 'c-mode-hook (lambda () (setq indent-tabs-mode t)))
(add-hook 'c++-mode-hook (lambda () (setq indent-tabs-mode t)))
(add-hook 'java-mode-hook (lambda () (setq indent-tabs-mode t)))
(add-hook 'sgml-mode-hook (lambda () (setq indent-tabs-mode t)))

(customize-set-variable 'sgml-basic-offset tab-width)

;; Disable case-sensitivity for file and buffer matching
;; with built-in completion styles.
(setq completion-ignore-case t)
(setq read-file-name-completion-ignore-case t)
(setq read-buffer-completion-ignore-case t)

(set-default-coding-systems 'utf-8)

(fset 'yes-or-no-p 'y-or-n-p)

;; Use apps key as Super
(setq w32-pass-apps-to-system nil)
(setq w32-apps-modifier 'super)

(defun xah/new-empty-buffer ()
  "Create a new empty buffer.
New buffer will be named “untitled” or “untitled<2>”, “untitled<3>”, etc.
It returns the buffer (for elisp programing).
URL `http://xahlee.info/emacs/emacs/emacs_new_empty_buffer.html'
Version 2017-11-01"
  (interactive)
  (let (($buf (generate-new-buffer "untitled")))
    (switch-to-buffer $buf)
    (funcall initial-major-mode)
    (setq buffer-offer-save t)
    $buf))

(use-package emacs
  :ensure nil

  :bind
  ("<f5>"  . xah/new-empty-buffer)
  ("<f6>"  . kill-buffer)
  ("<f7>"  . delete-window)
  ("<f8>"  . delete-other-windows)
  ("<f9>"  . tab-next)
  ("<f10>" . tab-new)
  ("<f12>" . tab-close)
  ("s-b"   . consult-buffer)
  ("s-B"   . consult-buffer-other-window)
  ("s-j"   . exchange-point-and-mark)
  ("s-k"   . consult-line)
  ("s-w"   . tab-close)
  ("s-t"   . tab-new)
  ("s-,"   . (lambda ()
               (interactive)
               (find-file user-init-file))))

(global-whitespace-mode 1)
(repeat-mode 1)
(recentf-mode 1)
(savehist-mode 1)
(winner-mode 1)
(column-number-mode 1)
(tool-bar-mode -1)
(menu-bar-mode -1)
(scroll-bar-mode -1)

;; Seems I need to enable this after disabling the above modes, else
;; the tab bar displays strangely.
(when (display-graphic-p)
  (tab-bar-mode 1))

;; Requires Emacs version 29 or higher.
(when (fboundp 'pixel-scroll-precision-mode)
  (pixel-scroll-precision-mode 1))

;; Disable all other themes to avoid awkward blending.
(mapc #'disable-theme custom-enabled-themes)

(load-theme 'modus-vivendi)

;; Custom Faces
(defun olnw/set-faces ()
  (set-face-attribute 'default nil :family "JetBrains Mono" :height 180 :weight 'light)
  (set-face-attribute 'fixed-pitch nil :family "JetBrains Mono" :height 180 :weight 'light)
  (set-face-attribute 'variable-pitch nil :family "FiraGO" :height 180 :weight 'light)

  ;; Make sure the faces are only set once.
  (remove-hook 'server-after-make-frame-hook #'olnw/set-faces))

(if (daemonp)
    (add-hook 'server-after-make-frame-hook #'olnw/set-faces)
  (add-hook 'window-setup-hook #'olnw/set-faces))

;;; LaTeX

(defvar olnw-latex-build-dir "Build")

;; Zotero+Better BibTeX -> auto export .bib file -> citar

(use-package citar
  :custom
  (citar-bibliography '("~/Documents/Bibliography.bib"))

  :hook
  (LaTeX-mode . citar-capf-setup)
  (org-mode   . citar-capf-setup))

(use-package citar-embark
  :after citar embark
  :init (citar-embark-mode 1))

(defun olnw-open-tex-pdf ()
  "Open the PDF file corresponding to the current TeX file."
  (interactive)
  (let ((pdf-path (file-name-concat (file-name-directory buffer-file-name)
                                    olnw-latex-build-dir
                                    (concat (file-name-base buffer-file-name)
                                            ".pdf"))))
    (pcase system-type
      ('darwin (start-process "" nil "open" "-a" "Skim.app" pdf-path))
      ('windows-nt (start-process "" nil "SumatraPDF.exe" pdf-path))
      ('gnu/linux (start-process "" nil "okular" pdf-path)))))

;; Build the current LaTeX document whenever it's saved.
(add-hook 'after-save-hook
          (lambda ()
            (when (eq major-mode 'latex-mode)
              (start-process "latexmk"
                             "latexmk"
                             "latexmk"
                             "-pdf"
                             (format "-auxdir=%s" olnw-latex-build-dir)
                             (format "-outdir=%s" olnw-latex-build-dir)
                             buffer-file-name))))

;;; Packages

(use-package multiple-cursors
  :bind
  ("s-1" . mc/edit-lines)
  ("s-2" . mc/mark-previous-like-this)
  ("s-3" . mc/mark-next-like-this)
  ("s-4" . mc/mark-all-like-this))

;; Incremental search compatible with multiple-cursors
(use-package phi-search)

;; Idea from https://xenodium.com/emacs-dwim-swiper-vs-isearch-vs-phi-search/
(defun olnw-forward-isearch-dwim ()
  (interactive)
  (cond ((and (fboundp #'phi-search)
              (bound-and-true-p multiple-cursors-mode))
         (call-interactively #'phi-search))
        (t (call-interactively #'isearch-forward))))

(defun olnw-backward-isearch-dwim ()
  (interactive)
  (cond ((and (fboundp #'phi-search-backward)
              (bound-and-true-p multiple-cursors-mode))
         (call-interactively #'phi-search-backward))
        (t (call-interactively #'isearch-backward))))

(define-key global-map [remap isearch-forward] #'olnw-forward-isearch-dwim)

(define-key global-map [remap isearch-backward] #'olnw-backward-isearch-dwim)

(use-package smartparens
  :demand t

  :custom
  (sp-highlight-pair-overlay nil)

  :config
  (require 'smartparens-config)
  (sp-use-paredit-bindings)

  :hook
  (lisp-mode       . turn-on-smartparens-strict-mode)
  (emacs-lisp-mode . turn-on-smartparens-strict-mode)

  ;; M-s is used by Consult.
  :bind
  (nil
   :map smartparens-mode-map
   ("M-s" . nil)
   ("C-z" . sp-splice-sexp)
   :map smartparens-strict-mode-map
   ("M-s" . nil)
   ("C-z" . sp-splice-sexp)))

(use-package aggressive-indent
  :custom
  (aggressive-indent-dont-electric-modes '(emacs-lisp-mode lisp-mode))

  :hook
  (emacs-lisp-mode . aggressive-indent-mode)
  (lisp-mode       . aggressive-indent-mode))

(use-package expand-region :bind ("M-h" . er/expand-region))

(use-package vertico :init (vertico-mode 1))

(use-package marginalia :init (marginalia-mode 1))

(use-package orderless
  :custom
  (completion-styles '(orderless basic))
  (completion-category-overrides '((file (styles basic partial-completion)))))

;; dabbrev-completion works with Corfu.
(use-package dabbrev
  :ensure nil
  ;; Swap M-/ and C-M-/
  :bind (("M-/"   . dabbrev-completion)
         ("C-M-/" . dabbrev-expand))
  ;; Other useful Dabbrev configurations.
  :custom
  (dabbrev-ignored-buffer-regexps '("\\.\\(?:pdf\\|jpe?g\\|png\\)\\'")))

(use-package corfu
  :custom
  (corfu-cycle t) ; Enable cycling for `corfu-next/previous'
  (corfu-auto t) ; Enable auto completion
  (corfu-quit-no-match 'separator)

  :init
  (global-corfu-mode)

  (defun corfu-enable-always-in-minibuffer ()
    "Enable Corfu in the minibuffer if Vertico/Mct are not active."
    (unless (or (bound-and-true-p mct--active)
                (bound-and-true-p vertico--input)
                (eq (current-local-map) read-passwd-map))
      ;; (setq-local corfu-auto nil) ;; Enable/disable auto completion
      (setq-local corfu-echo-delay nil ;; Disable automatic echo and popup
                  corfu-popupinfo-delay nil)
      (corfu-mode 1)))
  (add-hook 'minibuffer-setup-hook #'corfu-enable-always-in-minibuffer 1))

(use-package consult
  ;; Replace bindings. Lazily loaded by use-package.
  :bind (;; C-c bindings (mode-specific-map)
         ("C-c h"    . consult-history)
         ("C-c m"    . consult-mode-command)
         ("C-c k"    . consult-kmacro)
         ;; C-x bindings (ctl-x-map)
         ("C-x M-:"  . consult-complex-command)
         ("C-x b"    . consult-buffer)
         ("C-x B"    . consult-buffer-other-window)
         ("C-x 4 b"  . consult-buffer-other-window)
         ("C-x 5 b"  . consult-buffer-other-frame)
         ("C-x r b"  . consult-bookmark)
         ("C-x p b"  . consult-project-buffer)
         ;; Custom M-# bindings for fast register access
         ("M-#"      . consult-register-load)
         ("M-'"      . consult-register-store)
         ("C-M-#"    . consult-register)
         ;; Other custom bindings
         ("M-y"      . consult-yank-pop)
         ("<help> a" . consult-apropos)
         ;; M-g bindings (goto-map)
         ("M-g e"    . consult-compile-error)
         ("M-g f"    . consult-flymake)
         ("M-g g"    . consult-goto-line)
         ("M-g M-g"  . consult-goto-line)
         ("M-g o"    . consult-outline)
         ("M-g m"    . consult-mark)
         ("M-g k"    . consult-global-mark)
         ("M-g i"    . consult-imenu)
         ("M-g I"    . consult-imenu-multi)
         ;; M-s bindings (search-map)
         ("M-s d"    . consult-find)
         ("M-s D"    . consult-locate)
         ("M-s g"    . consult-grep)
         ("M-s G"    . consult-git-grep)
         ("M-s r"    . consult-ripgrep)
         ("M-s l"    . consult-line)
         ("M-s L"    . consult-line-multi)
         ("M-s k"    . consult-keep-lines)
         ("M-s u"    . consult-focus-lines)
         ;; Isearch integration
         ("M-s e"    . consult-isearch-history)
         :map isearch-mode-map
         ("M-e"      . consult-isearch-history)
         ("M-s e"    . consult-isearch-history)
         ("M-s l"    . consult-line)
         ("M-s L"    . consult-line-multi)
         ;; Minibuffer history
         :map minibuffer-local-map
         ("M-s"      . consult-history)
         ("M-r"      . consult-history)
         :map Info-mode-map
         ("s"        . consult-info))

  ;; The :init configuration is always executed. (Not lazy.)
  :init
  ;; Use `consult-completion-in-region' if Vertico is enabled.
  ;; Otherwise use the default `completion--in-region' function.
  ;; (setq completion-in-region-function
  ;;       (lambda (&rest args)
  ;;         (apply (if vertico-mode
  ;;                    #'consult-completion-in-region
  ;;                  #'completion--in-region)
  ;;                args)))

  ;; Configure the register formatting. This improves the register
  ;; preview for 'consult-register', 'consult-register-load',
  ;; 'consult-register-store' and the Emacs built-ins.
  (setq register-preview-delay 0.5
        register-preview-function #'consult-register-format)

  ;; Tweak the register preview window.
  ;; This adds thin lines, sorting and hides the mode line of the window.
  (advice-add #'register-preview :override #'consult-register-window)

  ;; Use Consult to select xref locations with preview.
  (setq xref-show-xrefs-function #'consult-xref
        xref-show-definitions-function #'consult-xref))

(use-package embark
  :bind
  ("C-."   . embark-act)
  ("C-;"   . embark-dwim)
  ("C-h B" . embark-bindings)

  :init
  ;; Optionally replace the key help with a completing-read interface.
  (setq prefix-help-command #'embark-prefix-help-command)

  :config
  ;; Hide the mode line of the Embark live/completions buffers.
  (add-to-list 'display-buffer-alist
               '("\\`\\*Embark Collect \\(Live\\|Completions\\)\\*"
                 nil
                 (window-parameters (mode-line-format . none))))

  (defun embark-which-key-indicator ()
    "An embark indicator that displays keymaps using which-key.
The which-key help message will show the type and value of the
current target followed by an ellipsis if there are further
targets."
    (lambda (&optional keymap targets prefix)
      (if (null keymap)
          (which-key--hide-popup-ignore-command)
        (which-key--show-keymap
         (if (eq (plist-get (car targets) :type) 'embark-become)
             "Become"
           (format "Act on %s '%s'%s"
                   (plist-get (car targets) :type)
                   (embark--truncate-target (plist-get (car targets) :target))
                   (if (cdr targets) "…" "")))
         (if prefix
             (pcase (lookup-key keymap prefix 'accept-default)
               ((and (pred keymapp) km) km)
               (_ (key-binding prefix 'accept-default)))
           keymap)
         nil nil t (lambda (binding)
                     (not (string-suffix-p "-argument" (cdr binding))))))))

  (setq embark-indicators
        '(embark-which-key-indicator
          embark-highlight-indicator
          embark-isearch-highlight-indicator))

  (defun embark-hide-which-key-indicator (fn &rest args)
    "Hide the which-key indicator immediately when using the completing-read prompter."
    (which-key--hide-popup-ignore-command)
    (let ((embark-indicators
           (remq #'embark-which-key-indicator embark-indicators)))
      (apply fn args)))

  (advice-add #'embark-completing-read-prompter
              :around #'embark-hide-which-key-indicator))

;; embark-consult provides integration between embark and consult.
(use-package embark-consult
  :hook
  (embark-collect-mode . consult-preview-at-point-mode))

;; wgrep allows you to edit grep buffers, saving your changes to all
;; corresponding files.
(use-package wgrep)

(use-package ws-butler :hook (prog-mode . ws-butler-mode))

(use-package exec-path-from-shell
  ;; Get environment variables such as $PATH from the shell
  :config
  (when (memq window-system '(mac ns))
    (exec-path-from-shell-initialize)))

(use-package which-key :init (which-key-mode))

(use-package rainbow-delimiters
  :hook
  ((ielm-mode . rainbow-delimiters-mode)
   (prog-mode . rainbow-delimiters-mode)
   (sly-mrepl . rainbow-delimiters-mode)))

;; Provides snippet completions for eglot.
(use-package yasnippet
  :config (yas-global-mode 1)
  :bind (:map yas-minor-mode-map
              ("<tab>" . nil)
              ("TAB"   . nil)))

(use-package yasnippet-snippets)

(use-package eglot
  :hook
  ((python-mode . eglot-ensure)
   (c-mode      . eglot-ensure)
   (c++-mode    . eglot-ensure)
   (cmake-mode  . eglot-ensure)
   (TeX-mode    . eglot-ensure)
   (LaTeX-mode  . eglot-ensure)))

(use-package consult-eglot
  :config
  (define-key eglot-mode-map [remap xref-find-apropos] #'consult-eglot-symbols)
  (define-key eglot-mode-map [remap xref-find-references-and-replace] #'eglot-rename))

(use-package sly
  :config
  ;; Disable Sly's completion UI.
  (sly-symbol-completion-mode -1))

(use-package magit
  :custom
  (magit-diff-paint-whitespace t)

  :hook
  (git-commit-setup . git-commit-turn-on-flyspell))

(use-package erc
  :ensure nil

  :custom
  (erc-nick "olnw")
  (erc-prompt-for-password nil)
  (erc-prompt-for-nickserv-password nil)

  :init
  (defun libera-chat ()
    (interactive)
    (erc-tls :server "irc.au.libera.chat"
             :port "6697")))
