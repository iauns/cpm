CMAKE_MINIMUM_REQUIRED(VERSION 2.8)
project (version-test)

include(../../util/CMakeUnitTesting.cmake)

# This file represents the 'test' that would be using gl-batch-testing
# We should only need to include gl-batch testing which should export
# everything to us.

#------------------------------------------------------------------------------
# Custom CPM setup (for tests). See https://github.com/iauns/cpm for real setup
#------------------------------------------------------------------------------
set(CPM_NO_UPDATE TRUE)
include(../../CPM.cmake)

CPM_AddModule("gl_batch_testing"
  SOURCE_DIR "./gl-batch-testing")
CPM_PrintVariables()

CPM_Finish()

file (GLOB source
  "*.cpp"
  "*.hpp"
  )

set(EXE_NAME cpm-test)
add_executable(${EXE_NAME} ${source})
target_link_libraries(${EXE_NAME} ${CPM_LIBRARIES})
