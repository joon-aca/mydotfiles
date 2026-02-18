;; Modern Emacs Configuration
;; Adapted from vintage Unix .emacs with modernizations

;;; ============================================================
;;; UI Cleanup
;;; ============================================================

;; Disable unnecessary UI elements
(menu-bar-mode -1)
(when (fboundp 'tool-bar-mode)   (tool-bar-mode -1))
(when (fboundp 'tooltip-mode)    (tooltip-mode -1))
(when (fboundp 'scroll-bar-mode) (scroll-bar-mode -1))

;; No startup screen
(setq inhibit-splash-screen t)
(setq inhibit-startup-message t)

;; Clean mode line
(set-face-attribute 'mode-line nil :box nil)

;; Show line and column numbers
(global-display-line-numbers-mode t)
(column-number-mode t)

;; Highlight current line
(global-hl-line-mode t)

;; Show matching parentheses
(show-paren-mode t)
(setq show-paren-delay 0)

;; Better scrolling behavior
(setq scroll-conservatively 101)
(setq scroll-margin 3)

;;; ============================================================
;;; Font Settings (modernized)
;;; ============================================================

;; Use modern font specification instead of X11 XLFD
;; Adjust to your preference (Monaco, Menlo, Consolas, etc.)
(when (display-graphic-p)
  (set-frame-font "Monaco-14" nil t))

;;; ============================================================
;;; Key Bindings
;;; ============================================================

;; M-g is now goto-line by default in modern Emacs, but keep for clarity
(global-set-key (kbd "M-g g") 'goto-line)

;; Query Replace
(global-set-key (kbd "C-x r") 'query-replace)

;; Buffer list (ibuffer is more modern than electric-buffer-list)
(global-set-key (kbd "C-x C-b") 'ibuffer)

;; Copy (modern emacs already has good clipboard integration)
(global-set-key (kbd "M-c") 'kill-ring-save)

;; Repeat complex command
(global-set-key (kbd "M-r") 'repeat-complex-command)

;; C-h as backspace (classic Unix behavior)
;; Note: This disables help on C-h, use F1 for help instead
(keyboard-translate ?\C-h ?\C-?)

;; Smooth scrolling (slide up/down)
(defun slide-up ()
  "Scroll up smoothly by one line."
  (interactive)
  (scroll-up 1)
  (forward-line 1))

(defun slide-down ()
  "Scroll down smoothly by one line."
  (interactive)
  (scroll-down 1)
  (forward-line -1))

(global-set-key (kbd "M-n") 'slide-up)
(global-set-key (kbd "M-p") 'slide-down)

;; Function keys
(global-set-key (kbd "<f1>") 'compile)
(global-set-key (kbd "<f2>") 'isearch-backward)
(global-set-key (kbd "<f3>") 'isearch-forward)
(global-set-key (kbd "<f4>") 'kill-region)
(global-set-key (kbd "<f5>") 'indent-region)
(global-set-key (kbd "<f6>") 'backward-kill-word)
(global-set-key (kbd "<f7>") 'kill-word)
(global-set-key (kbd "<f8>") 'what-line)
(global-set-key (kbd "<f10>") 'dabbrev-expand)
(global-set-key (kbd "<f11>") 'tags-search)
(global-set-key (kbd "<f12>") 'tags-loop-continue)

;; Disable iconification (suspend)
(global-unset-key (kbd "C-z"))

;;; ============================================================
;;; Line Ending Utilities
;;; ============================================================

(defun unix-file ()
  "Change the current buffer to Unix line-ends."
  (interactive)
  (set-buffer-file-coding-system 'unix t))

(defun dos-file ()
  "Change the current buffer to DOS line-ends."
  (interactive)
  (set-buffer-file-coding-system 'dos t))

(defun mac-file ()
  "Change the current buffer to Mac line-ends."
  (interactive)
  (set-buffer-file-coding-system 'mac t))

;;; ============================================================
;;; Editor Behavior
;;; ============================================================

;; Shorter yes/no prompts
(fset 'yes-or-no-p 'y-or-n-p)

;; No auto-save files (~ turds)
(setq auto-save-default nil)
(setq make-backup-files nil)

;; Mouse wheel support (already default in modern Emacs)
(when (fboundp 'mouse-wheel-mode)
  (mouse-wheel-mode t))

;; Delete selection mode - typing replaces selection
(delete-selection-mode t)

;; Enable recent files
(recentf-mode t)
(setq recentf-max-saved-items 50)

;; Save place in files
(save-place-mode t)

;; Electric pair mode - auto-close brackets
(electric-pair-mode t)

;;; ============================================================
;;; Programming Settings
;;; ============================================================

;; Syntax highlighting
(global-font-lock-mode t)

;; C/C++ indentation (Linux kernel style - 8 space tabs)
(setq c-basic-offset 8)
(setq c-indent-level 8)
(setq tab-width 8)

;; Python mode - 4 space tabs
(add-hook 'python-mode-hook
          (lambda ()
            (setq indent-tabs-mode t)
            (setq tab-width 4)
            (setq python-indent-offset 4)))

;; Enable region case conversion commands
(put 'upcase-region 'disabled nil)
(put 'downcase-region 'disabled nil)

;; Version control - prefer git
(setq vc-handled-backends '(Git SVN))

;;; ============================================================
;;; Custom Theme/Faces (Dark background)
;;; ============================================================

;; Modern approach: use a theme instead
;; Uncomment one of these or use M-x customize-themes
;; (load-theme 'wombat t)
;; (load-theme 'tango-dark t)
;; (load-theme 'misterioso t)

;; Or keep vintage custom faces for dark terminal use
(custom-set-faces
 '(font-lock-builtin-face ((((class color) (background dark)) (:foreground "CadetBlue"))))
 '(font-lock-comment-face ((((class color) (background dark)) (:foreground "RosyBrown"))))
 '(font-lock-constant-face ((((class color) (background dark)) (:foreground "Aquamarine3"))))
 '(font-lock-function-name-face ((((class color) (background dark)) (:foreground "White"))))
 '(font-lock-keyword-face ((((class color) (background dark)) (:foreground "Lavender"))))
 '(font-lock-string-face ((((class color) (background dark)) (:foreground "LightSteelBlue"))))
 '(font-lock-type-face ((((class color) (background dark)) (:foreground "LightYellow"))))
 '(font-lock-variable-name-face ((((class color) (background dark)) (:foreground "LightBlue"))))
 '(region ((t (:background "DarkSlateBlue")))))

;;; ============================================================
;;; Package Management (Modern Emacs 24+)
;;; ============================================================

;; Setup package archives
(require 'package)
(setq package-archives
      '(("melpa" . "https://melpa.org/packages/")
        ("gnu" . "https://elpa.gnu.org/packages/")
        ("nongnu" . "https://elpa.nongnu.org/nongnu/")))

;; Initialize packages
(package-initialize)

;; Uncomment to auto-install use-package if needed
;; (unless (package-installed-p 'use-package)
;;   (package-refresh-contents)
;;   (package-install 'use-package))

;;; ============================================================
;;; Custom Variables
;;; ============================================================

(custom-set-variables
 '(c-basic-offset 8)
 '(c-font-lock-extra-types '("FILE" "\\sw+_t" "HANDLE"))
 '(c-indent-level 8)
 '(c-label-minimum-indentation 0)
 '(c-tab-always-indent 'other))

;;; ============================================================
;;; Done
;;; ============================================================

(message "Emacs configuration loaded")
