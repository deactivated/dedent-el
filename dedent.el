;;; dedent.el --- Add and remove indentation during copy and paste

;; Copyright (c) 2011 Mike Spindel <deactivated@gmail.com>

;; This program is free software; you can redistribute it and/or modify
;; it under the terms of the GNU General Public License as published by
;; the Free Software Foundation, either version 3 of the License, or
;; (at your option) any later version.

;; This program is distributed in the hope that it will be useful,
;; but WITHOUT ANY WARRANTY; without even the implied warranty of
;; MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
;; GNU General Public License for more details.

;; You should have received a copy of the GNU General Public License
;; along with this program.  If not, see <http://www.gnu.org/licenses/>.

;;; Code:

(eval-when-compile (require 'cl))

(defmacro dedent-modify-last-kill (f)
  `(kill-new (,f (current-kill 0 t)) t))

(defun dedent-prepare-string (s n)
  (let ((buf-tab-width tab-width))
    (with-temp-buffer
      (setq tab-width buf-tab-width)
      (insert s)
      (untabify (point-min) (point-max))
      (goto-char (point-min))
      (when (re-search-forward "\\`\\(\\(^[ \t]*$\\)\n?\\)+" nil t)
        (replace-match "" nil nil))
      (when n
        (re-search-forward "[ \n]*" nil t)
        (replace-match (make-string n ?\ ) nil nil))
      (buffer-string))))

(defun dedent-string (s &optional first)
  (let* ((s (dedent-prepare-string s first))
         (amt (loop
               with start = 0
               while (string-match "^\\([ \t]*\\)[^ \t]" s start)
               do (setq start (match-end 0))
               minimize (- (match-end 1) (match-beginning 1)))))
    (replace-regexp-in-string
     "^ +" (lambda (m) (make-string (- (length m) amt) ?\ )) s)))

(defun dedent-extend-indentation (s)
  "Indent blank lines in S with same indentation as next
non-blank line.  This behavior is useful when copying a block of
code to a finicky REPL."
  (with-temp-buffer
    (insert s)
    (goto-char (point-min))
    (while (and (not (eobp))
                (re-search-forward "^ *$" nil t))
        (replace-match
         (save-match-data
           (if (re-search-forward "^\\( *\\)[^ \n\t]" nil t)
               (make-string (- (match-end 1) (match-beginning 1)) ?\ )
             "")))
      (forward-line))
    (buffer-string)))

(defun dedent-kill (kill-fn &optional extend-indentation)
  "Execute KILL-FN and then dedent the top entry in the kill-ring."
  (let ((col (save-excursion
               (save-restriction
                 (widen)
                 (if mark-active
                     (goto-char (min (mark) (point))))
                 (skip-chars-forward " \t\n")
                 (current-column)))))
    (call-interactively kill-fn)
    
    (dedent-modify-last-kill (lambda (s) (dedent-string s col)))
    (when extend-indentation
      (dedent-modify-last-kill dedent-extend-indentation))))

(defun dedent-yank ()
  "Yank such that the first non-white character is at point.
Maintain relative indentation on all subsequent lines."
  (interactive)
  (let ((col (current-column)))
    (insert
     (with-temp-buffer
       (insert (dedent-string (current-kill 0)))
       (goto-char (point-min))
       (let* ((white (save-excursion (skip-chars-forward " ")
                                     (- (point) 1)))
              (offset (- col white)))
         (if (> offset 0)
             (progn
               (and (re-search-forward "\\` *")
                    (replace-match ""))
               (forward-char)
               (while (re-search-forward "^" nil t)
                 (replace-match (make-string offset ?\ ))))

           (and (re-search-forward "\\` *")
                (replace-match (make-string (- white col) ?\ )))))
       (buffer-string)))))


(provide 'dedent)
;;; dedent.el ends here