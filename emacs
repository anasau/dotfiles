(require 'package)
(add-to-list 'package-archives '("melpa" . "http://melpa.milkbox.net/packages/") t)
(package-initialize)

(require 'cl)
(require 'iso-transl)
(require 'ido)

(defvar my-packages
  '(evil flycheck color-theme-sanityinc-tomorrow yasnippet auto-complete
	 emmet-mode evil-surround evil-numbers evil-nerd-commenter evil-leader
	 web-mode php-mode php-auto-yasnippets auto-complete-clang
	 cpputils-cmake)
  "A list of packages to ensure are installed at launch.")
 
(defun my-packages-installed-p ()
  (loop for p in my-packages
        when (not (package-installed-p p)) do (return nil)
        finally (return t)))
 
(unless (my-packages-installed-p)
  ;; check for new packages (package versions)
  (package-refresh-contents)
  ;; install the missing packages
  (dolist (p my-packages)
    (when (not (package-installed-p p))
      (package-install p))))

;; ido
(ido-mode t)
(setq ido-everywhere t)
(setq ido-enable-flex-matching t)
(setq ido-file-extensions-order '(".php" ".js" ".html" ".css" ".cpp" ".hpp" ".c" ".h" ".txt"))

;; Evil
(global-evil-leader-mode)
(evil-leader/set-leader ",")

(evil-leader/set-key
 "w" 'save-buffer
 "e" 'find-file
 "f" 'ff-find-related-file
 "b" 'ido-switch-buffer
 "d" 'dired
 "c" 'compile
 "k" 'kill-this-buffer
 "m" 'toggle-frame-maximized
)

(evil-mode 1)
(global-evil-surround-mode 1)
(evilnc-default-hotkeys)

(global-set-key (kbd "C-a") 'mark-whole-buffer)

;; Yasnippet
(yas-global-mode 1)

;; Emmet
(add-hook 'sgml-mode-hook 'emmet-mode) ;; Auto-start on any markup modes
(add-hook 'css-mode-hook  'emmet-mode) ;; enable Emmet's css abbreviation.

;; Flycheck
(add-hook 'after-init-hook #'global-flycheck-mode)

;; Autocomplete
(require 'auto-complete-config)
(add-to-list 'ac-dictionary-directories "~/.emacs.d/ac-dict")
(ac-config-default)
(global-auto-complete-mode t)
(add-to-list 'ac-sources 'ac-clang)

(require 'php-auto-yasnippets)

;;(ac-set-trigger-key "TAB")
;;(ac-set-trigger-key "<tab>")

(scroll-bar-mode -1)
(setq inhibit-startup-message t)
(tool-bar-mode -1)
(load-theme 'sanityinc-tomorrow-bright t)

(add-to-list 'default-frame-alist '(font . "Monaco 11"))
(set-face-attribute 'default t :font "Monaco 12")

;; esc quits

(defun minibuffer-keyboard-quit ()
  "Abort recursive edit.
In Delete Selection mode, if the mark is active, just deactivate it;
then it takes a second \\[keyboard-quit] to abort the minibuffer."
  (interactive)
  (if (and delete-selection-mode transient-mark-mode mark-active)
      (setq deactivate-mark t)
    (when (get-buffer "*Completions*") (delete-windows-on "*Completions*"))
    (abort-recursive-edit)))

(define-key evil-normal-state-map [escape] 'keyboard-quit)
(define-key evil-visual-state-map [escape] 'keyboard-quit)
(define-key minibuffer-local-map [escape] 'minibuffer-keyboard-quit)
(define-key minibuffer-local-ns-map [escape] 'minibuffer-keyboard-quit)
(define-key minibuffer-local-completion-map [escape] 'minibuffer-keyboard-quit)
(define-key minibuffer-local-must-match-map [escape] 'minibuffer-keyboard-quit)
(define-key minibuffer-local-isearch-map [escape] 'minibuffer-keyboard-quit)

;; web-dev

(defun php-setup ()
  ;; enable web mode
  (web-mode)
  (emmet-mode)

  (flycheck-define-checker php-checker
    "A PHP syntax checker using the PHP command line interpreter.
See URL `http://php.net/manual/en/features.commandline.php'."
    :command ("php" "-l" "-d" "error_reporting=E_ALL" "-d" "display_errors=1"
	      "-d" "log_errors=0" source)
    :error-patterns
    ((error line-start (or "Parse" "Fatal" "syntax") " error" (any ":" ",") " "
	    (message) " in " (file-name) " on line " line line-end))
    :modes (php-mode php+-mode web-mode))

  (flycheck-select-checker 'php-checker)

  (payas/ac-setup)

  (setq web-mode-ac-sources-alist '(("php" . (ac-source-yasnippet ac-source-php-auto-yasnippets))
				    ("html" . (ac-source-emmet-html-aliases ac-source-emmet-html-snippets))
				    ("css" . (ac-source-css-property ac-source-emmet-css-snippets))))

  (add-hook 'web-mode-before-auto-complete-hooks
	    '(lambda ()
	       (let ((web-mode-cur-language
		      (web-mode-language-at-pos)))
		 (if (string= web-mode-cur-language "php")
		     (yas-activate-extra-mode 'php-mode)
		   (yas-deactivate-extra-mode 'php-mode))
		 (if (string= web-mode-cur-language "css")
		     (setq emmet-use-css-transform t)
		   (setq emmet-use-css-transform nil)))))

  ;; make these variables local
  (make-local-variable 'web-mode-code-indent-offset)
  (make-local-variable 'web-mode-markup-indent-offset)
  (make-local-variable 'web-mode-css-indent-offset)

  ;; set indentation, can set different indentation level for different code type
  (setq web-mode-code-indent-offset 4)
  (setq web-mode-css-indent-offset 2)
  (setq web-mode-markup-indent-offset 2))

(add-to-list 'auto-mode-alist '("\\.php$" . php-setup))
(add-to-list 'auto-mode-alist '("\\.scss$" . css-mode))

(set-face-attribute 'mode-line nil :foreground "#fff" :background "#333" :box nil)
(set-face-attribute 'mode-line-inactive nil :background "#111" :box nil)

(global-hl-line-mode 1)
(set-face-background 'hl-line "#222")

(defalias 'yes-or-no-p 'y-or-n-p)


;; C++
(add-hook 'c-mode-common-hook
          (lambda ()
            (if (derived-mode-p 'c-mode 'c++-mode)
                (cppcm-reload-all)
              )))
;; OPTIONAL, somebody reported that they can use this package with Fortran
(add-hook 'c90-mode-hook (lambda () (cppcm-reload-all)))
;; OPTIONAL, avoid typing full path when starting gdb
(global-set-key (kbd "C-c C-g")
 '(lambda ()(interactive) (gud-gdb (concat "gdb --fullname " (cppcm-get-exe-path-current-buffer)))))

;; OPTIONAL, some users need specify extra flags forwarded to compiler
;;(setq cppcm-extra-preprocss-flags-from-user '("-I/usr/src/linux/include" "-DNDEBUG"))

(setq cppcm-get-executable-full-path-callback
      (lambda (path type tgt-name)
        ;; path is the supposed-to-be target's full path
        ;; type is either add_executabe or add_library
        ;; tgt-name is the target to built. The target's file extension is stripped
        (message "cppcm-get-executable-full-path-callback called => %s %s %s" path type tgt-name)
        (let ((dir (file-name-directory path))
              (file (file-name-nondirectory path)))
          (cond
           ((string= type "add_executable")
            (setq path (concat dir "bin/" file)))
           ;; for add_library
           (t (setq path (concat dir "lib/" file)))
           ))
        ;; return the new path
        (message "cppcm-get-executable-full-path-callback called => path=%s" path)
        path))

(setq flycheck-clang-language-standard "c++11")
(setq flycheck-clang-standard-library "libc++")


;; Backups


(defvar --backup-directory (concat user-emacs-directory "backups"))
(if (not (file-exists-p --backup-directory))
        (make-directory --backup-directory t))

(setq backup-directory-alist `(("." . ,--backup-directory)))

(setq version-control t     ;; Use version numbers for backups.
      make-backup-files t
      kept-new-versions 10  ;; Number of newest versions to keep.
      kept-old-versions 6   ;; Number of oldest versions to keep.
      delete-old-versions t ;; Don't ask to delete excess backup versions.
      delete-by-moving-to-trash t
      vc-make-backup-files t
      backup-by-copying t)  ;; Copy all files, don't rename them


