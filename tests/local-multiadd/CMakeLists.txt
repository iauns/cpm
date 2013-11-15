CMAKE_MINIMUM_REQUIRED(VERSION 2.8)
project (version-test)

#------------------------------------------------------------------------------
# Custom CPM setup (for tests). See https://github.com/iauns/cpm for real setup
#------------------------------------------------------------------------------
set(CPM_NO_UPDATE TRUE)
include(../../CPM.cmake)

CPM_AddModule("module_1" SOURCE_DIR "./repoModule1")
CPM_AddModule("module_2" SOURCE_DIR "./repoModule2")
CPM_AddModule("module_3" SOURCE_DIR "./repoModule3")
CPM_AddModule("central" SOURCE_DIR "./centralModule")

CPM_Finish()

file (GLOB source
  "*.cpp"
  "*.hpp"
  )

set(EXE_NAME cpm-test)
add_executable(${EXE_NAME} ${source})
target_link_libraries(${EXE_NAME} ${CPM_LIBRARIES})
