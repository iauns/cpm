cmake_minimum_required(VERSION 2.8.7 FATAL_ERROR)
project(foo)

set(CPM_NO_UPDATE TRUE)
include(../../CPM.cmake)

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
# Create main.cpp instead of relying on main.cpp already being present. This
# is done only to keep this CMakeLists.txt self-contained.
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
