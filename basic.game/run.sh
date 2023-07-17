#!/bin/bash

set -eu

echo Checking suika-replay
replay_cmd=`readlink -f ../../build/linux-x86_64-replay/suika-replay`

echo Checking compare.py
compare_cmd=`readlink -f ../../build/linux-x86_64-replay/compare.py`

for dir in `ls -d *.record`; do
    echo -n "  Running $dir..."
    dir=`readlink -f $dir`
    cd game && \
    rm -rf replay && \
    $replay_cmd $dir && \
    python3 $compare_cmd $dir replay \
    rm -rf replay sav log.txt
    echo "passed."
done
