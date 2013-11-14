CMAKE_MINIMUM_REQUIRED(VERSION 2.8)
project (Foo)

#------------------------------------------------------------------------------
# Required CPM Setup - See: http://github.com/iauns/cpm
#------------------------------------------------------------------------------
include(../../CPM.cmake)

# Include modules and externals. All modules must come before any project
# specific setup such as setting compiler flags. See the github readme for
# a full explanation.
CPM_AddModule("mongodb"
  GIT_REPOSITORY  "https://github.com/iauns/cpm-mongoc"
  GIT_TAG         "origin/master")

CPM_Finish()

