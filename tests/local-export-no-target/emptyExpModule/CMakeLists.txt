CMAKE_MINIMUM_REQUIRED(VERSION 2.8.9)

#------------------------------------------------------------------------------
# Custom CPM setup (for tests). See https://github.com/iauns/cpm for real setup
#------------------------------------------------------------------------------
set(CPM_MODULE_NAME "empty_exp_module")
set(CPM_LIB_TARGET_NAME ${CPM_MODULE_NAME})

if ((DEFINED CPM_DIR) AND (DEFINED CPM_UNIQUE_ID) AND (DEFINED CPM_TARGET_NAME))
  set(CPM_LIB_TARGET_NAME ${CPM_TARGET_NAME})
  set(CMAKE_MODULE_PATH ${CMAKE_MODULE_PATH} ${CPM_DIR})
  include(CPM)
else()
  include(../../../../CPM.cmake)
endif()

CPM_ExportAdditionalIncludeDir("${CMAKE_CURRENT_SOURCE_DIR}/incdirA")
CPM_ExportAdditionalIncludeDir("${CMAKE_CURRENT_SOURCE_DIR}/incdirB")

CPM_ExportAdditionalDefinition("-DINCDIRA_TEST")
CPM_ExportAdditionalDefinition("-DINCDIRB_TEST")

add_definitions(-DINCDIRA_TEST)
add_definitions(-DINCDIRB_TEST)

include_directories("${CMAKE_CURRENT_SOURCE_DIR}/incdirA")
include_directories("${CMAKE_CURRENT_SOURCE_DIR}/incdirB")

CPM_InitModule(${CPM_MODULE_NAME})

