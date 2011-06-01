# dedent.el #

dedent.el makes it easy to copy and paste text while treating
indentation intelligently.

The primary operation, `dedent-string`,takes a block of text,
identifies the line with the least indentation, and removes that
indentation from every line.  `dedent.el` provides several supporting
commands built on this operation:

- `dedent-yank` pastes such that the first non-white character is at
  point, and will maintain relative indentation on subsequent lines.

- `dedent-kill` kills a piece of text and then runs `dedent-string` on
  the text.

- `dedent-extend-indentation` will add spaces to blank lines to give
  them the same indentation as the next non-blank line.

  This behavior was specifically designed for copying blocks of code
  into the Python REPL, where empty lines are interpreted as
  end-of-function.

## Sample Usage ##

Load `dedent.el` and bind keys as you see fit.  For example, I bind
`dedent-kill` with `extend-indentation` in `python-mode`:

    (require 'dedent)
   
    (defun python-kill ()
      (interactive)
      (dedent-kill t))
     
    (add-hook 'python-mode-hook
              '(lambda ()
                 (define-key python-mode-map (kbd "C-M-w") 'python-kill)))
