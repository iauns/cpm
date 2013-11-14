CMAKE_MINIMUM_REQUIRED(VERSION 2.8)
project (Foo)

#------------------------------------------------------------------------------
# Custom CPM setup (for tests). See https://github.com/iauns/cpm for real setup
#------------------------------------------------------------------------------
include(${CPM_DIR}/../../CPM.cmake)

# Include modules and externals. All modules must come before any project
# specific setup such as setting compiler flags. See the github readme for
# a full explanation.
CPM_AddModule("mongodb"
  GIT_REPOSITORY  "https://github.com/iauns/cpm-mongoc"
  GIT_TAG         "origin/master")

CPM_Finish()

