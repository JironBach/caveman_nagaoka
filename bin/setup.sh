#!/bin/bash

cd ~/caveman_nagaoka
git clone https://github.com/roswell/roswell
cd roswell
./bootstrap && ./configure && make
make install
ros setup

echo "(quicklisp-quickstart:install)"
ros --load ~/caveman_nagaoka/bin/quicklisp.lisp

