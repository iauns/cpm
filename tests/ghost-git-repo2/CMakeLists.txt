CMAKE_MINIMUM_REQUIRED(VERSION 2.8)
project (version-test)

#------------------------------------------------------------------------------
# Custom CPM setup (for tests). See https://github.com/iauns/cpm for real setup
#------------------------------------------------------------------------------
set(CPM_NO_UPDATE TRUE)
include(../../CPM.cmake)

set(source_dir "./v01")
CPM_AddModule("test_01"
  SOURCE_DIR ${source_dir}
  SOURCE_GHOST_GIT_REPO "https://github.com/iauns/CPM-test"
  SOURCE_GHOST_GIT_TAG "v0.1")

CPM_AddModule("module1" SOURCE_DIR "./repoModule1")
CPM_AddModule("module2" SOURCE_DIR "./repoModule2")

CPM_Finish()

file (GLOB source
  "*.cpp"
  "*.hpp"
  )

set(EXE_NAME cpm-test)
add_executable(${EXE_NAME} ${source})
target_link_libraries(${EXE_NAME} ${CPM_LIBRARIES})
