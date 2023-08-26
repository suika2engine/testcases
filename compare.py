import cv2
import numpy as np
import sys
import os
import glob
import shutil
import subprocess

answer_dir = sys.argv[1]
result_dir = sys.argv[2]
diff_dir = sys.argv[3]

error_count=0

files = glob.glob(answer_dir + "/*.webp")
for file in files:
    basename = os.path.basename(file)
    answer_file = answer_dir + "/" + basename
    result_file = result_dir + "/" + os.path.splitext(basename)[0] + ".png"

    # Read images.
    answer_img = cv2.imread(answer_file)
    result_img = cv2.imread(result_file)

    # Read the images.
    answer_img = cv2.imread(answer_file)
    result_img = cv2.imread(result_file)

    # Get ndarrays.
    answer_array = np.asarray(answer_img).astype(np.float32)
    result_array = np.asarray(result_img).astype(np.float32)

    # Get delta.
    diff_array = answer_array - result_array
    delta = diff_array.max()

    # If they are different:
    if delta > 0:
        # Write a difference image.
        if not os.path.isdir(diff_dir):
            os.mkdir(diff_dir)
        shutil.copyfile(answer_file, diff_dir + "/" + os.path.splitext(basename)[0] + "-answer.webp")
        shutil.copyfile(result_file, diff_dir + "/" + os.path.splitext(basename)[0] + "-result.png")
        subprocess.run(["compare",
                        "-quiet",
                        "-metric",
                        "AE",
                        answer_file,
                        result_file,
                        diff_dir + "/" + os.path.splitext(basename)[0] + "-diff.png"],
                       stdout = subprocess.DEVNULL,
                       stderr = subprocess.DEVNULL)
        error_count = error_count + 1

# Make a return code.
if error_count > 0:
    sys.exit(1)
else:
    sys.exit(0)
