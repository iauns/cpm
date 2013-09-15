CMAKE_MINIMUM_REQUIRED(VERSION 2.8)
project (Foo)

#------------------------------------------------------------------------------
# CPM Download and Setup
#------------------------------------------------------------------------------
set (CPM_DIR "${CMAKE_CURRENT_BINARY_DIR}/cpm-packages" CACHE TYPE STRING)
if (${CPM_DIR} MATCHES "${CMAKE_CURRENT_BINARY_DIR}")
  message("Placing CPM in the binary directory is not recommended.")
endif ()

find_package(Git)
if(NOT GIT_FOUND)
  message(FATAL_ERROR "CPM requires Git.")
endif()
if (NOT EXISTS ${CPM_DIR}/CPM.cmake)
  execute_process(
    COMMAND "${GIT_EXECUTABLE}" clone https://github.com/iauns/cpm ${CPM_DIR}
    RESULT_VARIABLE error_code
    OUTPUT_VARIABLE head_sha
    )
  if(error_code)
    message(FATAL_ERROR "Failed to get the hash for HEAD")
  endif()
endif()

set(CMAKE_MODULE_PATH ${CMAKE_MODULE_PATH} ${CPM_DIR})
include(CPM)


