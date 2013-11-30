CMAKE_MINIMUM_REQUIRED(VERSION 2.8)
project (version-test)

#------------------------------------------------------------------------------
# Custom CPM setup (for tests). See https://github.com/iauns/cpm for real setup
#------------------------------------------------------------------------------
set(CPM_NO_UPDATE TRUE)
include(../../CPM.cmake)

CPM_AddModule("module1" SOURCE_DIR "./repoModule1")
CPM_AddModule("module2" SOURCE_DIR "./repoModule2")

# Purposefully added .git onto the end of this repo name. It will be removed
# by CPM.
CPM_AddModule("test_01"
  GIT_REPOSITORY "https://github.com/iauns/cpm-test.git"
  GIT_TAG "origin/master")

CPM_Finish()

file (GLOB source
  "*.cpp"
  "*.hpp"
  )

set(EXE_NAME cpm-test)
add_executable(${EXE_NAME} ${source})
target_link_libraries(${EXE_NAME} ${CPM_LIBRARIES})
