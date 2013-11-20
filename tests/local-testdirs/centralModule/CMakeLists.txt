CMAKE_MINIMUM_REQUIRED(VERSION 2.8)

include(../../../util/CMakeUnitTesting.cmake)

#------------------------------------------------------------------------------
# Custom CPM setup (for tests). See https://github.com/iauns/cpm for real setup
#------------------------------------------------------------------------------
set(CPM_MODULE_NAME "central")
set(CPM_LIB_TARGET_NAME ${CPM_MODULE_NAME})

if ((DEFINED CPM_DIR) AND (DEFINED CPM_UNIQUE_ID) AND (DEFINED CPM_TARGET_NAME))
  set(CPM_LIB_TARGET_NAME ${CPM_TARGET_NAME})
  set(CMAKE_MODULE_PATH ${CMAKE_MODULE_PATH} ${CPM_DIR})
  include(CPM)
else()
  include(../../../CPM.cmake)
endif()

CPM_AddModule("central_exp"
  SOURCE_DIR "./expModule"
  EXPORT_MODULE TRUE)
CPM_PrintVariables()

# Ensure only the expected directories are present in our include map.
set(EXPECTED_INCLUDE_DIRS 
  ${CMAKE_CURRENT_SOURCE_DIR}/expModule/incdir1
  ${CMAKE_CURRENT_SOURCE_DIR}/expModule/incdir2
  ${CMAKE_CURRENT_SOURCE_DIR}/expModule
  )

CPM_VerifyListEquality(
  EXPECTED_INCLUDE_DIRS 
  CPM_KV_INCLUDE_MAP_${CPM_LAST_MODULE_FULL_UNID}
  "CMAKE UNIT TESTING - include directory error: ")

CPM_AddModule("central_sub"
  SOURCE_DIR "./subModule")

CPM_InitModule(${CPM_MODULE_NAME})

file (GLOB source
  "central/*.cpp"
  "central/*.hpp"
  )

add_library(${CPM_LIB_TARGET_NAME} ${source})
target_link_libraries(${CPM_LIB_TARGET_NAME} ${CPM_LIBRARIES})

