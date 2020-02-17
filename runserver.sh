#!/bin/bash

export PATH="~/bin:~/caveman_nagaoka/bin:$PATH:."
APP_ENV=development bin/clackup --address 0.0.0.0 --port 5000 app.lisp

