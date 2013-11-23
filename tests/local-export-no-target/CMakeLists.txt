CMAKE_MINIMUM_REQUIRED(VERSION 2.8)
project (version-test)

include(../../util/CMakeUnitTesting.cmake)

#------------------------------------------------------------------------------
# Custom CPM setup (for tests). See https://github.com/iauns/cpm for real setup
#------------------------------------------------------------------------------
set(CPM_NO_UPDATE TRUE)
include(../../CPM.cmake)

CPM_AddModule("module_1" SOURCE_DIR "./repoModule1")
CPM_AddModule("central" SOURCE_DIR "./centralModule")
CPM_PrintVariables()
# Exp module has been exported to us. So we ensure that we can see its 
# definitions and includesc

# Ensure only the expected directories are present in our include map.
set(EXPECTED_INCLUDE_DIRS 
  ${CMAKE_CURRENT_SOURCE_DIR}/centralModule/expModule/incdir1
  ${CMAKE_CURRENT_SOURCE_DIR}/centralModule/expModule/incdir2
  ${CMAKE_CURRENT_SOURCE_DIR}/centralModule/expModule
  )

CPM_VerifyListSubset(
  EXPECTED_INCLUDE_DIRS 
  CPM_INCLUDE_DIRS
  "CMAKE UNIT TESTING - include directory error: ")

set(EXPECTED_DEFINITIONS
  "-DINCDIR1_TEST"
  "-DINCDIR2_TEST"
  )

CPM_VerifyListSubset(
  EXPECTED_DEFINITIONS 
  CPM_DEFINITIONS
  "CMAKE UNIT TESTING - definition error: ")

CPM_Finish()

file (GLOB source
  "*.cpp"
  "*.hpp"
  )

set(EXE_NAME cpm-test)
add_executable(${EXE_NAME} ${source})
target_link_libraries(${EXE_NAME} ${CPM_LIBRARIES})
