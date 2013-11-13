CMAKE_MINIMUM_REQUIRED(VERSION 2.8)
project (Foo)

#------------------------------------------------------------------------------
# Required CPM Setup - See: http://github.com/iauns/cpm
#------------------------------------------------------------------------------
set (CPM_DIR "${CMAKE_CURRENT_BINARY_DIR}/cpm-packages" CACHE TYPE STRING)
#if (${CPM_DIR} MATCHES "${CMAKE_CURRENT_BINARY_DIR}")
#  message("NOTE: Placing CPM in the binary directory is not recommended.")
#endif ()
find_package(Git)
if(NOT GIT_FOUND)
  message(FATAL_ERROR "CPM requires Git.")
endif()
if (NOT EXISTS ${CPM_DIR}/CPM.cmake)
  message(STATUS "Cloning repo (https://github.com/iauns/cpm)")
  execute_process(
    COMMAND "${GIT_EXECUTABLE}" clone https://github.com/iauns/cpm ${CPM_DIR}
    RESULT_VARIABLE error_code
    OUTPUT_QUIET ERROR_QUIET)
  if(error_code)
    message(FATAL_ERROR "CPM failed to get the hash for HEAD")
  endif()
endif()

include(${CPM_DIR}/CPM.cmake)

# Include modules and externals. All modules must come before any project
# specific setup such as setting compiler flags. See the github readme for
# a full explanation.
CPM_AddModule("spire"
              GIT_REPOSITORY  "https://github.com/SCIInstitute/spire"
              GIT_TAG         "origin/dev")

# Do the following only if we include spire...
# do this AFTER we have included all other modules.
CPM_Finish()

