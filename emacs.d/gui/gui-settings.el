(provide 'gui-settings)

(add-to-list 'default-frame-alist '(width . 132))
(add-to-list 'default-frame-alist '(height . 40))

(set-face-attribute 'default nil :family "ProfontWindows")
(set-face-attribute 'default nil :height (if
                                             (<= (display-pixel-height) 1000)
                                             120
                                           200))


(x-focus-frame nil)
