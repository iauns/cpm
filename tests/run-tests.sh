#!/bin/bash
cd "$(dirname "$0")"

# Terminate the script as soon as any command fails.
set -e

for dir in ./*/
do
  dir=${dir%*/}

  # Strips off ./ at the beginning.
  dirOnly=${dir##*/}
  echo ${dirOnly}

  binDir=bin-${dirOnly}
  rm -rf ${binDir} && true
  mkdir ${binDir}

  pushd ${binDir} > /dev/null
    echo ../${dirOnly}
    cmake ../${dirOnly}
    make
  popd > /dev/null

  # Remove the bin directory.
  rm -rf ${binDir}

  # Remove the 'modules' directory. This directory is automatically created
  # by CPM when running the test since we use the root directory as the CPM
  # directory.
  rm -rf ../modules
done
