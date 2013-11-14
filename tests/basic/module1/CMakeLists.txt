CMAKE_MINIMUM_REQUIRED(VERSION 2.8)

#------------------------------------------------------------------------------
# Custom CPM setup (for tests). See https://github.com/iauns/cpm for real setup
#------------------------------------------------------------------------------
set(CPM_MODULE_NAME "module1")
set(CPM_LIB_TARGET_NAME ${CPM_MODULE_NAME})

if ((DEFINED CPM_DIR) AND (DEFINED CPM_UNIQUE_ID) AND (DEFINED CPM_TARGET_NAME))
  set(CPM_LIB_TARGET_NAME ${CPM_TARGET_NAME})
  set(CMAKE_MODULE_PATH ${CMAKE_MODULE_PATH} ${CPM_DIR})
  include(CPM)
else()
  include(../../../CPM.cmake)
endif()

# Include modules and externals. All modules must come before any project
# specific setup such as setting compiler flags. See the github readme for
# a full explanation.

CPM_InitModule(${CPM_MODULE_NAME})

file (GLOB source
  "*.cpp"
  "*.hpp"
  )

add_library(${CPM_LIB_TARGET_NAME} ${source})
target_link_libraries(${CPM_LIB_TARGET_NAME} ${CPM_LIBRARIES})

