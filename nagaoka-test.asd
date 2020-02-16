(defsystem "nagaoka-test"
  :defsystem-depends-on ("prove-asdf")
  :author "JironBach"
  :license ""
  :depends-on ("nagaoka"
               "prove")
  :components ((:module "tests"
                :components
                ((:test-file "nagaoka"))))
  :description "Test system for nagaoka"
  :perform (test-op (op c) (symbol-call :prove-asdf :run-test-system c)))
