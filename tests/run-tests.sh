#!/bin/bash
cd "$(dirname "$0")"

./clean-tests.sh

# Terminate the script as soon as any command fails.
set -e

TESTNAME=$1

function RunTest
{
  dir=$1

  # Strips off ./ at the beginning.
  dirOnly=${dir##*/}

  binDir=bin-${dirOnly}
  mkdir ${binDir}

  echo ""
  echo " -- "
  echo " == RUNNING: ${dirOnly}"
  echo " -- "
  echo ""
  pushd ${binDir} > /dev/null
  if [ -f ../${dirOnly}/test.sh ]; then
    ../${dirOnly}/test.sh ../${dirOnly}
    set -e
  else
    cmake -DCPM_MODULE_CACHE_DIR=${HOME}/.cpm_cache -D_CPM_DEBUG_LOG=1 ../${dirOnly}
    #VERBOSE=1 make
    make
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
}

if [[ -z "$TESTNAME" ]]; then
  for dir in ./*/
  do
    dir=${dir%*/}

    RunTest $dir
  done
else
  RunTest $TESTNAME
fi
