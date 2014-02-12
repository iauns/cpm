  #------------------------------------------------------------------------------
  # Required CPM Setup - no need to modify - See: https://github.com/iauns/cpm
  #------------------------------------------------------------------------------
  set(CPM_REPOSITORY https://raw.github.com/toeb/cpm)
  set(CPM_DIR "${CMAKE_CURRENT_BINARY_DIR}/cpm_packages" CACHE TYPE STRING)
  find_package(Git)
  if(NOT GIT_FOUND)
    message(FATAL_ERROR "CPM requires Git.")
  endif()
  if (NOT EXISTS ${CPM_DIR}/CPM.cmake)
    message(STATUS "Cloning repo (${CPM_REPOSITORY})")
    execute_process(
      COMMAND "${GIT_EXECUTABLE}" clone ${CPM_REPOSITORY} ${CPM_DIR}
      RESULT_VARIABLE error_code
      OUTPUT_QUIET ERROR_QUIET)
    if(error_code)
      message(FATAL_ERROR "CPM failed to get the hash for HEAD")
    endif()
  endif()
  include(${CPM_DIR}/CPM.cmake)