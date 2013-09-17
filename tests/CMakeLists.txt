CMAKE_MINIMUM_REQUIRED(VERSION 2.8)
project (Foo)

##------------------------------------------------------------------------------
## Required CPM Setup - See: http://github.com/iauns/cpm
##------------------------------------------------------------------------------
#set (CPM_DIR "${CMAKE_CURRENT_BINARY_DIR}/cpm-packages" CACHE TYPE STRING)
#if (${CPM_DIR} MATCHES "${CMAKE_CURRENT_BINARY_DIR}")
#  message("NOTE: Placing CPM in the binary directory is not recommended.")
#endif ()
#
#find_package(Git)
#if(NOT GIT_FOUND)
#  message(FATAL_ERROR "CPM requires Git.")
#endif()
#if (NOT EXISTS ${CPM_DIR}/CPM.cmake)
#  execute_process(
#    COMMAND "${GIT_EXECUTABLE}" clone https://github.com/iauns/cpm ${CPM_DIR}
#    RESULT_VARIABLE error_code
#    OUTPUT_VARIABLE head_sha
#    )
#  if(error_code)
#    message(FATAL_ERROR "CPM failed to get the hash for HEAD")
#  endif()
#endif()
#
#message('CPM dir: ${CPM_DIR}')
#set(CMAKE_MODULE_PATH ${CMAKE_MODULE_PATH} ${CPM_DIR})
#include(CPM)

set(CMAKE_MODULE_PATH ${CMAKE_MODULE_PATH} ${CMAKE_CURRENT_BINARY_DIR}/..)
include(CPM)

#------------------------------------------------------------------------------
# Include modules and externals
#------------------------------------------------------------------------------
CPM_AddModule("SpireModule"
  GIT_REPOSITORY "https://github.com/SCIInstitute/spire"
  GIT_TAG "v0.1.1")

#CPM_AddExternal("CMongoDB"
#GIT_REPOSITORY "/")
