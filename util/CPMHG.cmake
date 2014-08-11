# CPM's support for HG.

macro(_cpm_clone_hg_repo repo dir tag)
  # Simply clones the hg repository at ${repo} into ${dir}
  # No other checks are performed.
  message(STATUS "Cloning hg repo (${repo} @ ${tag})")

  # Much of this clone code is taken from external project's generation
  # of its *gitclone.cmake files. (and copied again for hg)
  # Try the clone 3 times (from External Project source).
  # We don't set a timeout here because we absolutely need to clone the
  # directory in order to continue with the build process.
  set(error_code 1)
  set(number_of_tries 0)
  while(error_code AND number_of_tries LESS 3)
    execute_process(
      COMMAND "${HG_EXECUTABLE}" clone "${repo}" "${dir}"
      WORKING_DIRECTORY "${CPM_DIR_OF_CPM}"
      RESULT_VARIABLE error_code
      OUTPUT_QUIET
      ERROR_QUIET
      )
    math(EXPR number_of_tries "${number_of_tries} + 1")
  endwhile()

  # Check to see if we really have cloned the repository.
  if(number_of_tries GREATER 1)
    message(STATUS "Had to hg clone more than once: ${number_of_tries} times.")
  endif()
  if(error_code)
    message("Hg error for directory '${dir}'")
    message(FATAL_ERROR "Failed to clone repository: '${repo}'")
  endif()

  # Checkout the appropriate tag.
  execute_process(
    COMMAND "${HG_EXECUTABLE}" checkout ${tag}
    WORKING_DIRECTORY "${dir}"
    RESULT_VARIABLE error_code
    OUTPUT_QUIET
    ERROR_QUIET
    )
  if(error_code)
    message(FATAL_ERROR "Failed to checkout tag: '${tag}'")
  endif()

 # subrepositories in hg are not supported right now

endmacro()

macro(_cpm_update_hg_repo dir tag offline)
  message(STATUS "updating hg repository (${dir} @ ${tag})")
  if (NOT ${offline})
    execute_process(
      COMMAND "${HG_EXECUTABLE}" update
      WORKING_DIRECTORY "${dir}"
      RESULT_VARIABLE error_code)

    if(error_code)
      message("could not update hg repo in : '${dir}'")
    endif()
  endif()

  execute_process(
    COMMAND "${HG_EXECUTABLE}" checkout "${tag}"
    WORKING_DIRECTORY "${dir}"
    RESULT_VARIABLE error_code
    )

  if(error_code)
    message(FATAL_ERROR "could not checkout sepcified tag: '${tag}'" )
  endif()
endmacro()

macro(_cpm_ensure_hg_repo_is_current use_caching)
  # Tag with a sane default if not present.
  if (DEFINED _CPM_REPO_HG_TAG)
    set(tag ${_CPM_REPO_HG_TAG})
  else()
    set(tag "tip")
  endif()

  set(repo ${_CPM_REPO_HG_REPOSITORY})
  set(dir ${_CPM_REPO_TARGET_DIR})

  # Attempt to find the mercurial package
  find_package(Hg)
  if(NOT HG_FOUND)
    message(FATAL_ERROR "CPM could not find Mercurial(Hg). Cannot ensure ${repo} is current.")
  endif()

  _cpm_ensure_scm_repo_is_current(${use_caching} ${tag} ${repo} ${dir})
endmacro()

