CMAKE_MINIMUM_REQUIRED(VERSION 2.8)

#------------------------------------------------------------------------------
# Custom CPM setup (for tests). See https://github.com/iauns/cpm for real setup
#------------------------------------------------------------------------------
set(CPM_MODULE_NAME "central_exp")
set(CPM_LIB_TARGET_NAME ${CPM_MODULE_NAME})

if ((DEFINED CPM_DIR) AND (DEFINED CPM_UNIQUE_ID) AND (DEFINED CPM_TARGET_NAME))
  set(CPM_LIB_TARGET_NAME ${CPM_TARGET_NAME})
  set(CMAKE_MODULE_PATH ${CMAKE_MODULE_PATH} ${CPM_DIR})
  include(CPM)
else()
  include(../../../../CPM.cmake)
endif()

CPM_AddModule("central_subbed"
  SOURCE_DIR "../subModule")

CPM_ExportAdditionalIncludeDir("${CMAKE_CURRENT_SOURCE_DIR}/incdir1")
CPM_ExportAdditionalIncludeDir("${CMAKE_CURRENT_SOURCE_DIR}/incdir2")

CPM_ExportAdditionalDefinition("-DINCDIR1_TEST")
CPM_ExportAdditionalDefinition("-DINCDIR2_TEST")

add_definitions(-DINCDIR1_TEST)
add_definitions(-DINCDIR2_TEST)

include_directories("${CMAKE_CURRENT_SOURCE_DIR}/incdir1")
include_directories("${CMAKE_CURRENT_SOURCE_DIR}/incdir2")

CPM_InitModule(${CPM_MODULE_NAME})

file (GLOB source
  "central_exp/*.cpp"
  "central_exp/*.hpp"
  )

add_library(${CPM_LIB_TARGET_NAME} ${source})
target_link_libraries(${CPM_LIB_TARGET_NAME} ${CPM_LIBRARIES})

