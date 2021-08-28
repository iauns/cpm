#!/bin/bash
# We start in the CMake bin directory.
# Our source directory is given on the command line ($1).

SOURCE_DIR=$1

set +e

cmake ${SOURCE_DIR} || true
rc=$?
if [ $rc -ne 0 ]; then
  # We are successful if we fail to configure (conflicting namespaces).
  echo -ne "\nSUCCESS: Failed to cmake with conflicting namespaces.\n\n"
  exit 0
else
  echo -ne "\nFAILED: Shouldn't be able to successfully configure on a project with conflicting namespaces.\n\n"
  exit 1
fi
