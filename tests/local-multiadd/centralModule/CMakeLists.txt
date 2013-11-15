CMAKE_MINIMUM_REQUIRED(VERSION 2.8)

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

CPM_AddModule("central_sub"
  SOURCE_DIR "./subModule")

CPM_AddModule("central_exp"
  SOURCE_DIR "./expModule"
  EXPORT_MODULE TRUE)

CPM_InitModule(${CPM_MODULE_NAME})

file (GLOB source
  "central/*.cpp"
  "central/*.hpp"
  )

add_library(${CPM_LIB_TARGET_NAME} ${source})
message("Libraries: ${CPM_LIBRARIES}")
target_link_libraries(${CPM_LIB_TARGET_NAME} ${CPM_LIBRARIES})

