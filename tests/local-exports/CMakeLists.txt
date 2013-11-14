CMAKE_MINIMUM_REQUIRED(VERSION 2.8)
project (version-test)

macro(CPM_PostModuleExecCallback)
  set(CPM_LAST_MODULE_UNID_NO_VER ${__CPM_PATH_UNID} PARENT_SCOPE)
  set(CPM_LAST_MODULE_FULL_UNID ${__CPM_FULL_UNID} PARENT_SCOPE)
  set(CPM_LAST_MODULE_DECLARED_NAME ${CPM_LAST_MODULE_NAME} PARENT_SCOPE)
endmacro()

macro(PrintCPMVariables)
  message("")
  message("== Module: ${CPM_LAST_MODULE_DECLARED_NAME}")
  message("")
  message("Non version UNID for module: ${CPM_LAST_MODULE_UNID_NO_VER}")
  message("Non version UNID keyed variables: ")
  message("+ Version map: ${CPM_KV_MOD_VERSION_MAP_${CPM_LAST_MODULE_UNID_NO_VER}}")
  message("Full UNID for module: ${CPM_LAST_MODULE_FULL_UNID}")
  message("Full UNID keyed variables:")
  message("+ Last name declared by module: ${CPM_LAST_MODULE_DECLARED_NAME}")
  message("+ Source added: ${CPM_KV_SOURCE_ADDED_MAP_${CPM_LAST_MODULE_FULL_UNID}}")
  message("+ Preproc: ${CPM_KV_PREPROC_NS_MAP_${CPM_LAST_MODULE_FULL_UNID}}")
  message("+ Include: ${CPM_KV_INCLUDE_MAP_${CPM_LAST_MODULE_FULL_UNID}}")
  message("+ Definition: ${CPM_KV_DEFINITION_MAP_${CPM_LAST_MODULE_FULL_UNID}}")
  message("+ Export: ${CPM_KV_EXPORT_MAP_${CPM_LAST_MODULE_FULL_UNID}}")
  message("Lists:")
  message("+ Version map: ${CPM_KV_LIST_MOD_VERSION_MAP}")
  message("+ Source added: ${CPM_KV_LIST_SOURCE_ADDED_MAP}")
  message("+ Prepoc list: ${CPM_KV_LIST_PREPROC_NS_MAP}")
  message("+ Include list: ${CPM_KV_LIST_INCLUDE_MAP}")
  message("+ Def list: ${CPM_KV_LIST_DEFINITION_MAP}")
  message("+ Export list: ${CPM_KV_LIST_EXPORT_MAP}")
  message("Full definitions and includes")
  message("+ Definitions: ${CPM_DEFINITIONS}")
  message("+ Includes: ${CPM_INCLUDE_DIRS}")
endmacro()

#------------------------------------------------------------------------------
# Custom CPM setup (for tests). See https://github.com/iauns/cpm for real setup
#------------------------------------------------------------------------------
set(CPM_NO_UPDATE TRUE)
include(../../CPM.cmake)

CPM_AddModule("module1" SOURCE_DIR "./repoModule1")
PrintCPMVariables()
CPM_AddModule("module2" SOURCE_DIR "./repoModule2")
PrintCPMVariables()

CPM_Finish()

# 
message("")
message("Definitions and includes for top level")
message("")
message("Full definitions and includes")
message("+ Definitions: ${CPM_DEFINITIONS}")
message("+ Includes: ${CPM_INCLUDE_DIRS}")

file (GLOB source
  "*.cpp"
  "*.hpp"
  )

set(EXE_NAME cpm-test)
add_executable(${EXE_NAME} ${source})
target_link_libraries(${EXE_NAME} ${CPM_LIBRARIES})
