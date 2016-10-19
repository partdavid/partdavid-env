
; emacs -q -l /usr/local/env/jbrinkley/emacs
(unless
  (getenv "ENV_HOME")
  (setenv "ENV_HOME"
    (concat "/usr/local/env/"
      (or
        (getenv "SUDO_USER")
        (getenv "USER")))))

(defun envhome (file)
  "concatenate ENV_HOME with file"
  (concat (getenv "ENV_HOME") "/" file))

(setq-default indent-tabs-mode nil)
(setq-default tab-width 4)
(setq-default standard-indent 4)
(setq-default require-final-newline t)
(setq inhibit-startup-screen t)
(setq require-final-newline t)
(setq viper-custom-file-name (envhome "viper"))
(setq viper-mode 't)
(require 'viper)

;disable "Check it out?" prompts
(defadvice viper-maybe-checkout (around viper-svn-checkin-fix activate)
  "Advise viper-maybe-checkout to ignore svn files."
  (let ((file (expand-file-name (buffer-file-name buf))))
    (when (and (featurep 'vc-hooks)
               (not (memq (vc-backend file) '(nil SVN)))
               (not (memq (vc-backend file) '(nil Git)))
               )
      ad-do-it)))

;gui
(add-to-list 'load-path (envhome "emacs.d/gui"))
(if (display-graphic-p)
  (require 'gui-settings))

;backups
(setq backup-by-copying t)
(setq backup-directory-alist `(("." . "~/.backups")))
(setq delete-old-versions t
  kept-new-versions 6
  kept-old-versions 2
  version-control t)

;cl-lib
(defun extract-major-version (version-string)
  "Extract the first string of digits delimited by a dot"
  (if
      (string-match "\\([0-9]+\\)\." version-string)
      (string-to-number (match-string 1 version-string))
    nil
    )
  )

(when (< (extract-major-version (emacs-version)) 24)
  (add-to-list 'load-path (envhome "emacs.d/cl-lib"))
  (require 'cl-lib))

;emacs lisp
(add-to-list 'auto-mode-alist '("emacs$" . emacs-lisp-mode))

;ruby
(add-to-list 'load-path (envhome "emacs.d/ruby-mode"))
(require 'ruby-mode)

(autoload 'ruby-mode "ruby-mode"
  "Mode for editing ruby source files")

(setq ruby-indent-level standard-indent)
(add-to-list 'auto-mode-alist
  '("\\.\\(?:gemspec\\|irbrc\\|gemrc\\|rake\\|rb\\|ru\\|thor\\)\\'" . ruby-mode))
(add-to-list 'auto-mode-alist
  '("\\(Capfile\\|Gemfile\\(?:\\.[a-zA-Z0-9._-]+\\)?\\|[rR]akefile\\)\\'" . ruby-mode))
(add-to-list 'interpreter-mode-alist '("ruby" . ruby-mode))
(add-to-list 'interpreter-mode-alist '("rspec" . ruby-mode))
(add-hook 'ruby-mode-hook 'turn-on-font-lock)
(add-hook 'ruby-mode-hook
  '(lambda ()
    (setq ruby-insert-encoding-magic-comment nil)
    (setq ruby-indent-level standard-indent)))

;rspec
(add-to-list 'load-path (envhome "emacs.d/rspec-mode"))
(require 'rspec-mode)

;puppet
(add-to-list 'load-path (envhome "emacs.d/puppet-mode"))
(autoload 'puppet-mode "puppet-mode" "Major mode for editing puppet manifests")

(add-to-list 'auto-mode-alist '("\\.pp$" . puppet-mode))

(add-hook 'puppet-mode-hook
  (lambda ()
    (setq puppet-indent-level standard-indent)))

;yaml
(add-to-list 'load-path (envhome "emacs.d/yaml-mode"))
(autoload 'yaml-mode "yaml-mode" "Major mode for editing YAML files")
(add-to-list 'auto-mode-alist
  '("\\.ya?ml$" . yaml-mode))

(add-hook 'yaml-mode-hook
  '(lambda ()
    (setq yaml-indent-offset 2)))

;bats
(add-to-list 'interpreter-mode-alist '("bats" . sh-mode))

;rspec
(add-to-list 'load-path (envhome "emacs.d/rspec-mode"))
(require 'rspec-mode)

;go
(add-to-list 'load-path (envhome "emacs.d/go-mode"))
(autoload 'go-mode "go-mode" "Major mode for editing go source")
(add-to-list 'auto-mode-alist '("\\.go$" . go-mode))

;file variables for indentation
(put 'puppet-indent-level 'safe-local-variable 'integerp)
(put 'ruby-indent-level 'safe-local-variable 'integerp)
(put 'python-indent 'safe-local-variable 'integerp)
(put 'cperl-indent-level 'safe-local-variable 'integerp)
(put 'encoding 'safe-local-variable 'symbolp)

;erlang
(defun erlang-find ()
  "Create alist of erlang parameters for erlang mode"
  (let ((erlangf (shell-command-to-string (envhome "emacs.d/erlang-find"))))
    (if (string-match-p "[Nn]o such" erlangf)
        nil
      (mapcar
       (lambda (kv) (apply #'cons (split-string kv "=")))
       (split-string
        (shell-command-to-string (envhome "emacs.d/erlang-find")))))))

(setq erlang-param (erlang-find))

(when erlang-param
  (setq load-path (cons (cdr (assoc "erlang-load-path" erlang-param))
                         load-path))
  (setq erlang-root-dir (cdr (assoc "erlang-root-dir" erlang-param)))
  (setq exec-path (cons (cdr (assoc "erlang-exec-path" erlang-param)) exec-path))
  (require 'erlang-start))

(run-hooks after-init-hook)
