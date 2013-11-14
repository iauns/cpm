CMAKE_MINIMUM_REQUIRED(VERSION 2.8)
project (Foo)

#------------------------------------------------------------------------------
# Custom CPM setup (for tests). See https://github.com/iauns/cpm for real setup
#------------------------------------------------------------------------------
set(CPM_NO_UPDATE TRUE)
include(../../CPM.cmake)

CPM_AddModule("module1" SOURCE_DIR "./module1")

CPM_Finish()

