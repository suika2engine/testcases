#!/bin/bash

start_time=`date +'%s'`

# Checking for suika-replay binary.
replay_cmd=`readlink -f ../build/linux-x86_64-replay/suika-replay`
if [ ! -e $replay_cmd ]; then
    echo "Info: Building suika-replay.";
    pushd . && cd ../build/linux-x86_64-replay && make && popd;
    if [ -e $replay_cmd ]; then
	echo "Error: Failed to build suika-replay binary."
	exit 1;
    fi
fi

# Remove existing profile data.
rm -rf ../build/linux-x86_64-replay/*.gcda ../build/linux-x86_64-replay/sav

# Remove existing failed data.
rm -rf failed-*

# Remove existing report.
rm -rf report

# Run.
echo "Running test cases."

tc_count=0
tc_success=0
tc_fail=0

# For each game.
for testdata in `ls -d *.data`; do
    echo "  Entering $testdata"

    # For each record.
    for testcase in `ls -d $testdata/*.record`; do
	echo "    Running `basename $testcase`";

	# Remove garbage.
        rm -rf $testdata/game/replay $testdata/game/sav $testdata/game/log.txt;

	# Run.
	if [ "$1" = "--no-x11" ]; then
	    cd $testdata/game && \
		xvfb-run -a --server-args="-screen 0 1920x1080x24" $replay_cmd ../`basename $testcase` && \
	    cd ../../;
	else
	    cd $testdata/game && \
		$X_CMD $replay_cmd ../`basename $testcase` && \
	    cd ../../;
	fi

	# Compare the image pairs of an answer (webp) and a result (png).
	echo -n "      Comparing..."
	python3 compare.py $testcase $testdata/game/replay $fail_dir failed-`basename $testdata`-`basename $testcase`
	if [ $? != 0 ]; then
	   echo "failed.";

	   # Increment the failed count.
	   tc_fail=`expr $tc_fail + 1`;
	else
	   echo "succeeded.";

	   # Increment the successed count.
	   tc_success=`expr $tc_success + 1`;
	fi

	# Remove garbage.
        rm -rf $testdata/game/replay testdata/game/sav testdata/game/log.txt;

	# Increment the test case count.
	tc_count=`expr $tc_count + 1`;
    done
done

# Print the result.
echo ""
echo "Total test cases: $tc_count"
echo "  Succeeded: $tc_success"
echo "  Failed:    $tc_fail"
echo ""
if [ "$tc_count" -ne "$tc_success" ]; then
    echo "Test failed.";
    exit 1;
fi

# Make a coverage report.
cd ../build/linux-x86_64-replay && \
    lcov -d . --rc lcov_branch_coverage=1 -c -o app.info > /dev/null 2>&1 && \
    sed -i s+`pwd`+`readlink -f ../../src`+g app.info && \
    lcov -r app.info -o app.info --rc lcov_branch_coverage=1 '/usr/include/*' > /dev/null 2>&1 && \
    lcov --summary --rc lcov_branch_coverage=1 app.info | tail -n +2 && \
    genhtml -o lcovoutput -p `pwd` --num-spaces 4 --rc lcov_branch_coverage=1 -f app.info > /dev/null 2>&1 && \
cd ../../testcases
mv ../build/linux-x86_64-replay/lcovoutput ./report

# Print the lap time.
end_time=`date +'%s'`
lap=`expr $end_time - $start_time`
hours=`expr $lap / 3600`
minutes=`expr \( $lap - $hours \* 3600 \) / 60`
seconds=`expr $lap % 60`
echo ""
echo -n "All passed. (in"
if [ $hours -gt 0 ]; then echo -n " $hours hours"; fi
if [ $minutes -gt 0 ]; then echo -n " $minutes minutes"; fi
if [ $seconds -gt 0 ]; then echo -n " $seconds seconds"; fi
echo ")"

exit 0
