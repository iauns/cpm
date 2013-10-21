# CPM - CMake Package Manager
#
# I fully implemented the external project approach, see commit SHA:
# 107d0952bd3a64c371d1d3224271bdcca915b2fa . I also tagged it as 
# "External_Project_Approach". The biggest issue that I ran acrossed was lack 
# of support for static library linkage (which makes sense). I thought about
# building the linkages as you go, but that would require two runs of cmake,
# which I feel is not acceptable.
#
# The approach you see below is a mishmash of ExternalProject and
# addSubdirectory. I tried to take the good of ExternalProject, and merge that
# with the good of add_subdirectory.
#
# TODO: Add include prefixes. Since we know that all public includes will be
#       located in ./include, we can copy the contents of that directory to a
#       new location and prefix it with something. This is so we can fix
#       include issues at the local CMake level instead of having to go
#       upstream with requests or patch the project.
#       Name: INCLUDE_PREFIX.
# TODO: Possibly add an output variable for unique id or other paths the user
#       may want with regards to the module. This way users could add 
#       ExternalProject steps to the module. This may be useful for copying
#       assets from the child projects.
#       We could set this up using something like:
#       "EP_TARGET variable" where 'variable' will be populated in the parent
#       scope with the external project target name. Or something like
#       "EP_SOURCE_DIR variable".
#       Of course, depending on what you are doing, copying assets could
#       be (and probably should be) a cmake argument passed to the external
#       project. Possibly specifying the directory where the assets should be
#       copied.
# TODO: Add library constraints. Some modules may require the user to use
#       the same version of GLM it uses, for instance. This is to avoid
#       conflicts regarding what headers are used. This shouldn't be hard
#       to do as long as all externals and modules are run through CPM.
# TODO: Add externals. CPM could check the user's home directory for the
#       existance of recipes to make external projects. If that is not found,
#       it can manually download all of the recipes.
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
#
# Add external function reference:
#  CPM_AddExternal(<name>         # Required - External name (will be used to lookup external).
#    [GIT_REPOSITORY repo]        # Indicates git repository containing recipe to build external.
#    [GIT_TAG tag]                # Tag inside of the git repo.
#    [VERSION version]            # Attempt to find this version number.
#    )
#
# Also remember: you will probably want to use add_dependencies with the
# ${CPM_LIBRARIES}.
#
# CPM also adds the following variables to the global namespace for CPM
# script purposes only. These variables are unlikely to be useful to you.
#
#  CPM_DIR_OF_CPM       - Variable that stores the location of *this* file.
#  CPM_NS_HEADER_FILE   - Namespace header file.

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

# Run a regex to extract parameter names from the *this* file (CPM.cmake).
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

# Include dependencies
include(ExternalProject)
find_package(Git)
if(NOT GIT_FOUND)
  message(FATAL_ERROR "CPM requires Git.")
endif()

# Record where this list file is located. We pass this directory into our
# modules so they can also include SpirePM.
# We do NOT want to access CMAKE_CURRENT_LIST_DIR from a function invokation.
# If we do, then CMAKE_CURRENT_LIST_DIR will contain the calling CMakeLists.txt
# file. See: http://stackoverflow.com/questions/12802377/in-cmake-how-can-i-find-the-directory-of-an-included-file
set(CPM_DIR_OF_CPM ${CMAKE_CURRENT_LIST_DIR})

# If CPM_UNIQUE_ID exists then use that as the base directory for CPM.
# Note that we are already in the parent's namespace (we are not in a
# function), so we directly modify the appropriate GLOBAL variables.
if (DEFINED CPM_UNIQUE_ID)
  set(CPM_NS_HEADER_FILE "${CPM_DIR_OF_CPM}/include/${CPM_UNIQUE_ID}/cpm/cpm.h")
  set(CPM_INCLUDE_DIRS "${CPM_DIR_OF_CPM}/include/${CPM_UNIQUE_ID}")
else()
  set(CPM_NS_HEADER_FILE "${CPM_DIR_OF_CPM}/include/cpm/cpm.h")
  set(CPM_INCLUDE_DIRS "${CPM_DIR_OF_CPM}/include")
endif()

# Delete old cpm header file and begin constructing a new one.
file(REMOVE ${CPM_NS_HEADER_FILE})
file(APPEND ${CPM_NS_HEADER_FILE} "// This file was automatically generated by CPM.\n")
file(APPEND ${CPM_NS_HEADER_FILE} "// It includes all automatically generated namespaces.\n")

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

# Function for clearing parsed arguments. Used directly before calling
# add_subdirectory on a child module.
function(_cpm_clear_arguments f ns args)
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
        set(${ns}${key} PARENT_SCOPE)
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
# This is only for CMake files.
function(_cpm_build_target_output_dirs parent_var_to_update output_dir)

  set(outputs)
  set(outputs ${outputs} "-DCMAKE_RUNTIME_OUTPUT_DIRECTORY:STRING=${output_dir}")
  set(outputs ${outputs} "-DCMAKE_LIBRARY_OUTPUT_DIRECTORY:STRING=${output_dir}")
  set(outputs ${outputs} "-DCMAKE_ARCHIVE_OUTPUT_DIRECTORY:STRING=${output_dir}")

  # Second, for multi-config builds (e.g. msvc)
  foreach(OUTPUTCONFIG ${CMAKE_CONFIGURATION_TYPES})
    string(TOUPPER ${OUTPUTCONFIG} OUTPUTCONFIG_UPPER)
    set(outputs ${outputs} "-DCMAKE_RUNTIME_OUTPUT_DIRECTORY_${OUTPUTCONFIG_UPPER}:STRING=${output_dir}/${OUTPUTCONFIG}")
    set(outputs ${outputs} "-DCMAKE_LIBRARY_OUTPUT_DIRECTORY_${OUTPUTCONFIG_UPPER}:STRING=${output_dir}/${OUTPUTCONFIG}")
    set(outputs ${outputs} "-DCMAKE_ARCHIVE_OUTPUT_DIRECTORY_${OUTPUTCONFIG_UPPER}:STRING=${output_dir}/${OUTPUTCONFIG}")
  endforeach(OUTPUTCONFIG CMAKE_CONFIGURATION_TYPES)

  set(${parent_var_to_update} ${outputs} PARENT_SCOPE)

endfunction()

# Same as above but places the output directories in the parent scope.
function(_cpm_set_target_output_dirs parent_var_to_update output_dir)

  set(CMAKE_RUNTIME_OUTPUT_DIRECTORY "${output_dir}" PARENT_SCOPE)
  set(CMAKE_LIBRARY_OUTPUT_DIRECTORY "${output_dir}" PARENT_SCOPE)
  set(CMAKE_ARCHIVE_OUTPUT_DIRECTORY "${output_dir}" PARENT_SCOPE)

  # Second, for multi-config builds (e.g. msvc)
  foreach(OUTPUTCONFIG ${CMAKE_CONFIGURATION_TYPES})
    string(TOUPPER ${OUTPUTCONFIG} OUTPUTCONFIG_UPPER)
    set(CMAKE_RUNTIME_OUTPUT_DIRECTORY_${OUTPUTCONFIG_UPPER} "${output_dir}/${OUTPUTCONFIG}" PARENT_SCOPE)
    set(CMAKE_LIBRARY_OUTPUT_DIRECTORY_${OUTPUTCONFIG_UPPER} "${output_dir}/${OUTPUTCONFIG}" PARENT_SCOPE)
    set(CMAKE_ARCHIVE_OUTPUT_DIRECTORY_${OUTPUTCONFIG_UPPER} "${output_dir}/${OUTPUTCONFIG}" PARENT_SCOPE)
  endforeach(OUTPUTCONFIG CMAKE_CONFIGURATION_TYPES)

endfunction()

function(CPM_AddModule)

  # Parse all function arguments into our namespace prepended with _CPM_.
  _cpm_parse_arguments(CPM_AddModule _CPM_ "${ARGN}")

  # Determine base module directory and target directory for module.
  set(__CPM_BASE_MODULE_DIR "${CPM_DIR_OF_CPM}/modules")

  # Sane default for GIT_TAG if it is not specified
  if (DEFINED _CPM_GIT_TAG)
    set(git_tag ${_CPM_GIT_TAG})
  else()
    set(git_tag "origin/master")
  endif()

  if ((NOT DEFINED _CPM_GIT_REPOSITORY) AND (NOT DEFINED _CPM_SOURCE_DIR))
    message(FATAL_ERROR "CPM: You must specify either a git repository or source directory.")
  endif()

  if ((DEFINED _CPM_GIT_REPOSITORY) AND (DEFINED _CPM_SOURCE_DIR))
    message(FATAL_ERROR "CPM: You cannot specify both a git repository and a source directory.")
  endif()

  # Check to see if we should use git to download the source.
  set(__CPM_USING_GIT FALSE)
  if (DEFINED _CPM_GIT_REPOSITORY)
    set(__CPM_USING_GIT TRUE)

    set(__CPM_PATH_UNID ${_CPM_GIT_REPOSITORY})
    string(REGEX REPLACE "https://github.com/" "github_" __CPM_PATH_UNID "${__CPM_PATH_UNID}")
    string(REGEX REPLACE "http://github.com/" "github_" __CPM_PATH_UNID "${__CPM_PATH_UNID}")

    set(__CPM_PATH_UNID "${__CPM_PATH_UNID}_${_CPM_GIT_TAG}")
  endif()

  # Check to see if the source is stored locally.
  if (DEFINED _CPM_SOURCE_DIR)
    set(__CPM_PATH_UNID ${_CPM_SOURCE_DIR})
    set(__CPM_MODULE_SOURCE_DIR "${_CPM_SOURCE_DIR}")
  endif()

  # Build UNID
  # Get rid of any characters that would be offensive to paths.
  string(REGEX REPLACE "/" "_" __CPM_PATH_UNID "${__CPM_PATH_UNID}")
  # Ensure the 'hyphen (-)' is at the beginning or end of the [].
  string(REGEX REPLACE "[:/\\.?-]" "" __CPM_PATH_UNID "${__CPM_PATH_UNID}")

  # Construct paths from UNID
  set(__CPM_MODULE_BIN_DIR "${__CPM_BASE_MODULE_DIR}/${__CPM_PATH_UNID}/bin")

  if (__CPM_USING_GIT)
    set(__CPM_MODULE_SOURCE_DIR "${__CPM_BASE_MODULE_DIR}/${__CPM_PATH_UNID}/src")
    # Download the code if it doesn't already exist. Otherwise make sure
    # the code is updated (on the latest branch or tag).
    if (NOT EXISTS "${__CPM_MODULE_SOURCE_DIR}/")
      message(STATUS "Cloning module repo (${_CPM_GIT_REPOSITORY})")
      # Much of this clone code is taken from external project's generation
      # of its *gitclone.cmake files.
      # Try the clone 3 times (from External Project source).
      # We don't set a timeout here because we absolutely need to clone the
      # directory in order to continue with the build process.
      set(error_code 1)
      set(number_of_tries 0)
      while(error_code AND number_of_tries LESS 3)
        execute_process(
          COMMAND "${GIT_EXECUTABLE}" clone "${_CPM_GIT_REPOSITORY}" "${__CPM_MODULE_SOURCE_DIR}"
          WORKING_DIRECTORY "${CPM_DIR_OF_CPM}"
          RESULT_VARIABLE error_code
          )
        math(EXPR number_of_tries "${number_of_tries} + 1")
      endwhile()

      # Check to see if we really have cloned the repository.
      if(number_of_tries GREATER 1)
        message(STATUS "Had to git clone more than once:
        ${number_of_tries} times.")
      endif()
      if(error_code)
        message(FATAL_ERROR "Failed to clone repository: 'https://github.com/SCIInstitute/spire'")
      endif()

      # Checkout the appropriate tag.
      execute_process(
        COMMAND "${GIT_EXECUTABLE}" checkout ${_CPM_GIT_TAG}
        WORKING_DIRECTORY "${__CPM_MODULE_SOURCE_DIR}"
        RESULT_VARIABLE error_code
        OUTPUT_QUIET
        ERROR_QUIET
        )
      if(error_code)
        message(FATAL_ERROR "Failed to checkout tag: '${_CPM_GIT_TAG}'")
      endif()

      # Initialize and update any submodules that may be present in the repo.
      execute_process(
        COMMAND "${GIT_EXECUTABLE}" submodule init
        WORKING_DIRECTORY "${__CPM_MODULE_SOURCE_DIR}"
        RESULT_VARIABLE error_code
        )
      if(error_code)
        message(FATAL_ERROR "Failed to init submodules in: '${__CPM_MODULE_SOURCE_DIR}'")
      endif()

      execute_process(
        COMMAND "${GIT_EXECUTABLE}" submodule update --recursive
        WORKING_DIRECTORY "${__CPM_MODULE_SOURCE_DIR}"
        RESULT_VARIABLE error_code
        )
      if(error_code)
        message(FATAL_ERROR "Failed to update submodules in: '${__CPM_MODULE_SOURCE_DIR}'")
      endif()
    endif()

    # Attempt to update with a timeout.
    execute_process(
      COMMAND "${GIT_EXECUTABLE}" rev-list --max-count=1 HEAD
      WORKING_DIRECTORY "${__CPM_MODULE_SOURCE_DIR}"
      RESULT_VARIABLE error_code
      OUTPUT_VARIABLE head_sha
      )
    if(error_code)
      message(FATAL_ERROR "Failed to get the hash for HEAD")
    endif()

    execute_process(
      COMMAND "${GIT_EXECUTABLE}" show-ref master
      WORKING_DIRECTORY "${__CPM_MODULE_SOURCE_DIR}"
      OUTPUT_VARIABLE show_ref_output
      )
    # If a remote ref is asked for, which can possibly move around,
    # we must always do a fetch and checkout.
    if("${show_ref_output}" MATCHES "remotes")
      set(is_remote_ref 1)
    else()
      set(is_remote_ref 0)
    endif()

    # This will fail if the tag does not exist (it probably has not been fetched
    # yet).
    execute_process(
      COMMAND "${GIT_EXECUTABLE}" rev-list --max-count=1 master
      WORKING_DIRECTORY "${__CPM_MODULE_SOURCE_DIR}"
      RESULT_VARIABLE error_code
      OUTPUT_VARIABLE tag_sha
      )

    # Is the hash checkout out that we want?
    if(error_code OR is_remote_ref OR NOT ("${tag_sha}" STREQUAL "${head_sha}"))
      # Fetch the remote repository and limit it to 15 seconds.
      execute_process(
        COMMAND "${GIT_EXECUTABLE}" fetch
        WORKING_DIRECTORY "${__CPM_MODULE_SOURCE_DIR}"
        RESULT_VARIABLE error_code
        TIMEOUT 15
        )
      if(error_code)
        message("Failed to fetch repository '${_CPM_GIT_REPOSITORY}'. Skipping fetch.")
      endif()

      execute_process(
        COMMAND "${GIT_EXECUTABLE}" checkout ${_CPM_GIT_TAG}
        WORKING_DIRECTORY "${__CPM_MODULE_SOURCE_DIR}"
        RESULT_VARIABLE error_code
        OUTPUT_QUIET
        ERROR_QUIET
        )
      if(error_code)
        message(FATAL_ERROR "Failed to checkout tag: '${_CPM_GIT_TAG}'")
      endif()

      execute_process(
        COMMAND "${GIT_EXECUTABLE}" submodule update --recursive
        WORKING_DIRECTORY "${__CPM_MODULE_SOURCE_DIR}"
        RESULT_VARIABLE error_code
        TIMEOUT 15
        )
      if(error_code)
        message("Failed to update submodules in: '${__CPM_MODULE_SOURCE_DIR}'. Skipping submodule update.")
      endif()
    endif()

  endif(__CPM_USING_GIT)

  # We are either using the git clone or we are using a user supplied source
  # directory. We are ready to set our target variables and proceed with
  # the add subdirectory.

  # Set variables CPM will use inside of the library target.
  set(CPM_UNIQUE_ID ${__CPM_PATH_UNID})
  set(CPM_TARGET_NAME "${__CPM_PATH_UNID}_ep")
  set(CPM_OUTPUT_LIB_NAME ${__CPM_PATH_UNID})
  set(CPM_DIR ${CPM_DIR_OF_CPM})

  # Set target output directories.
  _cpm_set_target_output_dirs(_ep_output_bin_dirs "${__CPM_MODULE_BIN_DIR}")

  # Clear out the arguments so the child instances of CPM don't pick them up.
  # !!!!! NOTE !!!!!  If you want access to the _CPM arguments after this point,
  #                   you must reparse them using _cpm_parse_arguments
  _cpm_clear_arguments(CPM_AddModule _CPM_ "${ARGN}")

  # Clear out other variables we set in the function that may interfer
  # with further calls to CPM.
  set(__CPM_USING_GIT)
  set(__CPM_BASE_MODULE_DIR)

  # Setup the project.
  add_subdirectory("${__CPM_MODULE_SOURCE_DIR}" "${__CPM_MODULE_BIN_DIR}")

  # Append a definition to the cpm header file that must be included to
  # correct for the namespace modifications.
  file(APPEND ${CPM_NS_HEADER_FILE} "using namespace ${__CPM_PATH_UNID};\n")

  # Append target to pre-existing libraries.
  set(CPM_LIBRARIES ${CPM_LIBRARIES} "${CPM_TARGET_NAME}" PARENT_SCOPE)

  # Note: This is where we should perform an additional external project step
  #       (ExternalProject_Add_Step) to copy the include files to the 
  #       appropriate directory if INCLUDE_PREFIX was specified. Then set
  #       CPM_INCLUDE_DIRS to the appropriate value.
  set(CPM_INCLUDE_DIRS ${CPM_INCLUDE_DIRS} "${__CPM_MODULE_SOURCE_DIR}/include")

endfunction()

function(CPM_AddExternal name)
  # Attempt to find common directory for external project build recipes?
  # Or just download them to the cpm directory?
endfunction()

## 'name' - Name of the target that will be created.
#function(CPM_AddModule name)
#
#  # Parse all function arguments into our namespace prepended with _CPM_.
#  _cpm_parse_arguments(CPM_AddModule _CPM_ "${ARGN}")
#
#  # Determine base module directory and target directory for module.
#  set(base_module_dir "${CPM_DIR_OF_CPM}/modules")
#
#  # Sane default for GIT_TAG if it is not specified
#  if (DEFINED _CPM_GIT_TAG)
#    set(git_tag ${_CPM_GIT_TAG})
#  else()
#    set(git_tag "origin/master")
#  endif()
#
#  if ((NOT DEFINED _CPM_GIT_REPOSITORY) AND (NOT DEFINED _CPM_SOURCE_DIR))
#    message(FATAL_ERROR "CPM: You must specify either a git repository or source directory.")
#  endif()
#
#  # Check to see if we should use git to download the source.
#  set(using_git FALSE)
#  if (DEFINED _CPM_GIT_REPOSITORY)
#    set(using_git TRUE)
#    set(git_repo ${_CPM_GIT_REPOSITORY})
#
#    set(_ep_git_repo "GIT_REPOSITORY" "${git_repo}")
#    set(_ep_git_tag "GIT_TAG" ${_SPM_GIT_TAG})
#
#    set(path_unid ${git_repo})
#    string(REGEX REPLACE "https://github.com/" "github_" path_unid "${path_unid}")
#    string(REGEX REPLACE "http://github.com/" "github_" path_unid "${path_unid}")
#
#    set(path_unid "${path_unid}_${git_tag}")
#  endif()
#
#  # Check to see if the source is stored locally.
#  if (DEFINED _CPM_SOURCE_DIR)
#    set(path_unid ${_CPM_SOURCE_DIR})
#    set(_ep_source_dir "SOURCE_DIR" "${_CPM_SOURCE_DIR}")
#  endif()
#
#  # Get rid of any characters that would be offensive to paths.
#  string(REGEX REPLACE "/" "_" path_unid "${path_unid}")
#  # Ensure the 'hyphen (-)' is at the beginning or end of the [].
#  string(REGEX REPLACE "[:/\\.?-]" "" path_unid "${path_unid}")
#
#  # Setup common directory names.
#  set(this_module_dir "${base_module_dir}/${path_unid}")
#  set(this_module_ep_dir "${base_module_dir}/${path_unid}/ep")
#  set(this_module_bin_dir "${base_module_dir}/${path_unid}/bin")
#
#  # Build a set of target output directories based off of the configuration type
#  _cpm_build_target_output_dirs(_ep_output_bin_dirs ${this_module_bin_dir})
#
#  # Setup the external project.
#  set(module_lib_name ${path_unid})
#  set(_ep_module_target "${path_unid}_ep")
#  ExternalProject_Add(${_ep_module_target}
#    "PREFIX;${this_module_ep_dir}"
#    ${_ep_git_repo}
#    ${_ep_git_tag}
#    ${_ep_source_dir}
#    INSTALL_COMMAND ""
#    CMAKE_ARGS
#      -DCMAKE_BUILD_TYPE:STRING=${CMAKE_BUILD_TYPE}
#      -DCPM_OUTPUT_LIB_NAME:STRING=${module_lib_name}
#      -DCPM_UNIQUE_ID:STRING=${path_unid}
#      -DCPM_DIR:STRING=${CPM_DIR_OF_CPM}
#      ${_ep_output_bin_dirs}
#      ${_CPM_CMAKE_ARGS}
#    )
#
#  if (DEFINED _CPM_SOURCE_DIR)
#    # Forces a build even though we are source only.
#    ExternalProject_Add_Step(${_ep_module_target} forcebuild
#      COMMAND ${CMAKE_COMMAND} -E echo
#      ALWAYS 1
#      DEPENDERS build
#      )
#  endif()
#
#  # Append a definition to the cpm header file that must be included to
#  # correct for the namespace modifications.
#  file(APPEND ${CPM_NS_HEADER_FILE} "using namespace ${path_unid};\n")
#
#  # Setup imported library.
#  set(lib_suffix ${CMAKE_STATIC_LIBRARY_SUFFIX})
#  set(lib_prefix ${CMAKE_STATIC_LIBRARY_SUFFIX})
#  set(module_library_name ${module_lib_name})
#  set(module_library_target_name ${path_unid}_primtgt)
#  set(module_library_path "${this_module_bin_dir}")
#  set(module_library_filename  "${lib_prefix}${module_lib_name}${lib_suffix}")
#  add_library(${module_library_target_name} STATIC IMPORTED GLOBAL)
#  add_dependencies(${module_library_target_name} ${_ep_module_target})
#  set_property(TARGET ${module_library_target_name} PROPERTY IMPORTED_LOCATION
#    "${module_library_path}/${module_library_filename}")
#
#  # Ensure all of the configuration locations are setup correctly.
#  # Second, for multi-config builds (e.g. msvc)
#  foreach(OUTPUTCONFIG ${CMAKE_CONFIGURATION_TYPES})
#    string(TOUPPER ${OUTPUTCONFIG} OUTPUTCONFIG_UPPER)
#    set_property(TARGET ${module_library_target_name} PROPERTY IMPORTED_LOCATION_${OUTPUTCONFIG_UPPER}
#      "${module_library_path}/${OUTPUTCONFIG}/${module_library_filename}")
#  endforeach(OUTPUTCONFIG CMAKE_CONFIGURATION_TYPES)
#
#  # Grab source directory
#  ExternalProject_Get_Property(${_ep_module_target} SOURCE_DIR)
#
#  # Append to pre-existing libraries.
#  set(CPM_LIBRARIES ${CPM_LIBRARIES} "${module_library_target_name}" PARENT_SCOPE)
#
#  # Note: This is where we should perform an additional external project step
#  #       (ExternalProject_Add_Step) to copy the include files to the 
#  #       appropriate directory if INCLUDE_PREFIX was specified. Then set
#  #       CPM_INCLUDE_DIRS to the appropriate value.
#  set(CPM_INCLUDE_DIRS ${CPM_INCLUDE_DIRS} "${SOURCE_DIR}/include")
#
#endfunction()


