; -*- mode: emacs-lisp-mode; -*-
(setq viper-inhibit-startup-message 't)
(setq viper-expert-level '4)

(define-key viper-vi-global-user-map "h" 'viper-backward-char)
(define-key viper-vi-global-user-map "t" 'viper-next-line)
(define-key viper-vi-global-user-map "n" 'viper-previous-line)
(define-key viper-vi-global-user-map "s" 'viper-forward-char)

(define-key viper-vi-global-user-map "K" 'fill-paragraph)

(setq-default viper-auto-indent t)
(setq-default viper-electric-mode t)
(setq-default viper-shift-width 4)
