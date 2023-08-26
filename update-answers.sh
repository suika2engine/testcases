#!/bin/bash

set -eu

echo "Checking for suika-replay binary."

replay_cmd=`readlink -f ../build/linux-x86_64-replay/suika-replay`
if [ ! -e $replay_cmd ]; then
    echo "Error: Please build suika-replay first."
    exit 1;
fi

echo "Remaking tests."

tc_count=0

# For each game.
for testdata in `ls -d *.data`; do
    echo "Entering game $testdata"

    # For each record.
    for testcase in `ls -d $testdata/*.record`; do
	echo "Running `basename $testcase`";

	# Remove garbage.
        rm -rf $testdata/game/replay $testdata/game/sav $testdata/game/log.txt $testcase/*.png $testcase/*.webp;

	# Run.
	cd $testdata/game && \
	    xvfb-run -a --server-args="-screen 0 1920x1080x24" $replay_cmd ../`basename $testcase` && \
	cd ../../;

	# Move PNG files to the record directory.
	mv $testdata/game/replay/*.png $testcase/;

	# Remove garbage.
        rm -rf $testdata/game/replay testdata/game/sav testdata/game/log.txt;

	# Increment the test case count.
	tc_count=`expr $tc_count + 1`;
    done
done

echo "Compressing png files to webp files."

PARALLEL=`nproc --all`

# For each game.
for testdata in `ls -d *.data`; do
    # For each record.
    for testcase in `ls -d $testdata/*.record`; do
	i=0;
	for png in `ls $testcase/*.png`; do
	    # Do barrier synchronization for every $PARALLEL processes.
	    i=`expr $i % $PARALLEL`;
	    i=`expr $i + 1`;
 	    if [ $i -eq "0" ]; then
	       wait;
	    fi

	    # Convert PNG to WEBP (as a background job).
	    convert $png -define webp:lossless=true -define webp:method=6 $testcase/`basename ${png%.png}.webp` &
	done

	# Synchronize the unfinished jobs.
	wait;

	# Remove PNG.
	rm $testcase/*.png;
    done
done

echo "Total test cases updated: $tc_count"
