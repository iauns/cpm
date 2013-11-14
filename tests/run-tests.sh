#!/bin/bash
cd "$(dirname "$0")"

./clean-tests.sh

# Terminate the script as soon as any command fails.
set -e

for dir in ./*/
do
  dir=${dir%*/}

  # Strips off ./ at the beginning.
  dirOnly=${dir##*/}

  binDir=bin-${dirOnly}
  mkdir ${binDir}

  echo ""
  echo "RUNNING: ${dirOnly}"
  echo ""
  pushd ${binDir} > /dev/null
    if [ -f ../${dirOnly}/test.sh ]; then
      ../${dirOnly}/test.sh ../${dirOnly}
      set -e
    else
      cmake ../${dirOnly}
      VERBOSE=1 make
    fi
    if [ -f ./cpm-test ]; then
      echo ""
      echo "COMMAND OUTPUT: "
      ./cpm-test
      echo ""
    fi
  popd > /dev/null

  # Remove the bin directory.
  rm -rf ${binDir}

  # Remove the 'modules' directory. This directory is automatically created
  # by CPM when running the test since we use the root directory as the CPM
  # directory.
  rm -rf ../modules
done
