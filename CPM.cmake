# CPM - CMake Package Manager
#
# TODO: Disable build_as_shared when using AddModule.
#
# A CMake module for managing external dependencies.
# CPM can be used to build traditional C/C++ libraries and CPM modules.
# In contrast to traditional C++ libraries, CPM modules have namespace
# alteration and allow for multiple different versions of the same library to
# be statically linked together and easily used without namespace conflicts.
# CPM modules use add_subdirectory for CPM modules and ExternalProject for
# traditional builds. CPM is inspired by Node.js' NPM package manager. 
#
# CPM consists of two function: CPM_AddModule(...) and CPM_AddExternal(...) .
# CPM_AddModule accepts a few of the same parameters as ExternalProject
# alongside adding a few of its own. The following variables are created in /
# appended to PARENT_SCOPE whenever the add module function is called:
# 
#  CPM_INCLUDE_DIRS     - All module search paths.
#  CPM_LIBRARIES        - All libraries to link against. These are all imported targets.
#
# Add module function reference:
#  CPM_AddModule(<name>           # Required - Module target name.
#    [SOURCE_DIR dir]             # Uses 'dir' as the source directory as opposed to downloading.
#    [GIT_TAG tag]                # Same as ExternalProject_Add's GIT_TAG
#    [GIT_REPOSITORY repo]        # Same as ExternalProject_Add's GIT_REPOSITORY.
#    [CMAKE_ARGS args...]         # Additional CMake arguments to set for only for this module.
#    )
#
# Many settings are automatically applied for modules. Setting SOURCE_DIR is
# not recommeneded unless you are managing the header locations for the source
# directory manually. If you set the source directory the project will not be
# downloaded and will not be updated using git. You must manage that manually.
#
# Add external simply looks for the name plus an optional associated version.
# If you use this function, additional data will be downloaded from a CPM
# repository. This repository holds build scripts for various different popular
# packages. CPM_AddExternal is not as robust as modules and can't be versioned
# well. Additionally, you cannot link against multiple versions of the same
# library unless you use shared libraries.
# Add external function reference:
#  CPM_AddExternal(<name>         # Required - External name (will be used to lookup external).
#    [VERSION version]            # Attempt to find this version number.
#    )
#
# Also remember: you will probably want to use add_dependencies with the
# ${CPM_LIBRARIES}.

#-------------------------------------------------------------------------------
# Pre-compute a regex to match documented keywords for each command.
#-------------------------------------------------------------------------------
# This code parses the *current* file and extracts parameter key words from the
# documentation given above. It will match "# ... [...] # ..." style statements,
# or "#  <funcname>(" style statements.
# This code was pretty much lifted directly from KitWare's ExternalProject.cmake,
# but then I documented what it's doing. It's not exactly straight forward.

# Based on the current line in *this* file (SpirePM.cmake), we calc the number
# of lines the documentation header consumes. Including this comment, that is
# 12 lines upwards.
math(EXPR _cpm_documentation_line_count "${CMAKE_CURRENT_LIST_LINE} - 13")

# Run a regex to extract parameter names from the *this* file (SpirePM.cmake).
# Stuff the results into 'lines'.
file(STRINGS "${CMAKE_CURRENT_LIST_FILE}" lines
     LIMIT_COUNT ${_cpm_documentation_line_count}
     REGEX "^#  (  \\[[A-Z0-9_]+ [^]]*\\] +#.*$|[A-Za-z0-9_]+\\()")

# Iterate over the results we obtained 
foreach(line IN LISTS lines)
  # Check to see if we have found a function which is two spaces followed by
  # any number of alphanumeric chararcters followed by a '('.
  if("${line}" MATCHES "^#  [A-Za-z0-9_]+\\(")

    # Are we already parsing a function?
    if(_cpm_func)
      # We are parsing a function, save the current list of keywords in 
      # _cpm_keywords_<function_name> in preparation to parse a new function.
      set(_cpm_keywords_${_cpm_func} "${_cpm_keywords_${_cpm_func}})$")
    endif()

    # Note that _cpm_func gets *set* HERE. See 'cmake --help-command string'.
    # In this case, we are extracting the function's name into _cpm_func.
    string(REGEX REPLACE "^#  ([A-Za-z0-9_]+)\\(.*" "\\1" _cpm_func "${line}")

    #message("function [${_cpm_func}]")

    # Clear vars (we will be building a REGEX in _cpm_keywords, hence
    # the ^(. _cpm_keyword_sep is only use to inject a separator at appropriate
    # places while we are building the regex. In essence, we are skipping the
    # first '|' that would usually be inserted.
    set(_cpm_keywords_${_cpm_func} "^(")
    set(_cpm_keyword_sep)
  else()
    # Otherwise we must be parsing a parameter of the function. Extract the name
    # of the parameter into _cpm_key
    string(REGEX REPLACE "^#    \\[([A-Z0-9_]+) .*" "\\1" _cpm_key "${line}")
    # Syntax highlighting gets a little wonky around this regex, need this - "

    #message("  keyword [${_cpm_key}]")

    set(_cpm_keywords_${_cpm_func}
      "${_cpm_keywords_${_cpm_func}}${_cpm_keyword_sep}${_cpm_key}")
    set(_cpm_keyword_sep "|")
  endif()
endforeach()
# Duplicate of the 'Are we already parsing a function?' code above.
# Just completes the regex.
if(_cpm_func)
  set(_cpm_keywords_${_cpm_func} "${_cpm_keywords_${_cpm_func}})$")
endif()

# Include external project
include(ExternalProject)

# Record where this list file is located. We pass this directory into our
# modules so they can also include SpirePM.
# We do NOT want to access CMAKE_CURRENT_LIST_DIR from a function invokation.
# If we do, then CMAKE_CURRENT_LIST_DIR will contain the calling CMakeLists.txt
# file. See: http://stackoverflow.com/questions/12802377/in-cmake-how-can-i-find-the-directory-of-an-included-file
set(DIR_OF_SPIREPM ${CMAKE_CURRENT_LIST_DIR})

# Function for parsing arguments and values coming into the specified function
# name 'f'. 'name' is the target name. 'ns' (namespace) is a value prepended
# onto the key name before being added to the target namespace. 'args' list of
# arguments to process.
function(_cpm_parse_arguments f ns args)
  # Transfer the arguments to this function into target properties for the new
  # custom target we just added so that we can set up all the build steps
  # correctly based on target properties.
  #
  # We loop through ARGN and consider the namespace starting with an upper-case
  # letter followed by at least two more upper-case letters, numbers or
  # underscores to be keywords.
  set(key)

  foreach(arg IN LISTS args)
    set(is_value 1)

    # Check to see if we have a keyword. Otherwise, we will have a value
    # associated with a keyword. Confirm that the arg doesn't match a few
    # common exceptions.
    if(arg MATCHES "^[A-Z][A-Z0-9_][A-Z0-9_]+$" AND
        NOT ((arg STREQUAL "${key}") AND (key STREQUAL "COMMAND")) AND
        NOT arg MATCHES "^(TRUE|FALSE)$")

      # Now check to see if the argument is in our list of approved keywords.
      # If is, then make sure we don't treat it as a value.
      if(_cpm_keywords_${f} AND arg MATCHES "${_cpm_keywords_${f}}")
        set(is_value 0)
      endif()

    endif()

    if(is_value)
      if(key)
        # We have a key / value pair. Set the appropriate property.
        if(NOT arg STREQUAL "")
          # Set the variable in both scopes so we can test for existance
          # and update as needed.
          set(${ns}${key} "${arg}")
          set(${ns}${key} "${arg}" PARENT_SCOPE)
          #message("Set ${ns}${key} to ${arg}")
        else()
          if (${ns}${key})
            # If we already have a value for this key, generated a semi-colon
            # separated list.
            set(value ${${ns}${key}})
            set(${ns}${key} "${value};${arg}")
            set(${ns}${key} "${value};${arg}" PARENT_SCOPE)
            #message("Set2 ${ns}${key} to ${value};${arg}")
          else()
            set(${ns}${key} "${arg}")
            set(${ns}${key} "${arg}" PARENT_SCOPE)
          endif()
        endif()
      else()
        # Missing Keyword
        message(AUTHOR_WARNING "value '${arg}' with no previous keyword in ${f}")
      endif()
    else()
      # Set the key to use in the next iteration.
      set(key "${arg}")
    endif()
  endforeach()
endfunction()


# See: http://stackoverflow.com/questions/7747857/in-cmake-how-do-i-work-around-the-debug-and-release-directories-visual-studio-2
function(_cpm_build_target_output_dirs parent_var_to_update output_dir)

  set(outputs)
  set(outputs ${outputs} "-DCMAKE_RUNTIME_OUTPUT_DIRECTORY:STRING=${output_dir}")
  set(outputs ${outputs} "-DCMAKE_LIBRARY_OUTPUT_DIRECTORY:STRING=${output_dir}")
  set(outputs ${outputs} "-DCMAKE_ARCHIVE_OUTPUT_DIRECTORY:STRING=${output_dir}")

  # Second, for multi-config builds (e.g. msvc)
  foreach(OUTPUTCONFIG ${CMAKE_CONFIGURATION_TYPES})
    string(TOUPPER ${OUTPUTCONFIG} OUTPUTCONFIG)
    set(outputs ${outputs} "-DCMAKE_RUNTIME_OUTPUT_DIRECTORY_${OUTPUTCONFIG}:STRING=${output_dir}")
    set(outputs ${outputs} "-DCMAKE_LIBRARY_OUTPUT_DIRECTORY_${OUTPUTCONFIG}:STRING=${output_dir}")
    set(outputs ${outputs} "-DCMAKE_ARCHIVE_OUTPUT_DIRECTORY_${OUTPUTCONFIG}:STRING=${output_dir}")
  endforeach(OUTPUTCONFIG CMAKE_CONFIGURATION_TYPES)

  set(${parent_var_to_update} ${outputs} PARENT_SCOPE)

endfunction()

function(Spire_BuildCoreThirdPartyIncludes out_var source_dir)
  set(ret_val ${ret_val} "${source_dir}/Spire/3rdParty/glm")
  set(ret_val ${ret_val} "${source_dir}/Spire/3rdParty/glew/include")
  set(${out_var} ${ret_val} PARENT_SCOPE)
endfunction()


# 'name' - Name of the target that will be created.
# This function will define or add to the following variables in the parent's
# namespace.
# 
#  SPIRE_INCLUDE_DIR     - All the spire include directories, including modules.
#  SPIRE_LIBRARY         - All libraries to link against, including modules.
#
function(Spire_AddCore name)
  # Parse all function arguments into our namespace prepended with _CPM_.
  _cpm_parse_arguments(Spire_AddCore _CPM_ "${ARGN}")

  # Setup any defaults that the user provided.
  if (DEFINED _CPM_PREFIX)
    set(_ep_prefix "PREFIX" "${_CPM_PREFIX}")
  else()
    set(_ep_prefix "PREFIX" "${CMAKE_CURRENT_BINARY_DIR}/spire-core")
    # We also set the _CPM_PREFIX variable in this case since we use it below.
    set(_CPM_PREFIX "${CMAKE_CURRENT_BINARY_DIR}/spire-core")
  endif()

  if (DEFINED _CPM_GIT_TAG)
    set(_ep_git_tag "GIT_TAG" ${_CPM_GIT_TAG})
  else()
    set(_ep_git_tag "GIT_TAG" "origin/master")
  endif()

  if (DEFINED _CPM_GIT_REPOSITORY)
    set(_ep_git_repo "GIT_REPOSITORY" ${_CPM_GIT_REPOSITORY})
  else()
    set(_ep_git_repo "GIT_REPOSITORY" "https://github.com/SCIInstitute/spire.git")
  endif()

  if (DEFINED _CPM_SOURCE_DIR)
    set(_ep_source_dir "SOURCE_DIR" "${_CPM_SOURCE_DIR}")
    # Clear git repo or git tag, if any.
    set(_ep_git_repo)
    set(_ep_git_tag)
    set(_ep_update_command "UPDATE_COMMAND" "cmake .")
  endif()

  if (DEFINED _CPM_BINARY_DIR)
    set(_ep_bin_dir "BINARY_DIR" $_CPM_BINARY_DIR)
  endif()

  if (DEFINED _CPM_USE_STD_THREADS)
    set(_ep_spire_use_threads "-DUSE_STD_THREADS:BOOL=${_CPM_USE_STD_THREADS}")
  else()
    set(_ep_spire_use_threads "-DUSE_STD_THREADS:BOOL=ON")
  endif()

  # All the following 3 lines do is construct a series of values that will go
  # into the CMAKE_ARGS key in ExternalProject_Add. These are a series
  # binary of output directories. We want a central location for everything
  # so we can keep track of the binaries.
  set(_CPM_BASE_OUTPUT_DIR "${_CPM_PREFIX}/spire_modules_bin")
  set(_CPM_CORE_OUTPUT_DIR "${_CPM_BASE_OUTPUT_DIR}/spire_core")
  _cpm_build_target_output_dirs(_ep_spire_output_dirs ${_CPM_CORE_OUTPUT_DIR})

  ExternalProject_Add(${name}
    ${_ep_prefix}
    ${_ep_source_dir}
    ${_ep_git_repo}
    ${_ep_git_tag}
    ${_ep_bin_dir}
    INSTALL_COMMAND ""
    CMAKE_ARGS
      -DCMAKE_BUILD_TYPE:STRING=${CMAKE_BUILD_TYPE}
      ${_ep_spire_use_threads}
      ${_ep_spire_output_dirs}
    )

  if (DEFINED _CPM_SOURCE_DIR)
    # Forces a build even though we are source only.
    ExternalProject_Add_Step(${name} forcebuild
      COMMAND ${CMAKE_COMMAND} -E echo
      ALWAYS 1
      DEPENDERS build
      )
  endif()

  # This target property is used to place compiled modules where they belong.
  set_target_properties(${name} PROPERTIES SPIRE_MODULE_OUTPUT_DIRECTORY "${_CPM_BASE_OUTPUT_DIR}")

  # Setup imported library.
  set(spire_library_name Spire)
  set(spire_library_target_name SpireCoreLibraryTarget)
  set(spire_library_path 
    "${_CPM_CORE_OUTPUT_DIR}/${CMAKE_STATIC_LIBRARY_PREFIX}${spire_library_name}${CMAKE_STATIC_LIBRARY_SUFFIX}")
  add_library(${spire_library_target_name} STATIC IMPORTED GLOBAL)
  add_dependencies(${spire_library_target_name} ${name})
  set_property(TARGET ${spire_library_target_name} PROPERTY IMPORTED_LOCATION "${spire_library_path}")

  # Library path for the core module.
  set(SPIRE_LIBRARIES ${SPIRE_LIBRARIES} "${spire_library_target_name}" PARENT_SCOPE)
  set(SPIRE_LIBRARY_DIRS ${SPIRE_LIBRARY_DIRS} "${_CPM_CORE_OUTPUT_DIR}" PARENT_SCOPE)

  # Retrieving properties from external projects will retrieve their fully
  # initialized values (including if any defaults were set).
  ExternalProject_Get_Property(${name} PREFIX)
  ExternalProject_Get_Property(${name} SOURCE_DIR)
  ExternalProject_Get_Property(${name} BINARY_DIR)
  ExternalProject_Get_Property(${name} INSTALL_DIR)

  set(SPIRE_INCLUDE_DIR ${SPIRE_INCLUDE_DIR} "${SOURCE_DIR}")
  set(SPIRE_INCLUDE_DIR ${SPIRE_INCLUDE_DIR} PARENT_SCOPE)

  set(SPIRE_MODULE_INCLUDE_DIRS PARENT_SCOPE)

  Spire_BuildCoreThirdPartyIncludes(spire_third_party_dirs ${SOURCE_DIR})
  set(SPIRE_3RDPARTY_INCLUDE_DIRS ${spire_third_party_dirs})
  set(SPIRE_3RDPARTY_INCLUDE_DIRS "${SPIRE_3RDPARTY_INCLUDE_DIRS}" PARENT_SCOPE)

  # Also set a target property containing all of the includes needed for the
  # core spire library. This is used by modules in order.
  set_target_properties(${name} PROPERTIES SPIRE_CORE_INCLUDE_DIRS "${SPIRE_INCLUDE_DIRS};${SPIRE_3RDPARTY_INCLUDE_DIRS}")
  set_target_properties(${name} PROPERTIES SPIRE_BASE_MODULE_SRC_DIR "${PREFIX}/module_src/SpireExt")

  # Set output directory for assets if the user passed the variable in.
  if (DEFINED _CPM_ASSET_OUTPUT_DIR)
    set_target_properties(${name} PROPERTIES ASSET_OUTPUT_DIR "${_CPM_ASSET_OUTPUT_DIR}")
  endif()

  # Set output directory for shaders if the user passed the variable in.
  if (DEFINED _CPM_SHADER_OUTPUT_DIR)
    set_target_properties(${name} PROPERTIES SHADER_OUTPUT_DIR "${_CPM_SHADER_OUTPUT_DIR}")
  endif()

endfunction()

# Module are built using the root CMakeLists.txt but the output
# directories of the modules are modified such that they end up in a
# single area (under the spire-core prefix). Also, modules are linked
# against the already pre-existing spire_core library. Either dynamically or
# statically. Extra link directories are passed into the CMAKE_ARGS in
# ExternalProject_Add.
# Additionally, all spire modules must accept an output name
# (SPIRE_OUTPUT_NAME). The output name will be used to target and link against
# the generated static library.
function (Spire_AddModule spire_core module_name repo version)
  
  set(target_name "cpm_${module_name}")

  # The name we will link against.
  set(MODULE_STATIC_LIB_NAME "spirelib_${module_name}")

  # Extract prefix and target module src directory from spire_core
  get_target_property(BASE_MODULE_SRC_DIR ${spire_core} SPIRE_BASE_MODULE_SRC_DIR)
  ExternalProject_Get_Property(${spire_core} PREFIX)
  ExternalProject_Get_Property(${spire_core} SOURCE_DIR)
  set(SPIRE_CORE_PREFIX ${PREFIX})
  set(SPIRE_CORE_SRC ${SOURCE_DIR})
  set(PREFIX)
  set(SOURCE_DIR)
  set(MODULE_PREFIX "${SPIRE_CORE_PREFIX}/module_build/${module_name}/${version}")
  set(MODULE_SRC_DIR "${MODULE_PREFIX}/SpireExt/${module_name}")

  # Parse all function arguments into our namespace prepended with _CPM_.
  _cpm_parse_arguments(Spire_AddCore _CPM_ "${ARGN}")

  # Extract desired output directory from spire_core target.
  get_target_property(_CPM_BASE_OUTPUT_DIR ${spire_core} SPIRE_MODULE_OUTPUT_DIRECTORY)
  set(MODULE_BIN_OUTPUT_DIR "${_CPM_BASE_OUTPUT_DIR}/${target_name}")
  _cpm_build_target_output_dirs(_ep_spire_output_dirs ${MODULE_BIN_OUTPUT_DIR})

  # If the user specified the source directory then don't automatically generate
  # it for them and wipe out all git / download info.
  if (DEFINED _CPM_SOURCE_DIR)
    set(_ep_source_dir "SOURCE_DIR" "${_CPM_SOURCE_DIR}")
    # Clear git repo or git tag, if any.
    set(_ep_git_repo)
    set(_ep_git_tag)

    # Attempt to set include directory intelligently. This will allow use to
    # use SpireExt/<module name> if the directory hierarchy is setup correctly
    # on-disk.
    set(SPIRE_MODULE_INCLUDE_DIRS ${SPIRE_MODULE_INCLUDE_DIRS} ${_CPM_SOURCE_DIR}/../.. PARENT_SCOPE)
  else()
    # If they did not, place the source directory in a consistent directory
    # hierarchy such that the user can access the project using:
    # SpireExt/<reponame>/. It is common to store public include
    # headers at the root of the project for spire modules.
    set(_ep_source_dir "SOURCE_DIR" "${MODULE_SRC_DIR}")
    set(_ep_git_repo "GIT_REPOSITORY" "${repo}")
    set(_ep_git_tag "GIT_TAG" "${version}")

    # Set include directories.
    set(SPIRE_MODULE_INCLUDE_DIRS ${SPIRE_MODULE_INCLUDE_DIRS} ${MODULE_PREFIX} PARENT_SCOPE)
  endif()

  if (DEFINED _CPM_SHADER_DIR)
    # Set appropriate shader variable in PARENT_SCOPE.
    set(SPIRE_SHADER_DIRS ${SPIRE_SHADER_DIRS} ${_CPM_SHADER_DIR} PARENT_SCOPE)
  endif()

  if (DEFINED _CPM_ASSET_DIR)
    # Set appropriate asset variable in PARENT_SCOPE.
    set(SPIRE_ASSET_DIRS ${SPIRE_ASSET_DIRS} ${_CPM_ASSET_DIR} PARENT_SCOPE)
  endif()

  get_target_property(CORE_INCLUDE_DIRS ${spire_core} SPIRE_CORE_INCLUDE_DIRS)

  get_target_property(OUTPUT_SHADER_DIR ${spire_core} SHADER_OUTPUT_DIR)
  if(OUTPUT_SHADER_DIR STREQUAL "NOTFOUND")
    set(OUTPUT_SHADER_DIR "")
  endif()

  get_target_property(OUTPUT_ASSET_DIR ${spire_core} ASSET_OUTPUT_DIR)
  if(OUTPUT_ASSET_DIR STREQUAL "NOTFOUND")
    set(OUTPUT_ASSET_DIR "")
  endif()

  ExternalProject_Add(${target_name}
    "PREFIX;${MODULE_PREFIX}"
    ${_ep_git_repo}
    ${_ep_git_tag}
    ${_ep_source_dir}
    INSTALL_COMMAND ""
    CMAKE_ARGS
      -DCMAKE_BUILD_TYPE:STRING=${CMAKE_BUILD_TYPE}
      -DSPIRE_OUTPUT_MODULE_NAME:STRING=${MODULE_STATIC_LIB_NAME}
      -DMOD_SPIRE_CMAKE_MODULE_PATH:STRING=${DIR_OF_SPIREPM}
      -DMOD_SPIRE_CORE_SRC:STRING=${SPIRE_CORE_SRC}
      -DOUTPUT_SHADER_DIR:STRING=${OUTPUT_SHADER_DIR}
      -DOUTPUT_ASSET_DIR:STRING=${OUTPUT_ASSET_DIR}
      ${_ep_spire_output_dirs}
    )

  if (DEFINED _CPM_SOURCE_DIR)
    # Forces a build even though we are source only.
    ExternalProject_Add_Step(${target_name} forcebuild
      COMMAND ${CMAKE_COMMAND} -E echo
      ALWAYS 1
      DEPENDERS build
      )
  endif()

  # We don't need to set SPIRE_INCLUDE_DIRS since it is assumed that the source
  # for our module has been placed in the appropriate location and we can
  # lookup the results using SpireExt/{target_name}.

  # Setup imported library.
  set(spire_library_name ${MODULE_STATIC_LIB_NAME})
  set(spire_library_target_name ${MODULE_STATIC_LIB_NAME})
  set(spire_library_path 
    "${MODULE_BIN_OUTPUT_DIR}/${CMAKE_STATIC_LIBRARY_PREFIX}${spire_library_name}${CMAKE_STATIC_LIBRARY_SUFFIX}")
  add_library(${spire_library_target_name} STATIC IMPORTED GLOBAL)
  add_dependencies(${spire_library_target_name} ${target_name})
  set_property(TARGET ${spire_library_target_name} PROPERTY IMPORTED_LOCATION "${spire_library_path}")

  # Ensure this module can be found during the linking process.
  set(SPIRE_LIBRARIES ${SPIRE_LIBRARIES} "${MODULE_STATIC_LIB_NAME}" PARENT_SCOPE)
  set(SPIRE_LIBRARY_DIRS ${SPIRE_LIBRARY_DIRS} "${MODULE_BIN_OUTPUT_DIR}" PARENT_SCOPE)

  # We do depend on the spire source being available before we compile our,
  # hence the dependency.
  add_dependencies(${target_name} ${spire_core})

endfunction()

function (Spire_CopyShaders src_shader_dir dest_shader_dir)
  if (NOT dest_shader_dir STREQUAL "")
    file(COPY ${src_shader_dir}/ DESTINATION ${dest_shader_dir}
      FILE_PERMISSIONS OWNER_READ OWNER_WRITE GROUP_READ WORLD_READ
      DIRECTORY_PERMISSIONS OWNER_READ OWNER_WRITE OWNER_EXECUTE
                            GROUP_READ
                            WORLD_READ WORLD_EXECUTE)
  endif()
endfunction()

function (Spire_CopyAssets src_asset_dir dest_asset_dir)
  if (NOT dest_asset_dir STREQUAL "")
    file(COPY ${src_asset_dir}/ DESTINATION ${dest_asset_dir}
      FILE_PERMISSIONS OWNER_READ OWNER_WRITE GROUP_READ WORLD_READ
      DIRECTORY_PERMISSIONS OWNER_READ OWNER_WRITE OWNER_EXECUTE
                            GROUP_READ
                            WORLD_READ WORLD_EXECUTE)
  endif()
endfunction()

