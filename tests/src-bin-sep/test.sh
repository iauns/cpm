#!/bin/bash
# We start in the CMake bin directory.
# Our source directory is given on the command line ($1).

# Change to the current script directory.
cd "$(dirname "$0")"

# The following disables exit script on failure.
set +e

# Move the CPM directory alongside our source directory. This is to test the
# case where makefile generated targets would have generated targets with
# periods at the beginning of the target name. This invalid target name occured
# in commit 9e8a062543dac31c86f975eca1e56dd8af320f63 and earlier.
rm -rf ./cpm-src
mkdir -p cpm-src
cp ../../* ./cpm-src/
cp -r ../../util ./cpm-src/

# Create bin directory and navigate into it.
mkdir -p bin
pushd ./bin > /dev/null

# Ensure script exits with failure if any command fails.
set -e

cmake -D_CPM_DEBUG_LOG=1 ..
make

set +e

# Pop bin directory.
popd > /dev/null
