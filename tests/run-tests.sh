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
  mkdir ${binDir}

  pushd ${binDir} > /dev/null
    echo ../${dirOnly}
    cmake ../${dirOnly}
    make
  popd > /dev/null

  rm -rf ${binDir}

done
