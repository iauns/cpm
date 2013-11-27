CMAKE_MINIMUM_REQUIRED(VERSION 2.8)

#------------------------------------------------------------------------------
# Custom CPM setup (for tests). See https://github.com/iauns/cpm for real setup
#------------------------------------------------------------------------------
set(CPM_MODULE_NAME "glm")
set(CPM_LIB_TARGET_NAME ${CPM_MODULE_NAME})

if ((DEFINED CPM_DIR) AND (DEFINED CPM_UNIQUE_ID) AND (DEFINED CPM_TARGET_NAME))
  set(CPM_LIB_TARGET_NAME ${CPM_TARGET_NAME})
  set(CMAKE_MODULE_PATH ${CMAKE_MODULE_PATH} ${CPM_DIR})
  include(CPM)
else()
  include(../../../../CPM.cmake)
endif()

CPM_ForceOnlyOneModuleVersion()

CPM_AddModule("spire"
  SOURCE_DIR "../spire"
  EXPORT_MODULE TRUE)

CPM_InitModule(${CPM_MODULE_NAME})

CPM_ExportAdditionalIncludeDir("${CMAKE_CURRENT_SOURCE_DIR}/incdir")
include_directories("${CMAKE_CURRENT_SOURCE_DIR}/incdir")

CPM_ExportAdditionalDefinition("-DINCDIR1_TEST")
add_definitions(-DINCDIR1_TEST)


