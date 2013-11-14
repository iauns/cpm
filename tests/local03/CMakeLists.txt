CMAKE_MINIMUM_REQUIRED(VERSION 2.8)
project (version-test)

macro(CPM_PostModuleExecCallback)
  set(CPM_LAST_MODULE_FULL_UNID ${__CPM_FULL_UNID} PARENT_SCOPE)
  set(CPM_LAST_MODULE_DECLARED_NAME ${CPM_LAST_MODULE_NAME} PARENT_SCOPE)
endmacro()

#------------------------------------------------------------------------------
# Custom CPM setup (for tests). See https://github.com/iauns/cpm for real setup
#------------------------------------------------------------------------------
set(CPM_NO_UPDATE TRUE)
include(../../CPM.cmake)

CPM_AddModule("module1" SOURCE_DIR "./repoModule1")
message("Unid for module1: ${CPM_LAST_MODULE_FULL_UNID}")
message("Last name declared by module: ${CPM_LAST_MODULE_DECLARED_NAME}")
message("Preproc: ${CPM_KV_PREPROC_NS_MAP_${CPM_LAST_MODULE_FULL_UNID}}")
message("Include: ${CPM_KV_INCLUDE_MAP_${CPM_LAST_MODULE_FULL_UNID}}")
message("Definition: ${CPM_KV_DEFINITION_MAP_${CPM_LAST_MODULE_FULL_UNID}}")
message("Prepoc list: ${CPM_KV_LIST_PREPROC_NS_MAP}")
message("Include list: ${CPM_KV_LIST_INCLUDE_MAP}")
message("Def list: ${CPM_KV_LIST_DEFINITION_MAP}")
#message("Include directories: ${CPM_INCLUDE_DIRS}")
message("Definitions: ${CPM_DEFINITIONS}")
CPM_AddModule("module2" SOURCE_DIR "./repoModule2")
message("Unid for module2: ${CPM_LAST_MODULE_FULL_UNID}")
message("Last name declared by module: ${CPM_LAST_MODULE_DECLARED_NAME}")
message("Preproc: ${CPM_KV_PREPROC_NS_MAP_${CPM_LAST_MODULE_FULL_UNID}}")
message("Include: ${CPM_KV_INCLUDE_MAP_${CPM_LAST_MODULE_FULL_UNID}}")
message("Definition: ${CPM_KV_DEFINITION_MAP_${CPM_LAST_MODULE_FULL_UNID}}")
#message("Include directories: ${CPM_INCLUDE_DIRS}")
message("Definitions: ${CPM_DEFINITIONS}")

CPM_Finish()

file (GLOB source
  "*.cpp"
  "*.hpp"
  )

set(EXE_NAME cpm-test)
add_executable(${EXE_NAME} ${source})
target_link_libraries(${EXE_NAME} ${CPM_LIBRARIES})
