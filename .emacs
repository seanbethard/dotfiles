;; straight packages
(setq straight-repository-branch "develop")
(defvar bootstrap-version)
(let ((bootstrap-file
       (expand-file-name "straight/repos/straight.el/bootstrap.el" user-emacs-directory))
      (bootstrap-version 6))
  (unless (file-exists-p bootstrap-file)
    (with-current-buffer
	(url-retrieve-synchronously
	 "https://raw.githubusercontent.com/radian-software/straight.el/develop/install.el"
	 'silent 'inhibit-cookies)
      (goto-char (point-max))
      (eval-print-last-sexp)))
  (load bootstrap-file nil 'nomessage))

;; fish
(straight-use-package 'fish-mode)
(add-hook 'fish-mode-hook (lambda ()
                            (add-hook 'before-save-hook 'fish_indent-before-save)))

;; helm
(straight-use-package 'helm)

;; completions
(straight-use-package 'helm-fish-completion)
(straight-use-package 'fish-completion)

;; line and column numbers in mode line
(setq linum-mode t)
(setq column-number-mode t)

;; set location for backup files
(setq backup-directory-alist '((".*" . "~/.Trash")))
