(in-package :parser-combinators-debug)

;; printing

(defparameter *parser-debug-stream* *standard-output*
  "The stream to which messages from FORMAT? are directed.")

(defun format? (fmt &rest args)
  "Always successful zero width match with NIL as parse result, as a side effect prints the FMT
format string with arguments ARGS to the *PARSER-DEBUG-STREAM*."
  (define-oneshot-result inp is-unread
    (apply #'format *parser-debug-stream* fmt args)
    (make-instance 'parser-possibility
                   :tree nil :suffix inp)))

;; human-readable position: line, column

(defparameter *position-cache* nil)

(defmacro with-position-cache ((cache string) &body body)
  "Execute BODY within dynamic extent, where the position cache is established for the STRING
being parsed.  The resulting cache is also lexically bound to CACHE."
  `(let* ((,cache (make-string-position-cache ,string))
          (*position-cache* ,cache))
     ,@body))

(defun make-string-position-cache (string)
  (let ((cache (make-instance 'cl-containers:red-black-tree :key #'car)))
    (if (zerop (length string))
        (cl-containers:insert-item cache (cons 0 0))
        (iter (with lineno = 0)
              (for posn from 0)
              (for char in-string string)
              (for pchar previous char initially #\Newline)
              (when (char= pchar #\Newline)
                (cl-containers:insert-item cache (cons posn lineno))
                (incf lineno))))
    cache))

(defun string-position-context (cache offset &key (around 0))
  (let* ((succ (cl-containers:find-successor-node cache (cons (1+ offset) nil)))
         (pred (if succ
                   (cl-containers:predecessor cache succ)
                   (cl-containers::last-node cache))))
    (labels ((wind-rec (node n fn)
               (if (plusp n)
                   (or (when-let ((prev (funcall fn cache node)))
                         (when (cl-containers:element prev)
                           ;; ACHTUNG!! this is a bug in CL-CONTAINERS!
                           (wind-rec prev (1- n) fn)))
                       node)
                   node))
             (wind (node n fn)
               (let ((ret (wind-rec node n fn)))
                 (assert ret)
                 (cl-containers:element ret))))
      (destructuring-bind (lposn . lineno) (cl-containers:element pred)
        (values lineno lposn
                (car (wind pred around      #'cl-containers:predecessor))
                (1-
                 (car (wind pred (1+ around) #'cl-containers:successor))))))))

(defun string-position (offset)
  "Given a dynamically-established string position cache, convert the provided string OFFSET
into its corresponding line and column numbers, which are returned as the first and second
values, correspondingly."
  (multiple-value-bind (lineno line-offset)
      (string-position-context *position-cache* offset)
    (values lineno (- offset line-offset))))

(defmacro with-posn-info? ((charvar linevar colvar) &body body)
  "Utility macro: every time the parser is being matched, evaluate BODY in lexical context,
where CHARVAR, LINEVAR and COLVAR are bound to the current line, column and next character.

Does not advance the position."
  (with-gensyms (inp unreadp)
    `(lambda (,inp)
       (let ((,unreadp t))
         (lambda ()
           (let ((,charvar (parser-combinators::context-peek ,inp)))
             (declare (ignorable ,charvar))
             (multiple-value-bind (,linevar ,colvar)
                 (string-position (position-of ,inp))
               (declare (ignorable ,colvar))
               (let ((,linevar (1+ ,linevar)))
                 (declare (ignorable ,linevar))
                 ,@body)))
           (when ,unreadp
             (setf ,unreadp nil)
             (make-instance 'parser-possibility :tree ,inp :suffix ,inp)))))))

;; this silences the past-EOF peek warnings generated by the above
(defmethod parser-combinators::context-peek ((context end-context))
  nil)

;; end-user tools
 
(defvar *debug-mode* nil
  "Whether the CHECK? forms should trace the parsers they surround.")

(defvar *debug-print-result* nil
  "Whether the CHECK? form tracing should include parse results.")

(defun call-with-maybe-tracing (tracep mark fn)
  (if tracep
      (named-seq*
       (with-posn-info? (char line col)
         (format t "~S ? (next ~S, line:col ~D:~D)~%" mark char line col))
       (<- res (funcall fn))
       (progn
         (format t "~S ok~:[~; - ~S~]~%" mark *debug-print-result* res)
         res))
      (funcall fn)))

(defmacro check? (x)
  "Utility macro: every time the parser is being matched prints a message to *PARSER-DEBUG-STREAM*,
before a match attempt and after a successul match, but only if *DEBUG-MODE* is non-NIL.
The parser is printed in source form, accompanied with the line/column and next character."
  `(call-with-maybe-tracing *debug-mode* ',x (lambda () ,x)))

(defmacro c? (form)
  "An ergonomic shortcut for CHECK?"
  `(check? ,form))
