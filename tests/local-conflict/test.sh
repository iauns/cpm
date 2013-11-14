#!/bin/bash
# We start in the bin directory which we should call CMake from.
# Our source directory is given on the command line in $1.

SOURCE_DIR=$1

set +e

cmake ${SOURCE_DIR}
rc=$?
if [[ $rc != 0 ]]; then
  # We are successful if we fail to configure (conflicting namespaces).
  echo ""
  echo "SUCCESS: Failed to cmake with conflicting namespaces."
  echo ""
  exit 0
else
  echo ""
  echo "FAILED: Shouldn't be able to successfully configure on a project with conflicting namespaces."
  echo ""
  exit 1
fi
