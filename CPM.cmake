# CPM - Cmake based C++ Package Manager
#
# A CMake module for managing external dependencies.
# CPM can be used to build traditional C/C++ libraries and CPM modules.
# In contrast to traditional C++ libraries, CPM modules have namespace
# alteration and allow for multiple different versions of the same library to
# be statically linked together and easily used without namespace conflicts.
# CPM modules use add_subdirectory for CPM modules and ExternalProject for
# traditional builds. CPM is inspired by Node.js' NPM package manager. 
#
# CPM's primary function is CPM_AddModule(...).
# CPM_AddModule accepts a few of the same parameters as ExternalProject
# alongside adding a few of its own.
# 
# The following variables are created in / appended to PARENT_SCOPE whenever
# the add module function is called:
# 
#  CPM_INCLUDE_DIRS     - All module search paths.
#  CPM_LIBRARIES        - All targets to link against.
#  CPM_DEPENDENCIES     - All dependencies. In some cases, this is different than CPM_LIBRARIES.
#  CPM_DEFINITIONS      - Definitions for all CPM namespaces.
#
# Add module function reference:
#  CPM_AddModule(<name>           # Required - Module target name.
#    [GIT_TAG tag]                # Git tag to checkout when repository is downloaded. Tags, shas, and branches all work.
#    [GIT_REPOSITORY repo]        # Git repository to fetch source data from.
#    [USE_EXISTING_VER truth]     # If set to true then the module will attempt to use a pre-existing version of the module.
#    [SOURCE_DIR dir]             # Uses 'dir' as the source directory as opposed to downloading.
#    [SOURCE_GHOST_GIT_REPO repo] # Ghost repository when using SOURCE_DIR.
#    [SOURCE_GHOST_GIT_TAG tag]   # Ghost git tag when using SOURCE_DIR.
#    [EXPORT_MODULE truth]        # If true, then the module's definitions and includes will be exported to the consumer.
#    [FORWARD_DECLARATION truth]  # If true, then only the module's preprocessor definition (that the <name> argument above is used to generate) is exported to the consumer of the module. This is useful for situations where you only need to forward declare a module's classes in your interface classes and not actually include any of the target module's interface headers. This is preferred over EXPORT_MODULE as it is much lighter.
#    )
#
# When using SOURCE_DIR, SOURCE_GHOST_GIT_REPO and SOURCE_GHOST_GIT_TAG are used
# only when generating unique identifiers for the module. In this way, you can
# use GHOST repositories and tags to ensure CPM generates consistent unique IDs.
# For an example of using these parameters (mostly in testing), see
# https://github.com/SCIInstitute/spire. Particularly the batch renderer's
# CMakeLists.txt file.
#
# Define CPM_SHOW_HIERARCHY to see all modules and their dependencies in a
# hierarchical fashion. The output from defining this is usually best viewed
# after all of the modules have cloned their source.
#
# Many settings are automatically applied for modules. Setting SOURCE_DIR is
# not recommeneded unless you are managing the header locations for the source
# directory manually. If you set the source directory the project will not be
# downloaded and will not be updated using git. You must manage that manually.
#
# Also remember: you will probably want to use add_dependencies with the
# ${CPM_LIBRARIES}.
#
# The following is a reference for CPM_EnsureRepoCurrent, a utility function
# that allows CPM users to ensure a repository is available at some target
# directory location. This function is useful for creating modules for external
# header only libraries.
#
#  CPM_EnsureRepoIsCurrent(
#    [TARGET_DIR dir]             # Required - Directory to place repository.
#    [GIT_REPOSITORY repo]        # Git repository to clone and update in TARGET_DIR.
#    [GIT_TAG tag]                # Git tag to checkout.
#    [SVN_REPOSITORY repo]        # SVN repository to checkout.
#    [SVN_REVISION rev]           # SVN revision.
#    [SVN_TRUST_CERT 1]           # Trust the Subversion server site certificate
#    )
#
# CPM also adds the following variables to the global namespace for CPM script
# purposes only. These variables are unlikely to be useful to you.
#
#  CPM_DIR_OF_CPM               - Variable that stores the location of *this*
#                                 file.
#  CPM_KV_MOD_VERSION_MAP_*     - A key/value module version mapping.
#                                 Key: Unique path (no version)
#                                 Val: The most recently added module version.
#                                 This is used to enforce, if requested, that 
#                                 only one version of a particular module exists
#                                 in the build.
#  CPM_KV_LIST_MOD_VERSION_MAP  - A list of entries in CPM_KV_MOD_VERSION_MAP. 
#                                 This list is used to propagate information to
#                                 the parent_scope when CPM_INIT_MODULE is
#                                 called and at the end of the AddModule
#                                 function.
#  CPM_KV_SOURCE_ADDED_MAP_*    - Key/value added source map. Ensures we don't
#                                 add the same module twice.
#                                 Key: Full unique path.
#                                 Value: Module's chosen name. This name is used
#                                        to generate a preprocessor token when
#                                        the module is exported.
#  CPM_KV_LIST_SOURCE_ADDED_MAP - A list of entries in CPM_KV_SOURCE_ADDED_MAP.
#                                 Used to ensure we don't issue duplicate
#                                 add_subdirectory calls.
#  CPM_KV_PREPROC_NS_MAP_*      - A key/value C preprocessor namespace mapping.
#                                 Key: C Preprocessor name.
#                                 Val: The *full* unique ID of the module. 
#                                 This ensures that namespace definitions do not
#                                 overlap on one another. Either by accident by
#                                 naming different modules the same, or through
#                                 an imported modules interface (modules can 
#                                 force you to import a particular version of a
#                                 module if they expose it in their interface).
#  CPM_KV_LIST_PREPROC_NS_MAP   - A list of entries in CPM_KV_PREPROC_NS_MAP.
#                                 This list is used to clear the map when
#                                 descending the build hierarchy using 
#                                 add_subdirectory.
#  CPM_KV_INCLUDE_MAP_*         - A key/value mapping from unique id to a
#                                 list of include files.
#                                 Key: unique path (with version)
#                                 Value: List of include statements.
#                                 Used only for determining includes that are
#                                 associated with an exported module.
#  CPM_KV_LIST_INCLUDE_MAP      - A list of entries in CPM_KV_INCLUDE_MAP.
#
#  CPM_KV_DEFINITION_MAP_*      - A key/value mapping from unique id to
#                                 definitions.
#                                 Key: unique path (with version)
#                                 Value: List of definitions.
#                                 Used only for determining definitions that are
#                                 associated with an exported module.
#  CPM_KV_LIST_DEFINITION_MAP   - A list of values in the definition map.
#
#  CPM_KV_LIB_TARGET_MAP_*      - A key/value mapping from unique id to
#                                 additional targets to link against.
#                                 Key: unique path (with version).
#                                 Value: List of additional targets.
#                                 Used to determine the list of additional
#                                 targets associated with an exported module.
#  CPM_KV_LIST_LIB_TARGET_MAP   - A list of all key values in the library
#                                 target map (CPM_KV_LIB_TARGET_MAP_*).
#  CPM_KV_FORWARD_DECL_MAP_*    - A key/value mapping of unique id to forward
#                                 declaration pairs. This map is also used
#                                 during the export module process to determine
#                                 what the module was named by the exporter
#                                 module.
#                                 Key: unique path (with version)
#                                 Value: Pairs consisting of the following:
#                                        (unique_id_for_fwd_decl, new_name).
#  CPM_KV_LIST_FORWARD_DECL_MAP - A list of entries in CPM_KV_FORWARD_DECL_MAP.
#
#  CPM_KV_EXPORT_MAP_*          - A key/value mapping of all exported modules
#                                 from a module.
#                                 Key: unique path (with version).
#                                 Value: A list of modules that have been 
#                                        exported. In particular, this value is
#                                        their full unique id.
#  CPM_KV_LIST_EXPORT_MAP       - List of values from exported module map.
#
#  CPM_KV_UNID_MAP_*            - Map of full unique IDs. This map is cleared
#                                 everytime CPM is included.
#                                 Key: User defined name of the module.
#                                 Value: Unique ID of the module.
#  CPM_KV_LIST_UNID_MAP         - List of user defined module names that have
#                                 been added to the unid map.
#
#  CPM_KV_SOURCEDIR_MAP_*       - Map of source directories. This map is cleared
#                                 everytime CPM is included.
#                                 Key: User defined name of the module.
#                                 Value: Source directory.
#  CPM_KV_LIST_SOURCEDIR_MAP    - List of user defined module names that have
#                                 been added to the sourcedir map.
#
#  CPM_EXPORTED_MODULES         - Used to determine what modules are exported.
#
#  CPM_HIERARCHY_LEVEL          - Contains current CPM hierarchy level.
#
# NOTE: End users aren't required to finalize their modules after they add them
# because all appropriate constraints do not need to be propogated further then
# the top level file. 
#
# Additional functions and macros.
#
#  CPM_ExportAdditionalDefinition <def>
#
#     Exports an additional definition in the parent scope, from the module.
#     Use sparingly. Primarily used to expose mandatory external project
#     definitions to the parent module.
#
#  CPM_ExportAdditionalIncludeDir <dir>
#
#     Exposes an additional include directory to the consumer of a module.
#     Use sparingly. Primarily used to expose external project directories
#     to module consumers.
#
#  CPM_ExportAdditionalLibraryTarget <target>
#
#     This function is mostly used to avoid having to name targets
#     per the ${CPM_TARGET_NAME} convention in CPM. For an example of its use
#     see http://github.com/iauns/cpm-google-test. Google test generates 
#     its own target name when included as a subdirectory, so we must use
#     that name.
#
#  CPM_ForceOnlyOneModuleVersion
#
#     When called from a module, this function ensures that we use only one
#     version of that module throughout our static linkage. This is mandatory
#     for modules which import code not written as a CPM module. Such as
#     code built with CMake's ExternalProject.
#
#  CPM_GetSourceDir <variable_to_set> <name>
#
#     Retrieves the source directory for the module.
#
#
#
# TODO: Consolidate the definitions, includes, and target_lib map lists.
# TODO: Add ability to patch source directories after we download them.
#
#-------------------------------------------------------------------------------
# Pre-compute a regex to match documented keywords for each command.
#-------------------------------------------------------------------------------
# This code parses the *current* file and extracts parameter key words from the
# documentation given above. It will match "# ... [...] # ..." style
# statements, or "#  <funcname>(" style statements.  This code was pretty much
# lifted directly from KitWare's ExternalProject.cmake, but then I documented
# what it's doing. It's not exactly straight forward.

# Based on the current line in *this* file (CPM.cmake), we calc the number
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
find_package(Git)
if(NOT GIT_FOUND)
  message(FATAL_ERROR "CPM requires Git.")
endif()

macro(_cpm_debug_log debug)
  if ((DEFINED _CPM_DEBUG_LOG) AND (_CPM_DEBUG_LOG))
    message("== ${debug}")
  endif()
endmacro()

# Record where this list file is located. We pass this directory into our
# modules so they can also include SpirePM.
# We do NOT want to access CMAKE_CURRENT_LIST_DIR from a function invokation.
# If we do, then CMAKE_CURRENT_LIST_DIR will contain the calling CMakeLists.txt
# file. See: http://stackoverflow.com/questions/12802377/in-cmake-how-can-i-find-the-directory-of-an-included-file
set(CPM_DIR_OF_CPM ${CMAKE_CURRENT_LIST_DIR})

# Clear out any definitions a parent_scope might have declared.
set(CPM_DEFINITIONS)

# Clear out any include directories.
set(CPM_INCLUDE_DIRS)

# Clear out exported modules from the parent.
set(CPM_EXPORTED_MODULES)

# Ensure we add an entry in the forward declaration map list for ourselves
# (even if we don't even add a forward declaration).
set(CPM_KV_LIST_FORWARD_DECL_MAP ${CPM_KV_LIST_FORWARD_DECL_MAP} ${CPM_UNIQUE_ID})

# Increment the module hierarchy level if it exists.
if (NOT DEFINED CPM_HIERARCHY_LEVEL)
  set(CPM_HIERARCHY_LEVEL 0)
endif()

# Initial display of the hierarchy if the user requested it.
if ((DEFINED CPM_SHOW_HIERARCHY) AND (CPM_SHOW_HIERARCHY))
  if (CPM_HIERARCHY_LEVEL EQUAL 0)
    message("CPM Module Dependency Hierarchy:")
    message("Root")
  endif()
endif()

# Clear out the old CPM_KV_PREPROC_NS_MAP
foreach(_cpm_kvName IN LISTS CPM_KV_LIST_PREPROC_NS_MAP)
  set(CPM_KV_PREPROC_NS_MAP_${_cpm_kvName})
endforeach()
# Clear out both the list, and the 'for' variable
set(CPM_KV_LIST_PREPROC_NS_MAP)
set(_cpm_kvName)

# Clear out the old CPM_KV_UNID_MAP
foreach(_cpm_kvName IN LISTS CPM_KV_LIST_UNID_MAP)
  set(CPM_KV_UNID_MAP_${_cpm_kvName})
endforeach()
# Clear out both the list, and the 'for' variable
set(CPM_KV_LIST_UNID_MAP)
set(_cpm_kvName)

# Clear out the old CPM_KV_SOURCEDIR_MAP
foreach(_cpm_kvName IN LISTS CPM_KV_LIST_SOURCEDIR_MAP)
  set(CPM_KV_SOURCEDIR_MAP_${_cpm_kvName})
endforeach()
# Clear out both the list, and the 'for' variable
set(CPM_KV_LIST_SOURCEDIR_MAP)
set(_cpm_kvName)

set(CPM_ADDITIONAL_INCLUDE_DIRS)
set(CPM_ADDITIONAL_DEFINITIONS)

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

# Builds the preprocessor name from 'name' and stores it in 'parentVar'.
function(_cpm_build_preproc_name name parentVar)
  string(TOUPPER ${name} CPM_UPPER_CASE_NAME)
  set(${parentVar} "CPM_${CPM_UPPER_CASE_NAME}_NS" PARENT_SCOPE)
endfunction()

macro(_cpm_propogate_version_map_up)
  # Use CPM_KV_LIST_MOD_VERSION_MAP to propogate constraints up into the
  # parent CPM_AddModule function's namespace. CPM_AddModule will
  # propogate the versioning information up again to it's parent's namespace.
  if (NOT CPM_HIERARCHY_LEVEL EQUAL 0)
    foreach(_cpm_kvName IN LISTS CPM_KV_LIST_MOD_VERSION_MAP)
      set(CPM_KV_MOD_VERSION_MAP_${_cpm_kvName} ${CPM_KV_MOD_VERSION_MAP_${_cpm_kvName}} PARENT_SCOPE)
    endforeach()
    set(_cpm_kvName) # Clear kvName

    # Now propogate the list itself upwards.
    set(CPM_KV_LIST_MOD_VERSION_MAP ${CPM_KV_LIST_MOD_VERSION_MAP} PARENT_SCOPE)
  endif()
endmacro()

# Propogates the list of directories we have sourced upwards.
macro(_cpm_propogate_source_added_map_up)
  if (NOT CPM_HIERARCHY_LEVEL EQUAL 0)
    foreach(_cpm_kvName IN LISTS CPM_KV_LIST_SOURCE_ADDED_MAP)
      set(CPM_KV_SOURCE_ADDED_MAP_${_cpm_kvName} ${CPM_KV_SOURCE_ADDED_MAP_${_cpm_kvName}} PARENT_SCOPE)
    endforeach()
    set(_cpm_kvName) # Clear kvName

    # Now propogate the list itself upwards.
    set(CPM_KV_LIST_SOURCE_ADDED_MAP ${CPM_KV_LIST_SOURCE_ADDED_MAP} PARENT_SCOPE)
  endif()
endmacro()

# Propogates include map up.
macro(_cpm_propogate_include_map_up)
  if (NOT CPM_HIERARCHY_LEVEL EQUAL 0)
    foreach(_cpm_kvName IN LISTS CPM_KV_LIST_INCLUDE_MAP)
      set(CPM_KV_INCLUDE_MAP_${_cpm_kvName} ${CPM_KV_INCLUDE_MAP_${_cpm_kvName}} PARENT_SCOPE)
    endforeach()
    set(_cpm_kvName) # Clear kvName

    # Now propogate the list itself upwards.
    set(CPM_KV_LIST_INCLUDE_MAP ${CPM_KV_LIST_INCLUDE_MAP} PARENT_SCOPE)
  endif()
endmacro()

# Propogates definition map up.
macro(_cpm_propogate_definition_map_up)
  if (NOT CPM_HIERARCHY_LEVEL EQUAL 0)
    foreach(_cpm_kvName IN LISTS CPM_KV_LIST_DEFINITION_MAP)
      set(CPM_KV_DEFINITION_MAP_${_cpm_kvName} ${CPM_KV_DEFINITION_MAP_${_cpm_kvName}} PARENT_SCOPE)
    endforeach()
    set(_cpm_kvName) # Clear kvName

    # Now propogate the list itself upwards.
    set(CPM_KV_LIST_DEFINITION_MAP ${CPM_KV_LIST_DEFINITION_MAP} PARENT_SCOPE)
  endif()
endmacro()

# Propogates forward declaration map up.
macro(_cpm_propogate_forward_decl_map_up)
  if (NOT CPM_HIERARCHY_LEVEL EQUAL 0)
    foreach(_cpm_kvName IN LISTS CPM_KV_LIST_FORWARD_DECL_MAP)
      set(CPM_KV_FORWARD_DECL_MAP_${_cpm_kvName} ${CPM_KV_FORWARD_DECL_MAP_${_cpm_kvName}} PARENT_SCOPE)
    endforeach()
    set(_cpm_kvName) # Clear kvName

    # Now propogate the list itself upwards.
    set(CPM_KV_LIST_FORWARD_DECL_MAP ${CPM_KV_LIST_FORWARD_DECL_MAP} PARENT_SCOPE)
  endif()
endmacro()

# Propogates target library map up.
macro(_cpm_propogate_target_lib_map_up)
  if (NOT CPM_HIERARCHY_LEVEL EQUAL 0)
    foreach(_cpm_kvName IN LISTS CPM_KV_LIST_LIB_TARGET_MAP)
      set(CPM_KV_LIB_TARGET_MAP_${_cpm_kvName} ${CPM_KV_LIB_TARGET_MAP_${_cpm_kvName}} PARENT_SCOPE)
    endforeach()
    set(_cpm_kvName) # Clear kvName

    # Now propogate the list itself upwards.
    set(CPM_KV_LIST_LIB_TARGET_MAP ${CPM_KV_LIST_LIB_TARGET_MAP} PARENT_SCOPE)
  endif()
endmacro()

# Propogates export module map up.
macro(_cpm_propogate_export_map_up)
  if (NOT CPM_HIERARCHY_LEVEL EQUAL 0)
    foreach(_cpm_kvName IN LISTS CPM_KV_LIST_EXPORT_MAP)
      set(CPM_KV_EXPORT_MAP_${_cpm_kvName} ${CPM_KV_EXPORT_MAP_${_cpm_kvName}} PARENT_SCOPE)
    endforeach()
    set(_cpm_kvName) # Clear kvName

    # Now propogate the list itself upwards.
    set(CPM_KV_LIST_EXPORT_MAP ${CPM_KV_LIST_EXPORT_MAP} PARENT_SCOPE)
  endif()
endmacro()


# This macro initializes a CPM module. We use a macro for this code so that
# we can set variables in the parent namespace (if any).
# name - Same as the name parameter in CPM_AddModule. A preprocessor definition
#        using this name will be generated for namespaces.
macro(CPM_InitModule name)
  # Ensure the parent function knows what we decided to name ourselves.
  # This name will correspond to our module's namespace directives.
  if (NOT CPM_HIERARCHY_LEVEL EQUAL 0)
    set(CPM_LAST_MODULE_NAME ${name} PARENT_SCOPE)
  endif()

  # Build the appropriate definition for the module. We stored the unique ID
  _cpm_build_preproc_name(${name} __CPM_TMP_VAR)
  if (NOT DEFINED CPM_UNIQUE_ID)
    set(CPM_UNIQUE_ID CPM_TESTING_UPPER_LEVEL_NAMESPACE)
  endif()
  add_definitions("-D${__CPM_TMP_VAR}=${CPM_UNIQUE_ID}")
  set(__CPM_TMP_VAR) # Clean up

  # Propogate our exported modules up.
  if (DEFINED CPM_EXPORTED_MODULES)
    set(CPM_EXPORTED_MODULES ${CPM_EXPORTED_MODULES} PARENT_SCOPE)
  endif()

  # Propogate up additional definitions and includes.
  # (the reason we propogate this up: addition definitions can be modified
  #  from the CPM_AddModule function one scope down)
  set(CPM_ADDITIONAL_DEFINITIONS ${CPM_ADDITIONAL_DEFINITIONS} PARENT_SCOPE)

  # Setup the export map.
  set(CPM_KV_EXPORT_MAP_${CPM_UNIQUE_ID} ${CPM_EXPORTED_MODULES})
  set(CPM_KV_LIST_EXPORT_MAP ${CPM_KV_LIST_EXPORT_MAP} ${CPM_UNIQUE_ID})

  _cpm_propogate_source_added_map_up()
  _cpm_propogate_version_map_up()
  _cpm_propogate_include_map_up()
  _cpm_propogate_definition_map_up()
  _cpm_propogate_target_lib_map_up()
  _cpm_propogate_export_map_up()
  _cpm_propogate_forward_decl_map_up()

  # Setup the module with appropriate definitions and includes.
  # We can do this because we are not in a new scope; instead, we are in a macro
  # which executes in the parent scope (since it is literally inserted into
  # the parent scope).
  add_definitions(${CPM_DEFINITIONS})
  include_directories(SYSTEM ${CPM_INCLUDE_DIRS})

  include_directories(${CMAKE_CURRENT_SOURCE_DIR})
  # TODO: Remove the following line when we upgrade SCIRun.
  include_directories(SYSTEM ${CMAKE_CURRENT_SOURCE_DIR}/3rdParty)

endmacro()

# This macro is meant to be used only by the root of the CPM dependency
# hierarchy (C++ code that uses modules, but is not a module itself).
macro(CPM_Finish)
  # Ensure the parent function knows what we decided to name ourselves.
  # This name will correspond to our module's namespace directives.
  if (NOT CPM_HIERARCHY_LEVEL EQUAL 0)
    message(FATAL_ERROR "You can only call CPM_Finish from the top level of the dependency hierarchy.")
  endif()

  # Setup appropriate definitions and include directories.
  add_definitions(${CPM_DEFINITIONS})
  include_directories(SYSTEM ${CPM_INCLUDE_DIRS})

  # Ensure CPM.cmake is current. CPM_Finish will always be called at
  # the end of setting up the entire hierarchy chain. So this
  # won't affect what the modules include.
  if (NOT ((DEFINED CPM_NO_UPDATE) AND (CPM_NO_UPDATE)))
    CPM_EnsureRepoIsCurrent(
      TARGET_DIR ${CPM_DIR_OF_CPM}
      GIT_REPOSITORY "https://github.com/iauns/cpm"
      GIT_TAG "origin/master"
      )
  endif()
endmacro()

# This macro forces one, and only one, version of a module to be linked into
# a program. If any part of the build chain uses a different version of the
# module, then the CMake configure step will fail with a verbose error.
macro(CPM_ForceOnlyOneModuleVersion)
  # Set a flag in the parent namespace to force a check against module name
  # and version.
  set(CPM_FORCE_ONLY_ONE_MODULE_VERSION TRUE PARENT_SCOPE)
endmacro()

# This macro allows modules to expose additional include directories to
# consumers. This is necessary for externals, and only exposes the include
# definition to the direct consumer of the module. None of the consumer's
# parents.
macro(CPM_ExportAdditionalIncludeDir)
  foreach (item ${ARGV})
    get_filename_component(tmp_src_dir ${item} ABSOLUTE)
    set(CPM_ADDITIONAL_INCLUDE_DIRS ${CPM_ADDITIONAL_INCLUDE_DIRS} "${tmp_src_dir}" PARENT_SCOPE)
    set(CPM_ADDITIONAL_INCLUDE_DIRS ${CPM_ADDITIONAL_INCLUDE_DIRS} "${tmp_src_dir}")
  endforeach()
endmacro()

# This macro allows modules to expose additional definitions.
# As with ExportAdditionalIncludeDirectory, this only exposes the definition
# to the direct consumer of the module. None of the consumer's parents.
macro(CPM_ExportAdditionalDefinition)
  foreach (item ${ARGV})
    set(CPM_ADDITIONAL_DEFINITIONS ${CPM_ADDITIONAL_DEFINITIONS} ${item} PARENT_SCOPE)
    set(CPM_ADDITIONAL_DEFINITIONS ${CPM_ADDITIONAL_DEFINITIONS} ${item})
  endforeach()
endmacro()

macro(CPM_ExportAdditionalLibraryTarget)
  foreach (item ${ARGV})
    set(CPM_ADDITIONAL_TARGET_LIBS ${CPM_ADDITIONAL_TARGET_LIBS} ${item} PARENT_SCOPE)
    set(CPM_ADDITIONAL_TARGET_LIBS ${CPM_ADDITIONAL_TARGET_LIBS} ${item})
  endforeach()
endmacro()

# We use this code in multiple places to check that we don't have preprocessor
# conflicts, and if we don't, then add the appropriate defintion.
macro(_cpm_check_and_add_preproc defShortName fullUNID)
  _cpm_build_preproc_name(${defShortName} __CPM_LAST_MODULE_PREPROC)

  # Ensure that we don't have a name conflict
  if (DEFINED CPM_KV_PREPROC_NS_MAP_${__CPM_LAST_MODULE_PREPROC})
    if (NOT ${CPM_KV_PREPROC_NS_MAP_${__CPM_LAST_MODULE_PREPROC}} STREQUAL ${fullUNID})
      message("CPM namespace conflict.")
      message("  Current module name: ${name}.")
      message("  Conflicting propressor macro: ${__CPM_LAST_MODULE_PREPROC}.")
      message("  Our module UNID: ${fullUNID}.")
      message("  Conflicting UNID: ${CPM_KV_PREPROC_NS_MAP_${__CPM_LAST_MODULE_PREPROC}}.")
      message(FATAL_ERROR "CPM cannot continue without resolving namespace conflict.")
    endif()
  else()
    set(CPM_KV_PREPROC_NS_MAP_${__CPM_LAST_MODULE_PREPROC} ${fullUNID} PARENT_SCOPE)

    set(CPM_KV_LIST_PREPROC_NS_MAP ${CPM_KV_LIST_PREPROC_NS_MAP} ${__CPM_LAST_MODULE_PREPROC} PARENT_SCOPE)
    set(CPM_KV_LIST_PREPROC_NS_MAP ${CPM_KV_LIST_PREPROC_NS_MAP} ${__CPM_LAST_MODULE_PREPROC})
  endif()

  # Add the interface definition to our list of preprocessor definitions.
  # We don't set this in the parent scope because definitions will be propogated
  # up to the parent at the end of our function.
  set(CPM_DEFINITIONS ${CPM_DEFINITIONS} "-D${__CPM_LAST_MODULE_PREPROC}=${fullUNID}")

  # Clear our variable.
  set(__CPM_LAST_MODULE_PREPROC)
endmacro()


function(_cpm_print_with_hierarchy_level msg)
  # while ${number} is between 0 and 11
  if (DEFINED CPM_HIERARCHY_LEVEL)
    set(number 1)
    set(spacing "  ")
    while( number GREATER 0 AND number LESS ${CPM_HIERARCHY_LEVEL} )
      set(spacing "${spacing}  ")
      math( EXPR number "${number} + 1" ) # decrement number
    endwhile()
    message("${spacing}| ${msg}")
  else()
    message(msg)
  endif()
endfunction()

macro(_cpm_make_valid_unid_or_path variable)
  if (NOT "${${variable}}" STREQUAL "")
    string(REGEX REPLACE "https://github.com/" "github_" ${variable} ${${variable}})
    string(REGEX REPLACE "http://github.com/" "github_" ${variable} ${${variable}})

    # Strip off .git extension, if any.
    string(REGEX REPLACE "\\.git$" "" ${variable} ${${variable}})

    string(REGEX REPLACE "/" "_" ${variable} ${${variable}})
    string(REGEX REPLACE "[:/\\.?-]" "" ${variable} ${${variable}})
  endif()
endmacro()

macro(_cpm_obtain_version_from_params parentVar)
  if ((DEFINED _CPM_USE_EXISTING_VER) AND (_CPM_USE_EXISTING_VER))
    # Attempt to pull existing version from module hierarchy. If we don't
    # find any, and the user has defined a version, then use that version
    # (this constitutes falling through without setting parentVar).
    if (DEFINED _CPM_GIT_REPOSITORY)
      # Modify the git repository.
      set(__CPM_TMP_VAR ${_CPM_GIT_REPOSITORY})
      _cpm_make_valid_unid_or_path(__CPM_TMP_VAR)
      if (DEFINED CPM_KV_MOD_VERSION_MAP_${__CPM_TMP_VAR})
        set(${parentVar} ${CPM_KV_MOD_VERSION_MAP_${__CPM_TMP_VAR}})
      endif()
      set(__CPM_TMP_VAR)
    elseif(DEFINED _CPM_SOURCE_DIR)
      if (DEFINED _CPM_SOURCE_GHOST_GIT_REPO)
        set(__CPM_TMP_VAR ${_CPM_SOURCE_GHOST_GIT_REPO})
        _cpm_make_valid_unid_or_path(__CPM_TMP_VAR)
        if (DEFINED CPM_KV_MOD_VERSION_MAP_${__CPM_TMP_VAR})
          set(${parentVar} ${CPM_KV_MOD_VERSION_MAP_${__CPM_TMP_VAR}})
        endif()
        set(__CPM_TMP_VAR)
      endif()
    endif()
  endif()

  # Sane default for GIT_TAG if it is not specified
  if (NOT DEFINED ${parentVar})
    if (DEFINED _CPM_GIT_TAG)
      set(${parentVar} ${_CPM_GIT_TAG})
    else()
      if (DEFINED _CPM_SOURCE_GHOST_GIT_TAG)
        set(${parentVar} ${_CPM_SOURCE_GHOST_GIT_TAG})
      else()
        set(${parentVar} "origin/master")
      endif()
    endif()
  endif()
endmacro()

macro(_cpm_ensure_git_repo_is_current)
  # Tag with a sane default if not present.
  if (DEFINED _CPM_REPO_GIT_TAG)
    set(tag ${_CPM_REPO_GIT_TAG})
  else()
    set(tag "origin/master")
  endif()

  set(repo ${_CPM_REPO_GIT_REPOSITORY})
  set(dir ${_CPM_REPO_TARGET_DIR})

  if (NOT EXISTS "${dir}/")
    message(STATUS "Cloning repo (${repo} @ ${tag})")

    # Much of this clone code is taken from external project's generation
    # of its *gitclone.cmake files.
    # Try the clone 3 times (from External Project source).
    # We don't set a timeout here because we absolutely need to clone the
    # directory in order to continue with the build process.
    set(error_code 1)
    set(number_of_tries 0)
    while(error_code AND number_of_tries LESS 3)
      execute_process(
        COMMAND "${GIT_EXECUTABLE}" clone "${repo}" "${dir}"
        WORKING_DIRECTORY "${CPM_DIR_OF_CPM}"
        RESULT_VARIABLE error_code
        OUTPUT_QUIET
        ERROR_QUIET
        )
      math(EXPR number_of_tries "${number_of_tries} + 1")
    endwhile()

    # Check to see if we really have cloned the repository.
    if(number_of_tries GREATER 1)
      message(STATUS "Had to git clone more than once: ${number_of_tries} times.")
    endif()
    if(error_code)
      message(FATAL_ERROR "Failed to clone repository: '${repo}'")
    endif()

    # Checkout the appropriate tag.
    execute_process(
      COMMAND "${GIT_EXECUTABLE}" checkout ${tag}
      WORKING_DIRECTORY "${dir}"
      RESULT_VARIABLE error_code
      OUTPUT_QUIET
      ERROR_QUIET
      )
    if(error_code)
      message(FATAL_ERROR "Failed to checkout tag: '${tag}'")
    endif()

    # Initialize and update any submodules that may be present in the repo.
    execute_process(
      COMMAND "${GIT_EXECUTABLE}" submodule init
      WORKING_DIRECTORY "${dir}"
      RESULT_VARIABLE error_code
      )
    if(error_code)
      message(FATAL_ERROR "Failed to init submodules in: '${dir}'")
    endif()

    execute_process(
      COMMAND "${GIT_EXECUTABLE}" submodule update --recursive
      WORKING_DIRECTORY "${dir}"
      RESULT_VARIABLE error_code
      )
    if(error_code)
      message(FATAL_ERROR "Failed to update submodules in: '${dir}'")
    endif()
  endif()

  # Attempt to update with a timeout.
  execute_process(
    COMMAND "${GIT_EXECUTABLE}" rev-list --max-count=1 HEAD
    WORKING_DIRECTORY "${dir}"
    RESULT_VARIABLE error_code
    OUTPUT_VARIABLE head_sha
    )
  if(error_code)
    message(FATAL_ERROR "Failed to get the hash for HEAD")
  endif()

  execute_process(
    COMMAND "${GIT_EXECUTABLE}" show-ref ${tag}
    WORKING_DIRECTORY "${dir}"
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
    COMMAND "${GIT_EXECUTABLE}" rev-list --max-count=1 ${tag}
    WORKING_DIRECTORY "${dir}"
    RESULT_VARIABLE error_code
    OUTPUT_VARIABLE tag_sha
    )

  # Is the hash checkout out that we want?
  if(error_code OR is_remote_ref OR NOT ("${tag_sha}" STREQUAL "${head_sha}"))
    # Fetch the remote repository and limit it to 15 seconds.
    execute_process(
      COMMAND "${GIT_EXECUTABLE}" fetch
      WORKING_DIRECTORY "${dir}"
      RESULT_VARIABLE error_code
      TIMEOUT 15
      )
    if(error_code)
      message("Failed to fetch repository '${repo}'. Skipping fetch.")
    endif()

    execute_process(
      COMMAND "${GIT_EXECUTABLE}" checkout ${tag}
      WORKING_DIRECTORY "${dir}"
      RESULT_VARIABLE error_code
      OUTPUT_QUIET
      ERROR_QUIET
      )
    if(error_code)
      message(FATAL_ERROR "Failed to checkout tag: '${tag}'")
    endif()

    execute_process(
      COMMAND "${GIT_EXECUTABLE}" submodule update --recursive
      WORKING_DIRECTORY "${dir}"
      RESULT_VARIABLE error_code
      TIMEOUT 15
      )
    if(error_code)
      message("Failed to update submodules in: '${dir}'. Skipping submodule update.")
    endif()
  endif()
endmacro()

macro(_cpm_ensure_svn_repo_is_current)
  # Tag with a sane default if not present.
  if (DEFINED _CPM_REPO_SVN_REVISION)
    set(revision ${_CPM_REPO_SVN_REVISION})
  else()
    set(revision "HEAD")
  endif()

  find_package(Subversion)
  if(NOT Subversion_SVN_EXECUTABLE)
    message(FATAL_ERROR "error: could not find svn for checkout of ${_CPM_REPO_SVN_REPOSITORY}")
  endif()

  set(repo ${_CPM_REPO_SVN_REPOSITORY})
  set(dir ${_CPM_REPO_TARGET_DIR})

  if ((DEFINED _CPM_REPO_SVN_TRUST_CERT) AND (_CPM_REPO_TRUST_CERT))
    set(trustCert "--trust-server-cert")
  endif()

  set(svn_user_pw_args "")
  if((DEFINED _CPM_REPO_SVN_USERNAME) AND (_CPM_REPO_SVN_USERNAME))
    set(svn_user_pw_args ${svn_user_pw_args} "--username=${_CPM_REPO_SVN_USERNAME}")
  endif()
  if((DEFINED _CPM_REPO_SVN_PASSWORD) AND (_CPM_REPO_SVN_PASSWORD))
    set(svn_user_pw_args ${svn_user_pw_args} "--password=${_CPM_REPO_SVN_PASSWORD}")
  endif()

  if (NOT EXISTS "${dir}/")
    message(STATUS "SVN checking out repo (${repo} @ revision ${revision})")
    set(cmd ${Subversion_SVN_EXECUTABLE} co ${repo} -r ${revision}
      --non-interactive ${trustCert} ${svn_user_pw_args} ${dir})
    execute_process(
      COMMAND ${cmd}
      RESULT_VARIABLE result
      OUTPUT_QUIET
      ERROR_QUIET)
    if (result)
      set(msg "Command failed: ${result}\n")
      set(msg "${msg} '${cmd}'")
      message(FATAL_ERROR "${msg}")
    endif()
  endif()

  # Update the SVN repo.
  set(cmd ${Subversion_SVN_EXECUTABLE} up -r ${revision}
    --non-interactive ${trustCert} ${svn_user_pw_args})
  execute_process(
    COMMAND ${cmd}
    RESULT_VARIABLE result
    WORKING_DIRECTORY "${dir}"
    OUTPUT_QUIET
    ERROR_QUIET)
  if (result)
    set(msg "Command failed: ${result}\n")
    set(msg "${msg} '${cmd}'")
    set(msg "Skipping SVN update.")
    message("${msg}")
  endif()
endmacro()

function(CPM_EnsureRepoIsCurrent)
  _cpm_parse_arguments(CPM_EnsureRepoIsCurrent _CPM_REPO_ "${ARGN}")

  if (DEFINED _CPM_REPO_GIT_REPOSITORY)
    _cpm_ensure_git_repo_is_current()
  elseif(DEFINED _CPM_REPO_SVN_REPOSITORY)
    _cpm_ensure_svn_repo_is_current()
  else()
    message(FATAL_ERROR "CPM_EnsureRepoIsCurrent: You must specify an SVN or GIT repository.")
  endif()

endfunction()

macro(_cpm_get_base_directory VARIABLE_TO_SET)
  # Determine base module directory and target directory for module.
  set(${VARIABLE_TO_SET} "${CPM_DIR_OF_CPM}/modules")
endmacro()

function(CPM_GetSourceDir VARIABLE_TO_SET name)
  if (DEFINED CPM_KV_SOURCEDIR_MAP_${name})
    set(${VARIABLE_TO_SET} ${CPM_KV_SOURCEDIR_MAP_${name}} PARENT_SCOPE)
  else()
    message(FATAL_ERROR "${name} is not recognized as a module name")
  endif()
endfunction()

macro(_cpm_generate_map_names)
  set(INCLUDE_MAP_NAME    CPM_KV_INCLUDE_MAP_${__CPM_FULL_UNID})
  set(DEFINITION_MAP_NAME CPM_KV_DEFINITION_MAP_${__CPM_FULL_UNID})
  set(TARGET_LIB_MAP_NAME CPM_KV_LIB_TARGET_MAP_${__CPM_FULL_UNID})
endmacro()

macro(_cpm_apply_forward_declarations moduleUNID)
  if (DEFINED CPM_KV_FORWARD_DECL_MAP_${moduleUNID})
    set(fwd_decl_unid)
    foreach(item IN LISTS CPM_KV_FORWARD_DECL_MAP_${moduleUNID})
      if (DEFINED fwd_decl_unid)
        set(module_specified_name ${item})
        _cpm_check_and_add_preproc(${module_specified_name} ${fwd_decl_unid})
        set(fwd_decl_unid)
      else()
        # The unid's module name is coming up next.
        set(fwd_decl_unid ${item})
      endif()
    endforeach()
  endif()
endmacro()

# This recursive function will ensure all modules, including modules exported
# by the target module, are exported to the current level.
macro(_cpm_handle_exports_for_module_rec recUNID)
  if (DEFINED CPM_KV_EXPORT_MAP_${recUNID})
    # Search _CPM_REC_MOD_VAR to ensure we haven't attempted to export recUNID
    # before.
    foreach(existingExport IN LISTS _CPM_REC_MOD_VAR)
      if (${existingExport} STREQUAL ${recUNID})
        message("Conflicting circular UNID: ${recUNID}")
        message(FATAL_ERROR "CPM circular export references. Stopping build.")
      endif()
    endforeach()
    # Export all necessary includes, definitions, and targets.
    foreach(module IN LISTS CPM_KV_EXPORT_MAP_${recUNID})
      set(IMPORT_INCLUDE_MAP_NAME    CPM_KV_INCLUDE_MAP_${module})
      set(IMPORT_DEFINITION_MAP_NAME CPM_KV_DEFINITION_MAP_${module})
      set(IMPORT_TARGET_LIB_MAP_NAME CPM_KV_LIB_TARGET_MAP_${module})

      set(CPM_INCLUDE_DIRS ${CPM_INCLUDE_DIRS} ${${IMPORT_INCLUDE_MAP_NAME}})
      set(CPM_DEFINITIONS ${CPM_DEFINITIONS} ${${IMPORT_DEFINITION_MAP_NAME}})
      set(CPM_LIBRARIES ${CPM_LIBRARIES} ${${IMPORT_TARGET_LIB_MAP_NAME}})
      set(CPM_LIBRARIES ${CPM_LIBRARIES} PARENT_SCOPE)
      set(CPM_DEPENDENCIES ${CPM_DEPENDENCIES} ${${IMPORT_TARGET_LIB_MAP_NAME}})
      set(CPM_DEPENDENCIES ${CPM_DEPENDENCIES} PARENT_SCOPE)

      # Find what the module named itself, and add that definition to our
      # definitions.
      if (DEFINED CPM_KV_SOURCE_ADDED_MAP_${module})
        set(module_specified_name ${CPM_KV_SOURCE_ADDED_MAP_${module}})
        _cpm_check_and_add_preproc(${module_specified_name} ${module})
      else()
        message(FATAL_ERROR "Logic error: All exported modules must be in the source map.")
      endif()

      # Apply the forward declarations being used. There is always one forward
      # declaration in use for the parents of exported modules: one is required
      # for the name that the parent module gave the exported module.
      _cpm_apply_forward_declarations(${module})

      # Ensure we don't attempt to handle exports for a module we've already
      # covered.
      set(_CPM_SAVE_REC_MOD_VAR_${recUNID} ${_CPM_REC_MOD_VAR})
      set(_CPM_REC_MOD_VAR ${_CPM_REC_MOD_VAR} ${recUNID})

      # Recurse into the module we exported.
      _cpm_handle_exports_for_module(${module})

      # Remove our item from the list. We don't care if our module is added
      # in different parts of the hierarchy. We only care about circular
      # references.
      set(_CPM_REC_MOD_VAR ${_CPM_SAVE_REC_MOD_VAR_${recUNID}})
      set(_CPM_SAVE_REC_MOD_VAR_${recUNID})
    endforeach()
  endif()
endmacro()

macro(_cpm_handle_exports_for_module recUNID)
  set(_CPM_REC_MOD_VAR)
  _cpm_handle_exports_for_module_rec(${recUNID})
  set(_CPM_REC_MOD_VAR)
endmacro()

# name - Required as this name determines what preprocessor definition will
#        be generated for this module.
function(CPM_AddModule name)

  _cpm_debug_log("Beginning module: ${name}")
  _cpm_debug_log("Hierarchy level: ${CPM_HIERARCHY_LEVEL}")

  # Increase the hierarchy level by 1. Mandatory for propogate calls to work
  # at the top level.
  math(EXPR CPM_HIERARCHY_LEVEL "${CPM_HIERARCHY_LEVEL}+1")

  # Parse all function arguments into our namespace prepended with _CPM_.
  _cpm_parse_arguments(CPM_AddModule _CPM_ "${ARGN}")

  # Determine base module directory and target directory for module.
  # This function places its result into __CPM_BASE_MODULE_DIR.
  _cpm_get_base_directory(__CPM_BASE_MODULE_DIR)

  if ((NOT DEFINED _CPM_GIT_REPOSITORY) AND (NOT DEFINED _CPM_SOURCE_DIR))
    message(FATAL_ERROR "CPM: You must specify either a git repository or source directory.")
  endif()

  if ((DEFINED _CPM_GIT_REPOSITORY) AND (DEFINED _CPM_SOURCE_DIR))
    message(FATAL_ERROR "CPM: You cannot specify both a git repository and a source directory.")
  endif()

  _cpm_obtain_version_from_params(__CPM_NEW_GIT_TAG)

  # Check to see if we should use git to download the source.
  set(__CPM_USING_GIT FALSE)
  if (DEFINED _CPM_GIT_REPOSITORY)
    # Remove the .git extension if it exists. This causes the url to not
    # be a unique ID in a number of situations. _CPM_GIT_REPOSITORY is reused
    # in a number of situations; so even though _cpm_make_valid_unid_or_path
    # also removes the post-fix, we want to do it here as well.
    string(REGEX REPLACE "\\.git$" "" _CPM_GIT_REPOSITORY ${_CPM_GIT_REPOSITORY})

    set(__CPM_USING_GIT TRUE)
    set(__CPM_PATH_UNID ${_CPM_GIT_REPOSITORY})
    string(TOLOWER ${__CPM_PATH_UNID} __CPM_PATH_UNID)
    set(__CPM_PATH_UNID_VERSION "${__CPM_NEW_GIT_TAG}")
    string(TOLOWER ${__CPM_PATH_UNID_VERSION} __CPM_PATH_UNID_VERSION)
  endif()

  # Check to see if the source is stored locally.
  if (DEFINED _CPM_SOURCE_DIR)
    get_filename_component(tmp_src_dir ${_CPM_SOURCE_DIR} ABSOLUTE)

    if (DEFINED _CPM_SOURCE_GHOST_GIT_REPO)
      # See comment above regarding removing the .git postfix.
      string(REGEX REPLACE "\\.git$" "" _CPM_SOURCE_GHOST_GIT_REPO ${_CPM_SOURCE_GHOST_GIT_REPO})
      set(__CPM_PATH_UNID ${_CPM_SOURCE_GHOST_GIT_REPO})

      # Ghost tags have been taken into account in _cpm_obtain_version_from_params
      # So using __CPM_NEW_GIT_TAG here will work as expected with ghost tags.
      set(__CPM_PATH_UNID_VERSION "${__CPM_NEW_GIT_TAG}")

      # Ensure all lower case. This string is used when testing preprocessor
      # name collisions.
      string(TOLOWER ${__CPM_PATH_UNID} __CPM_PATH_UNID)
      string(TOLOWER ${__CPM_PATH_UNID_VERSION} __CPM_PATH_UNID_VERSION)
    else()
      set(__CPM_PATH_UNID ${tmp_src_dir})
      set(__CPM_PATH_UNID_VERSION "")

      string(TOLOWER ${__CPM_PATH_UNID} __CPM_PATH_UNID)
    endif()
    set(__CPM_MODULE_SOURCE_DIR "${tmp_src_dir}")

  endif()

  # Cunstruct full UNID
  _cpm_make_valid_unid_or_path(__CPM_PATH_UNID)
  _cpm_make_valid_unid_or_path(__CPM_PATH_UNID_VERSION)
  set(__CPM_FULL_UNID "${__CPM_PATH_UNID}_${__CPM_PATH_UNID_VERSION}")

  # Construct paths from UNID
  set(__CPM_MODULE_BIN_DIR "${__CPM_BASE_MODULE_DIR}/${__CPM_FULL_UNID}/bin")

  if (__CPM_USING_GIT)
    set(__CPM_MODULE_SOURCE_DIR "${__CPM_BASE_MODULE_DIR}/${__CPM_FULL_UNID}/src")
    # Do not attempt to download the source if we have already processed
    # this unique ID. This is for a corner case involving USE_EXISTING_VER.
    if (NOT DEFINED CPM_KV_SOURCE_ADDED_MAP_${__CPM_FULL_UNID})
      # Download the code if it doesn't already exist. Otherwise make sure
      # the code is updated (on the latest branch or tag).
      CPM_EnsureRepoIsCurrent(
        TARGET_DIR      ${__CPM_MODULE_SOURCE_DIR}
        GIT_REPOSITORY  ${_CPM_GIT_REPOSITORY}
        GIT_TAG         ${__CPM_NEW_GIT_TAG}
        )
    endif()
  endif(__CPM_USING_GIT)

  # Both of the following Key/Value maps use PARENT_SCOPE directly and do
  # not need propagation upwards.
  # Add UNID to lookup table (mostly to assist users in finding source directory).
  set(CPM_KV_UNID_MAP_${name} ${__CPM_FULL_UNID} PARENT_SCOPE)
  set(CPM_KV_LIST_UNID_MAP ${CPM_KV_LIST_UNID_MAP} ${name} PARENT_SCOPE)

  # Add source directory. This is only used for looking up source directories
  # given the user's name for the module.
  set(CPM_KV_SOURCEDIR_MAP_${name} ${__CPM_MODULE_SOURCE_DIR} PARENT_SCOPE)
  set(CPM_KV_LIST_SOURCEDIR_MAP ${CPM_KV_LIST_SOURCEDIR_MAP} ${name} PARENT_SCOPE)

  # We are either using the git clone or we are using a user supplied source
  # directory. We are ready to set our target variables and proceed with
  # the add subdirectory.

  # Set variables CPM will use inside of the library target.
  if (DEFINED CPM_UNIQUE_ID)
    set(CPM_SAVED_PARENT_UNIQUE_ID ${CPM_UNIQUE_ID})
  endif()
  set(CPM_UNIQUE_ID ${__CPM_FULL_UNID})
  set(CPM_TARGET_NAME "${__CPM_FULL_UNID}")
  set(CPM_DIR ${CPM_DIR_OF_CPM})

  # Set target output directories.
  _cpm_set_target_output_dirs(_ep_output_bin_dirs "${__CPM_MODULE_BIN_DIR}")

  if ((DEFINED CPM_SHOW_HIERARCHY) AND (CPM_SHOW_HIERARCHY))
    set(_cpm_is_module_resued_var)
    if (DEFINED CPM_KV_SOURCE_ADDED_MAP_${__CPM_FULL_UNID})
      set(_cpm_is_module_resued_var " (reused)")
    endif()
    if(__CPM_USING_GIT)
      _cpm_print_with_hierarchy_level("${name}${_cpm_is_module_resued_var} - GIT - Tag: ${__CPM_NEW_GIT_TAG} - Unid: ${__CPM_FULL_UNID}")
    else()
      _cpm_print_with_hierarchy_level("${name}${_cpm_is_module_resued_var} - Source - Unid: ${__CPM_FULL_UNID}")
    endif()
  endif()

  # Save variables that get overwritten by subdirectory.
  set(CPM_PARENT_ADDITIONAL_DEFINITIONS ${CPM_ADDITIONAL_DEFINITIONS})

  # Add the project's source code.
  if (NOT DEFINED CPM_KV_SOURCE_ADDED_MAP_${__CPM_FULL_UNID})
    # A curiosity when using emscripten on unix: we want shared libraries, not 
    # static libraries. Otherwise em++ will complain about an empty library.
    # Use EMCC_DEBUG=1 to debug emcc or em++ errors.
    if (UNIX)
      if (EMSCRIPTEN)
        set(BUILD_SHARED_LIBS ON)
      else()
        set(BUILD_SHARED_LIBS OFF)
      endif()
    else()
      set(BUILD_SHARED_LIBS OFF)
    endif()

    # The following call to add_subdirectory will propogate CPM_EXPORTED_MODULES
    # up to us. We don't want to clear our parent's variable. So we save it
    # and reset it later on.
    set(CPM_SAVE_EXPORTED_MODULES ${CPM_EXPORTED_MODULES})
    set(CPM_EXPORTED_MODULES)

    # Clear out the arguments so the child instances of CPM don't pick them up.
    # !!!!! NOTE !!!!!  If you want access to the _CPM arguments after this point,
    #                   you must reparse them using _cpm_parse_arguments
    _cpm_clear_arguments(CPM_AddModule _CPM_ "${ARGN}")

    # Clear out other variables we set in the function that may interfer
    # with further calls to CPM.
    set(__CPM_BASE_MODULE_DIR)
    set(CPM_FORCE_ONLY_ONE_MODULE_VERSION)
    set(__CPM_NEW_GIT_TAG)

    # Add the module's code.
    add_subdirectory("${__CPM_MODULE_SOURCE_DIR}" "${__CPM_MODULE_BIN_DIR}")

    _cpm_generate_map_names()

    # Add any includes the module wants to expose in the parent's scope.
    if(DEFINED CPM_ADDITIONAL_INCLUDE_DIRS)
      set(CPM_INCLUDE_DIRS ${CPM_INCLUDE_DIRS} ${CPM_ADDITIONAL_INCLUDE_DIRS})
    endif()

    # Add any definitions the module wants to expose in the parent's scope.
    if(DEFINED CPM_ADDITIONAL_DEFINITIONS)
      set(CPM_DEFINITIONS ${CPM_DEFINITIONS} ${CPM_ADDITIONAL_DEFINITIONS})
    endif()

    if(DEFINED CPM_ADDITIONAL_TARGET_LIBS)
      set(CPM_LIBRARIES ${CPM_LIBRARIES} ${CPM_ADDITIONAL_TARGET_LIBS})
      set(CPM_LIBRARIES ${CPM_LIBRARIES} PARENT_SCOPE)
      set(CPM_DEPENDENCIES ${CPM_DEPENDENCIES} ${CPM_ADDITIONAL_TARGET_LIBS})
      set(CPM_DEPENDENCIES ${CPM_DEPENDENCIES} PARENT_SCOPE)
    endif()

    # Add these additional include directories and definitions to our maps...
    set(${INCLUDE_MAP_NAME} ${CPM_ADDITIONAL_INCLUDE_DIRS})
    set(${DEFINITION_MAP_NAME} ${CPM_ADDITIONAL_DEFINITIONS})
    set(${TARGET_LIB_MAP_NAME} ${CPM_ADDITIONAL_TARGET_LIBS})

    # Parse the arguments once again after adding the subdirectory (since we
    # cleared them all).
    _cpm_parse_arguments(CPM_AddModule _CPM_ "${ARGN}")
    _cpm_obtain_version_from_params(__CPM_NEW_GIT_TAG)

    # Enforce one module version if the module has requested it.
    if (DEFINED CPM_FORCE_ONLY_ONE_MODULE_VERSION)
      if(CPM_FORCE_ONLY_ONE_MODULE_VERSION)
        # Check version of __CPM_PATH_UNID in our pre-existing map key/value map.
        if (DEFINED CPM_KV_MOD_VERSION_MAP_${__CPM_PATH_UNID})
          if (NOT "${CPM_KV_MOD_VERSION_MAP_${__CPM_PATH_UNID}}" STREQUAL "${__CPM_NEW_GIT_TAG}")
            message(FATAL_ERROR "Module '${name}' was declared as only allowing one version of its module. Another version of the module was found: ${CPM_KV_MOD_VERSION_MAP_${__CPM_PATH_UNID}}.")
          endif()
        endif()
      endif()
    endif()
    set(CPM_FORCE_ONLY_ONE_MODULE_VERSION)

    # Add the module version to the map.
    if (NOT DEFINED CPM_KV_MOD_VERSION_MAP_${__CPM_PATH_UNID})
      # Add this entry to the map list.
      set(CPM_KV_LIST_MOD_VERSION_MAP ${CPM_KV_LIST_MOD_VERSION_MAP} ${__CPM_PATH_UNID})
    endif()
    set(CPM_KV_MOD_VERSION_MAP_${__CPM_PATH_UNID} ${__CPM_NEW_GIT_TAG})

    # Setup module interface definition. This is the name the module is using
    # to identify itself in it's headers.
    if (DEFINED CPM_LAST_MODULE_NAME)
      _cpm_check_and_add_preproc(${CPM_LAST_MODULE_NAME} ${__CPM_FULL_UNID})
    else()
      message(FATAL_ERROR "A module (${name}) failed to define its name!")
    endif()

    # Ensure we log that we have added this source directory.
    # Otherwise CMake will error out and tell us we can't use the same binary
    # directory for two source directories. We always start in the parent scope.
    set(CPM_KV_SOURCE_ADDED_MAP_${__CPM_FULL_UNID} ${CPM_LAST_MODULE_NAME})
    set(CPM_KV_LIST_SOURCE_ADDED_MAP ${CPM_KV_LIST_SOURCE_ADDED_MAP} ${__CPM_FULL_UNID})

    set(CPM_INCLUDE_DIRS ${CPM_INCLUDE_DIRS} "${__CPM_MODULE_SOURCE_DIR}")

    # Add ${__CPM_MODULE_SOURCE_DIR} to our include directory map.
    set(${INCLUDE_MAP_NAME} ${${INCLUDE_MAP_NAME}} "${__CPM_MODULE_SOURCE_DIR}")

    # Our exports should have been added to the appropriate map in our scope.
    # So we ignore CPM_EXPORTED_MODULES (which should not be placed in our
    # scope by the modules).
    _cpm_handle_exports_for_module(${__CPM_FULL_UNID})

    # Reset the exported modules to its value before we made the add_subdirectory call.
    set(CPM_EXPORTED_MODULES ${CPM_SAVE_EXPORTED_MODULES})

    # Make sure there are entries for us in the include and definition lists.
    set(CPM_KV_LIST_INCLUDE_MAP ${CPM_KV_LIST_INCLUDE_MAP} ${__CPM_FULL_UNID})
    set(CPM_KV_LIST_DEFINITION_MAP ${CPM_KV_LIST_DEFINITION_MAP} ${__CPM_FULL_UNID})
    set(CPM_KV_LIST_LIB_TARGET_MAP ${CPM_KV_LIST_LIB_TARGET_MAP} ${__CPM_FULL_UNID})

  else()
    # Set the name the module is using to setup its namespaces.
    set(CPM_LAST_MODULE_NAME ${CPM_KV_SOURCE_ADDED_MAP_${__CPM_FULL_UNID}})

    _cpm_generate_map_names()

    # Ensure our module's preprocessor definition is present.
    _cpm_check_and_add_preproc(${CPM_LAST_MODULE_NAME} ${__CPM_FULL_UNID})

    # Lookup the module by full unique ID and pull their definitions and additional include directories.
    if (DEFINED ${INCLUDE_MAP_NAME})
      set(CPM_INCLUDE_DIRS ${CPM_INCLUDE_DIRS} ${${INCLUDE_MAP_NAME}})
    endif()

    if (DEFINED ${DEFINITION_MAP_NAME})
      set(CPM_DEFINITIONS ${CPM_DEFINITIONS} ${${DEFINITION_MAP_NAME}})
    endif()

    if(DEFINED ${TARGET_LIB_MAP_NAME})
      set(CPM_LIBRARIES ${CPM_LIBRARIES} ${${TARGET_LIB_MAP_NAME}})
      set(CPM_LIBRARIES ${CPM_LIBRARIES} PARENT_SCOPE)
      set(CPM_DEPENDENCIES ${CPM_DEPENDENCIES} ${${TARGET_LIB_MAP_NAME}})
      set(CPM_DEPENDENCIES ${CPM_DEPENDENCIES} PARENT_SCOPE)
    endif()

    _cpm_handle_exports_for_module(${__CPM_FULL_UNID})

  endif()

  # Build forward declarations.
  if (DEFINED CPM_SAVED_PARENT_UNIQUE_ID)
    if (((DEFINED _CPM_FORWARD_DECLARATION) AND (_CPM_FORWARD_DECLARATION)) OR
        ((DEFINED _CPM_EXPORT_MODULE) AND (_CPM_EXPORT_MODULE)))
      # Populate our parent's forward decl map with the name they have
      # chosen for us. Remember, this is a map of pairs.
      set(map_name CPM_KV_FORWARD_DECL_MAP_${CPM_SAVED_PARENT_UNIQUE_ID})
      set(${map_name} ${${map_name}} ${__CPM_FULL_UNID})
      set(${map_name} ${${map_name}} ${name})
    endif()
  endif()

  # Apply forward declarations for the module.
  _cpm_apply_forward_declarations(${__CPM_FULL_UNID})

  # If we are exporting this module, be sure the parent knows.
  if ((DEFINED _CPM_EXPORT_MODULE) AND (_CPM_EXPORT_MODULE))
    set(CPM_EXPORTED_MODULES ${CPM_EXPORTED_MODULES} ${__CPM_FULL_UNID} PARENT_SCOPE)
    set(CPM_EXPORTED_MODULES ${CPM_EXPORTED_MODULES} ${__CPM_FULL_UNID})
  endif()

  # Append target to pre-existing libraries.
  if (TARGET ${CPM_TARGET_NAME})
    get_target_property(TARGET_TYPE ${CPM_TARGET_NAME} TYPE)
    if (("${TARGET_TYPE}" STREQUAL "STATIC_LIBRARY")
      OR ("${TARGET_TYPE}" STREQUAL "MODULE_LIBRARY")
      OR ("${TARGET_TYPE}" STREQUAL "SHARED_LIBRARY"))
      set(CPM_LIBRARIES ${CPM_LIBRARIES} "${CPM_TARGET_NAME}" PARENT_SCOPE)
    endif()
    set(CPM_DEPENDENCIES ${CPM_DEPENDENCIES} "${CPM_TARGET_NAME}" PARENT_SCOPE)
  else()
    add_custom_target(${CPM_TARGET_NAME})
    set(CPM_DEPENDENCIES ${CPM_DEPENDENCIES} ${CPM_TARGET_NAME} PARENT_SCOPE)
  endif()

  # Set the appropriate preprocessor definition for how *we* named the module.
  # This is different than the preprocessor definition that the module itself
  # used in its name. But only do this if our name differs from what the
  # module named itself.
  if (NOT ${name} STREQUAL ${CPM_LAST_MODULE_NAME})
    _cpm_check_and_add_preproc(${name} ${__CPM_FULL_UNID})
  endif()

  # TODO: Remove the following line when we upgrade SCIRun.
  set(CPM_INCLUDE_DIRS ${CPM_INCLUDE_DIRS} "${__CPM_MODULE_SOURCE_DIR}/3rdParty")
  set(CPM_DEFINITIONS ${CPM_DEFINITIONS} PARENT_SCOPE)
  set(CPM_INCLUDE_DIRS ${CPM_INCLUDE_DIRS} PARENT_SCOPE)

  # Now propogate the version map upwards (we don't really *need* to do this).
  # But makes it clear what we are trying to do.
  _cpm_propogate_version_map_up()
  _cpm_propogate_source_added_map_up()

  # Export the rest of the maps for exported modules and the like.
  _cpm_propogate_include_map_up()
  _cpm_propogate_definition_map_up()
  _cpm_propogate_target_lib_map_up()
  _cpm_propogate_export_map_up()
  _cpm_propogate_forward_decl_map_up()

  if (COMMAND CPM_PostModuleExecCallback)
    CPM_PostModuleExecCallback()
  endif()

  _cpm_debug_log("Ending module: ${name}")

endfunction()

