# CPM's support for GIT.

macro(_cpm_clone_git_repo repo dir tag)
  # Simply clones the git repository at ${repo} into ${dir}
  # No other checks are performed.
  message(STATUS "Cloning git repo (${repo} @ ${tag})")

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
    message("Git error for directory '${dir}'")
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

endmacro()


macro(_cpm_update_git_repo dir tag offline)
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
    OUTPUT_QUIET
    ERROR_QUIET
    )

  # Is the hash checkout out that we want?
  if(error_code OR is_remote_ref OR NOT ("${tag_sha}" STREQUAL "${head_sha}"))
    # Fetch the remote repository and limit it to 15 seconds.
    if (NOT ${offline})
      execute_process(
        COMMAND "${GIT_EXECUTABLE}" fetch
        WORKING_DIRECTORY "${dir}"
        RESULT_VARIABLE error_code
        TIMEOUT 15
        OUTPUT_QUIET
        ERROR_QUIET
        )
      if(error_code)
        message(STATUS "Failed to fetch repository '${repo}'. Skipping fetch.")
      endif()
    endif()

    execute_process(
      COMMAND "${GIT_EXECUTABLE}" checkout ${tag}
      WORKING_DIRECTORY "${dir}"
      RESULT_VARIABLE error_code
      OUTPUT_QUIET
      ERROR_QUIET
      )
    if(error_code)
      message("Git error for directory '${dir}'")
      message(FATAL_ERROR "Failed to checkout tag: '${tag}'")
    endif()

    if (NOT ${offline})
      execute_process(
        COMMAND "${GIT_EXECUTABLE}" submodule update --recursive
        WORKING_DIRECTORY "${dir}"
        RESULT_VARIABLE error_code
        )
      if(error_code)
        message("Failed to update submodules in: '${dir}'. Skipping submodule update.")
      endif()
    endif()

  endif()
endmacro()

macro(_cpm_ensure_git_repo_is_current use_caching)
  # Tag with a sane default if not present.
  if (DEFINED _CPM_REPO_GIT_TAG)
    set(tag ${_CPM_REPO_GIT_TAG})
  else()
    set(tag "origin/master")
  endif()

  set(repo ${_CPM_REPO_GIT_REPOSITORY})
  set(dir ${_CPM_REPO_TARGET_DIR})

  _cpm_ensure_scm_repo_is_current(${use_caching} ${tag} ${repo} ${dir})
endmacro()
