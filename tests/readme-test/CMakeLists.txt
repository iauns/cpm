# Note, this example requires CMake 2.8.9 because of the mongo C module and
# it's ExternalProject dependency. Remove that module and you should be able
# to compile with earlier versions.
cmake_minimum_required(VERSION 2.8.9 FATAL_ERROR)
project(Viewer)

#------------------------------------------------------------------------------
# Required CPM Setup - no need to modify - See: https://github.com/iauns/cpm
#------------------------------------------------------------------------------
set(CPM_DIR "${CMAKE_CURRENT_BINARY_DIR}/cpm_packages" CACHE TYPE STRING)
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

#------------------------------------------------------------------------------
# CPM Modules
#------------------------------------------------------------------------------

# ++ MODULE: OpenGL platform
CPM_AddModule("gl_platform"
  GIT_REPOSITORY "https://github.com/iauns/cpm-gl-platform"
  GIT_TAG "1.3.0")

# ++ MODULE: aabb
CPM_AddModule("aabb"
  GIT_REPOSITORY "https://github.com/iauns/cpm-glm-aabb"
  GIT_TAG "1.0.2")

# ++ EXTERNAL-MODULE: GLM
CPM_AddModule("glm"
  GIT_REPOSITORY "https://github.com/iauns/cpm-glm"
  GIT_TAG "1.0.1"
  USE_EXISTING_VER TRUE)

CPM_Finish()

#-----------------------------------------------------------------------
# Setup source
#-----------------------------------------------------------------------
file(GLOB Sources
  "${CMAKE_CURRENT_SOURCE_DIR}/*.cpp"
  "${CMAKE_CURRENT_SOURCE_DIR}/*.hpp"
  )

#-----------------------------------------------------------------------
# Setup executable
#-----------------------------------------------------------------------
set(EXE_NAME myViewer)
add_executable(${EXE_NAME} ${Sources})
target_link_libraries(${EXE_NAME} ${CPM_LIBRARIES})
