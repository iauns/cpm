CMAKE_MINIMUM_REQUIRED(VERSION 2.8)

include(../../../util/CMakeUnitTesting.cmake)

#------------------------------------------------------------------------------
# Custom CPM setup (for tests). See https://github.com/iauns/cpm for real setup
#------------------------------------------------------------------------------
set(CPM_MODULE_NAME "batch_testing")
set(CPM_LIB_TARGET_NAME ${CPM_MODULE_NAME})

if ((DEFINED CPM_DIR) AND (DEFINED CPM_UNIQUE_ID) AND (DEFINED CPM_TARGET_NAME))
  set(CPM_LIB_TARGET_NAME ${CPM_TARGET_NAME})
  set(CMAKE_MODULE_PATH ${CMAKE_MODULE_PATH} ${CPM_DIR})
  include(CPM)
else()
  include(../../../CPM.cmake)
endif()

CPM_AddModule("spire"
  SOURCE_DIR "../spire"
  EXPORT_MODULE TRUE)

# TODO: This should NOT be required when we fix exported modules' exported
#       modules.
CPM_AddModule("glm"
  SOURCE_DIR "../glm"
  EXPORT_MODULE TRUE)

CPM_InitModule(${CPM_MODULE_NAME})

file (GLOB source
  "batch-testing/*.cpp"
  "batch-testing/*.hpp"
  )

add_library(${CPM_LIB_TARGET_NAME} ${source})
target_link_libraries(${CPM_LIB_TARGET_NAME} ${CPM_LIBRARIES})

