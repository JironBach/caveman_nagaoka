(in-package :cl-user)
(defpackage nagaoka.web
  (:use :cl
        :caveman2
        :nagaoka.config
        :nagaoka.view
        :nagaoka.db
        :datafly
        :sxql)
  (:export :*web*))
(in-package :nagaoka.web)

;; for @route annotation
(syntax:use-syntax :annot)

;;
;; Application

(defclass <web> (<app>) ())
(defvar *web* (make-instance '<web>))
(clear-routing-rules *web*)

;;
;; Routing rules
(defroute "/" ()
  (render #P"index.html"))
(defroute "/home" ()
  (render #P"index.html"))
(defroute "/examples" ()
  (render #P"examples.html"))
(defroute "/page" ()
  (render #P"page.html"))
(defroute "/another_page" ()
  (render #P"another_page.html"))
(defroute "/contact" ()
  (render #P"contact.html"))

;;
;; Error pages

(defmethod on-exception ((app <web>) (code (eql 404)))
  (declare (ignore app))
  (merge-pathnames #P"_errors/404.html"
                   *template-directory*))
