;;; org-transform-tree-table.el --- Transform org-mode tree with properties to a table, and the other way around

;; Copyright © 2014 Johan Lindstrom
;;
;; Author: Johan Lindstrom <buzzwordninja not_this_bit@googlemail.com>
;; URL: https://github.com/jplindstrom/emacs-org-transform-tree-table
;; Version: 0.1.0
;; Package-Requires: ((dash "2.10.0") (s "1.3.0"))
;; Keywords: org-mode table org-table tree csv convert

;; This program is free software: you can redistribute it and/or modify
;; it under the terms of the GNU General Public License as published by
;; the Free Software Foundation, either version 3 of the License, or
;; (at your option) any later version.

;; This program is distributed in the hope that it will be useful,
;; but WITHOUT ANY WARRANTY; without even the implied warranty of
;; MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
;; GNU General Public License for more details.

;; You should have received a copy of the GNU General Public License
;; along with this program.  If not, see <http://www.gnu.org/licenses/>.

;; This file is not part of GNU Emacs.

;;
;;; Commentary:
;;
;; Transform an org-mode outline and its properties to a table format
;; (org-table, CSV).

;; This makes it possible to have an outline with properties and work
;; with it in column view. Then you can transform the outline to a table
;; to share with others (export to CSV and open in Excel).

;; More about column view:

;; * http://orgmode.org/worg/org-tutorials/org-column-view-tutorial.html
;; * http://orgmode.org/worg/org-tutorials/org-column-view-tutorial.html


;;; Usage

;; ### From org tree to table

;;     ;; Org outline to an org table
;;     M-x org-transform-tree/org-table-buffer-from-outline

;;     ;; Org outline to CSV (or rather, tab-separated value)
;;     M-x org-transform-tree/csv-table-buffer-from-outline

;; If the region is active, convert that part of the
;; tree. Otherwise, if point is on an org heading, convert that
;; heading and its subtree. Otherwise convert the buffer.

;; In the resulting table, row one is the column titles. The rest of
;; the rows are property values.

;; Column one is the outline heading, and the rest are the
;; properties in the order they first appear in the buffer.

;; However, all special properties (e.g. 'COLUMNS', '*_ALL') are
;; placed after all the user properties (i.e. whatever properties
;; the user has added to capture information).


;; ### From table to org tree

;;     ;; From an org table to an org outline
;;     M-x org-transform-table/org-tree-buffer-from-org-table

;;     ;; From CSV (tab separated) to an org outline
;;     M-x org-transform-table/org-tree-buffer-from-csv

;; When converting from an org table, point must be on a table.

;; When converting CSV, convert the buffer.

;; ## Tiny example

;; This outline:

;;     * Pages
;;       :PROPERTIES:
;;       :COLUMNS:  %30ITEM %10Access %10Cost
;;       :END:
;;     ** Products
;;        :PROPERTIES:
;;        :Access:   All
;;        :END:
;;     *** Free Widget
;;         :PROPERTIES:
;;         :Access:   All
;;         :END:
;;     *** Paid Thingy
;;         :PROPERTIES:
;;         :Access:   Paid
;;         :Cost:     30
;;         :END:

;; Transforms into:

;;     | Heading         | Access | Cost | COLUMNS                   |
;;     | * Pages         |        |      | %30ITEM %10Access %10Cost |
;;     | ** Products     | All    |      |                           |
;;     | *** Free Widget | All    |      |                           |
;;     | *** Paid Thingy | Paid   |   30 |                           |

;; Note that the special property COLUMNS are out on the right, to be out
;; of the way when the table is being edited in e.g. Excel or Open
;; Office.

;; This also means the transformation is only 99% round-trip safe and the
;; first time you go back to a tree representation, you'll get more diffs
;; than subsequent ones.


;;; Installation

;; Install org-transform-tree using MELPA.

;; Or clone the repo into somewhere in the load-path. 

;;     git clone https://github.com/jplindstrom/emacs-org-transform-tree-table.git

;; and initialize with:

;;    (require 'org-transform-tree-table)


;;; Changes
;;
;; 2014-12-23 - 0.1.1
;;
;; * Initial release

;;; Code:



(require 'dash)
(require 's)



;; interactive defuns

;;;###autoload
(defun org-transform-tree/org-table-buffer-from-outline ()
  "Transform an org tree to an org-table and return a new buffer
with the table.

If the region is active, convert that part of the
tree. Otherwise, if point is on an org heading, convert that
heading and its subtree. Otherwise convert the buffer.

In the resulting table, row one is the column titles. The rest of
the rows are property values.

Column one is the outline heading, and the rest are the
properties in the order they first appear in the buffer.

However, all special properties (e.g. 'COLUMNS', '*_ALL') are
placed after all the user properties (i.e. whatever properties
the user has added to capture information)."
  (interactive)
  (ott/render-new-buffer-from-rows-cols
   "-table.org"
   (ott/org-tree/parse-rows-cols)
   'ott/org-table/render-rows-cols)
  )

;;;###autoload
(defun org-transform-tree/csv-buffer-from-outline ()
  "Transform an org tree to CSV format and return a new buffer
with the table.

Except it's not comma separated. It's tab separated because with
all (non) 'standard' ways to escape ',' in CSV files... let's not
even go there.

If the region is active, convert that part of the
tree. Otherwise, if point is on an org heading, convert that
heading and its subtree. Otherwise convert the buffer.

In the resulting table, row one is the column titles. The rest of
the rows are property values.

Column one is the outline heading, and the rest are the
properties in the order they first appear in the buffer.

However, all special properties (e.g. 'COLUMNS', '*_ALL') are
placed after all the user properties (i.e. whatever properties
the user has added to capture information)."
  (interactive)
  (ott/render-new-buffer-from-rows-cols
   ".csv"
   (ott/org-tree/parse-rows-cols)
   'ott/csv-table/render-rows-cols)
  )

;;;###autoload
(defun org-transform-table/org-tree-buffer-from-org-table ()
  "Transform the org-table at point to an org-mode outline and
return a new buffer with the new tree.

Raise an error if point isn't on an org-table."
  (interactive)
  (ott/render-new-buffer-from-rows-cols
   "-tree.org"
   (ott/org-table/parse-rows-cols)
   'ott/org-tree/render-rows-cols)
  )

;;;###autoload
(defun org-transform-table/org-tree-buffer-from-csv ()
  "Transform the buffer CSV table to an org-mode outline and
return a new buffer with the new tree."
  (interactive)
  (ott/render-new-buffer-from-rows-cols
   "-tree.csv"
   (ott/csv-table/parse-rows-cols)
   'ott/org-tree/render-rows-cols)
  )



;; Main

(defun ott/render-new-buffer-from-rows-cols (type rows-cols render-fun)
  "Render ROWS-COLS to a table using RENDER-FUN and return a new
buffer with the table. Name the new buffer after the current
buffer file name and TYPE."
  (let* ((target-buffer
          (get-buffer-create (concat (buffer-name) type)) ;; Use the other one later
          ;; (create-file-buffer (concat (or (buffer-file-name) "new") type))
          ))
    (with-current-buffer target-buffer
      (funcall render-fun rows-cols))

    (switch-to-buffer target-buffer)
    (goto-char (point-min))

    target-buffer
    ))



;; render/parse org tree

(defun ott/org-tree/parse-rows-cols ()
  "Return a list of rows, with a list of columns from the org
tree.

Row one is the column titles.

Column one is the outline heading, and the rest are the
properties as they appear in the buffer.

However, all special properties (e.g. 'COLUMNS', '*_ALL') are
placed after all the user properties (i.e. whatever property
keys/values the user is edi property keys/values the user is
editing."
  (interactive)
  (save-excursion
    (let* (
           (ordered-property-keys
            (ott/org-tree/user-then-special-property-keys
             (ott/org-tree/unique-propery-keys-in-buffer-order)))

           (col-title-values (cons "Heading" ordered-property-keys))

           (row-col-data-values
            (ott/org-tree/row-col-property-values ordered-property-keys))
           )
      (cons
       col-title-values
       row-col-data-values)
      )
    )
  )

(defun ott/org-tree/render-rows-cols (rows-cols)
  "Insert an org-tree with the ROWS-COLS."
  (erase-buffer) ;; JPL: remove later
  (org-mode)
  (let* (
         (data-rows-cols (cdr rows-cols))
         (title-row (car rows-cols))
         ;; All but the first item, which is the Heading title col
         (property-title-cols (cdr title-row))
         ;; Reverse, to render the special cols first in the drawer
         (reverse-property-title-cols (reverse property-title-cols))
         )

    (dolist (row-cols data-rows-cols)
      (let* (
             (heading-col (car row-cols))
             (property-cols (cdr row-cols))
             )

        ;; Insert heading
        (insert (concat heading-col "\n"))

        ;; Set properties
        ;; Reverse to render special ones first
        (--zip-with
         (when (and other (not (string= other "")))
           ;;JPL: escape properties? or is that done by org-entry-put?
           (org-entry-put nil it other)
           )
         reverse-property-title-cols
         (reverse property-cols))

        (outline-next-heading)
        )
      )
    )
  )

(defun ott/org-tree/row-col-property-values (property-keys)
  "Return list of rows with a list of columns that are property
values for the PROPERTY-KEYS for each tree heading."
  (ott/org-tree/map-entries
   (lambda ()
     (cons
      (ott/org-tree/level-and-heading (org-heading-components)) ; Heading
      (ott/org-tree/current-property-values-from-keys property-keys)))
   )
  )

(defun ott/org-tree/active-scope ()
  "Return a scope modifier depending on whether the region is
active, or whether point is on a org heading, or not."
  (if (org-region-active-p) 'region
    (if (org-at-heading-p) 'tree
      nil))) ;; Entire buffer

(defun ott/org-tree/map-entries (fun)
  "Run org-map-entries with FUN in the active scope"
    (org-map-entries fun nil (ott/org-tree/active-scope)))

(defun ott/org-tree/level-and-heading (heading-components)
  "Return the *** level and the heading text of
ORG-HEADING-COMPONENTS"
  (let ((level (nth 1 heading-components))
        (heading-text (nth 4 heading-components)))
    (concat (make-string level ?*) " " heading-text)))

(defun ott/org-tree/current-property-values-from-keys (property-keys)
  "Return list of values (possibly nil) for each property in
PROPERTY-KEYS."
  (mapcar
   (lambda (key)
     (alist-value (org-entry-properties nil 'standard key) key))
   property-keys))

(defun ott/org-tree/unique-propery-keys-in-buffer-order ()
  "Return list of all unique property keys used in drawers. They
are in the order they appear in the buffer."
  (let* ((entries-keys
          (ott/org-tree/map-entries
           (lambda () (mapcar 'car (org-entry-properties nil 'standard)))))
         (all-keys '())
         )
    (dolist (keys entries-keys)
      (dolist (key keys)
        (add-to-list 'all-keys key t)))

    ;; Not sure why this one appears here. Are there others?
    (-remove (lambda (x) (string= x "CATEGORY")) all-keys)
    )
  )

(defun ott/org-tree/user-then-special-property-keys (property-keys)
  "Return list with items in PROPERTY-KEYS, but where all column
properties are first and all special properties are at the end.

Column properties are properties the user would normally enter.

Special properties are things like 'COLUMNS' or 'Someting_ALL',
which are instructions for org-mode. They should typically go at
the end and not mix with the actual data."
  (-flatten (-separate 'ott/org-tree/is-col-property property-keys)))

(defun ott/org-tree/is-col-property (key)
  "Is KEY a column / user-data level property?"
  (if (string= key "COLUMNS") nil
    (if (string-match "._ALL$" key) nil
      t)))



;; render/parse org table

(defun ott/org-table/parse-rows-cols ()
  "Parse the org-table at point and return a list of rows with a
list of cols.

If there isn't an org-table at point, raise an error."
  (when (not (org-at-table-p)) (error "Not in an org table"))
  (let* ((beg (org-table-begin))
         (end (org-table-end))
         (table-text (buffer-substring-no-properties beg end))
         (lines (org-split-string table-text "[ \t]*\n[ \t]*"))
         ;; JPL: ignore horizontal lines
         (rows-cols
          (mapcar
           (lambda (line)
             ;;JPL: unescape e.g. \vert
             (org-split-string (org-trim line) "\\s-*|\\s-*")
             )
           lines))
         )
    rows-cols))

(defun ott/org-table/render-rows-cols (rows-cols)
  "Insert an org-table with the ROWS-COLS."
    (erase-buffer) ;; JPL: remove later
    (org-mode)
    (--each rows-cols
      (ott/org-table/insert-values-as-table-row it))
    (org-table-align)
  )

(defun ott/org-table/insert-values-as-table-row (col-values)
  "Insert escaped COL-VALUES using the org-table format."
  (insert "|")
  (dolist (value col-values)
    (insert (concat " " (ott/org-table/escape-value value) " |"))
    )
  (insert "\n")
  )

(defun ott/org-table/escape-value (value)
  "Return VALUE but suitable to put in a table value. Return an
empty string for nil values."
  (if value
      (replace-regexp-in-string "|" "\\\\vert{}" value)
    ""))



;; Render/parse CSV table (tab separated)

(defun ott/csv-table/parse-rows-cols ()
  "Parse the buffer CSV table (tab separated) and return a list
of rows with a list of cols.

If there isn't an org-table at point, raise an error."
  (let* (
         (table-text (buffer-substring-no-properties (point-min) (point-max)))
         (lines (org-split-string table-text "\n"))
         (rows-cols
          (mapcar
           (lambda (line)
             (org-split-string (org-trim line) "\t")
             )
           lines))
         )
    rows-cols))

(defun ott/csv-table/render-rows-cols (rows-cols)
  "Insert a CSV table with the ROWS-COLS."
    (erase-buffer) ;; JPL: remove later
    (--each rows-cols
      (ott/csv-table/insert-values-as-table-row it))
  )

(defun ott/csv-table/insert-values-as-table-row (col-values)
  "Insert escaped COL-VALUES using CSV format (tab separated)."
  (insert
   (s-join "\t" (mapcar 'ott/csv-table/escape-value col-values)))
  (insert "\n")
  )

(defun ott/csv-table/escape-value (value)
  "Return VALUE but suitable to put in a CSV file. Return an
empty string for nil values."
  (if value
      value
    ""))




;; Test

;; (ert-run-tests-interactively "^ott-")

;; (set-buffer "expected-org-table1--tree.org")
;; (org-transform-table/org-tree-buffer-from-org-table)

;; (set-buffer "table1.csv")
;; (org-transform-table/org-tree-buffer-from-csv)

;; (set-buffer "tree1.org")
;; (org-transform-tree/org-table-buffer-from-outline)

;; (set-buffer "tree1.org")
;; (org-transform-tree/csv-buffer-from-outline)




(provide 'org-transform-tree-table)

;;; org-transform-tree-table.el ends here
