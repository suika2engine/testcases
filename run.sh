#!/bin/bash

set -eu

for dir in `ls -d *.testcase`; do
    echo Entering directory $dir
    cd $dir && ./run.sh
done