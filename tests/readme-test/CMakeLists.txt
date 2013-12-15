cmake_minimum_required(VERSION 2.8.7 FATAL_ERROR)
project(foo)

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
# Create main.cpp. This is done to keep this CMakeLists.txt self-contained.
# Source files should be added to the project in other ways.
file(WRITE src/main.cpp "#include <iostream>\n")
file(APPEND src/main.cpp "#include <glm-aabb/AABB.hpp>\n")
file(APPEND src/main.cpp "#include <glm/glm.hpp>\n\n")
file(APPEND src/main.cpp "namespace glm_aabb = CPM_AABB_NS;\n\n")
file(APPEND src/main.cpp "int main(int argc, char** av)\n")
file(APPEND src/main.cpp "{\n")
file(APPEND src/main.cpp "  glm_aabb::AABB aabb(glm::vec3(-1.0), glm::vec3(1.0));\n")
file(APPEND src/main.cpp "  aabb.extend(glm::vec3(-2.0, 3.0, -0.5));\n")
file(APPEND src/main.cpp "  glm_aabb::AABB aabb2(glm::vec3(1.0), 1.0);\n")
file(APPEND src/main.cpp "  std::cout << \"AABB Interesction: \" << aabb.intersect(aabb2) << std::endl;\n")
file(APPEND src/main.cpp "  return 0;\n")
file(APPEND src/main.cpp "}\n")

set(Sources src/main.cpp)

#-----------------------------------------------------------------------
# Setup executable
#-----------------------------------------------------------------------
set(EXE_NAME cpm-test)
add_executable(${EXE_NAME} ${Sources})
target_link_libraries(${EXE_NAME} ${CPM_LIBRARIES})
