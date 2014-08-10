macro(_cpm_clone_git_repo repo dir tag)

  # Simply clones the git repository at ${repo} into ${dir}
  # No other checks are performed.
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


macro(_cpm_update_git_repo dir tag)
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

    execute_process(
      COMMAND "${GIT_EXECUTABLE}" submodule update --recursive
      WORKING_DIRECTORY "${dir}"
      RESULT_VARIABLE error_code
      )
    if(error_code)
      message("Failed to update submodules in: '${dir}'. Skipping submodule update.")
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

  if (NOT EXISTS "${dir}/")

    # If there exists a cache repository, check the cache directory before
    # cloning a new instance of the repository. This results in the following
    # two scenarios:
    #
    # 1) If we determine that there is cached instance of the repo then update
    #    the cached repo and copy the cache directory to our current directory.
    #
    # 2) If we do not find a cached repository, clone it into the cache
    #    directory, then follow steps in #1.
    #

    # All modules will be cached in the cache directory.
    if ((DEFINED CPM_MODULE_CACHE_DIR) AND (${use_caching}))

      if (NOT EXISTS ${CPM_MODULE_CACHE_DIR})
        file(MAKE_DIRECTORY ${CPM_MODULE_CACHE_DIR})
      endif()

      # Generate unique id for repo and check the cache directory.
      set(__CPM_ENSURE_CACHE_UNID ${repo})
      _cpm_make_valid_unid_or_path(__CPM_ENSURE_CACHE_UNID)

      # Use unique id (non-versioned) to lookup the repository in
      # the cache directory.
      set(__CPM_ENSURE_CACHE_DIR "${CPM_MODULE_CACHE_DIR}/${__CPM_ENSURE_CACHE_UNID}")
      if (EXISTS ${__CPM_ENSURE_CACHE_DIR})
        # Update the repository, then copy it. Only update if we can
        # write to the cache directory.
        message(STATUS "Found cached version of ${repo}.")

        # Todo: We really shouldn't update the tag in the cache directory.
        #       Simply fetching the contents would suffice.
        if (NOT DEFINED CPM_MODULE_CACHE_NO_WRITE)
          _cpm_update_git_repo(${__CPM_ENSURE_CACHE_DIR} ${tag})
        endif()

        # We are positive the directory exists, although it may not be
        # updated. Copy it.
        file(COPY "${__CPM_ENSURE_CACHE_DIR}/" DESTINATION ${dir})

        # Update git repo once more when it is in the target directory.
        # We will need this call to set the correct tag if we fix the todo
        # item above.
        _cpm_update_git_repo(${dir} ${tag})
      else()
        message(STATUS "Creating cached version of ${repo}.")
        # If we can write to the cache directory, then clone it, update it,
        # then copy it to the target directory.
        if (DEFINED CPM_MODULE_CACHE_NO_WRITE)
          # Clone directly into the target directory.
          _cpm_clone_git_repo(${repo} ${dir} ${tag})
          _cpm_update_git_repo(${dir} ${tag})
        else()
          _cpm_clone_git_repo(${repo} ${__CPM_ENSURE_CACHE_DIR} ${tag})
          _cpm_update_git_repo(${__CPM_ENSURE_CACHE_DIR} ${tag})
          file(COPY "${__CPM_ENSURE_CACHE_DIR}/" DESTINATION ${dir})
          _cpm_update_git_repo(${dir} ${tag}) # Sanity
        endif()
      endif()

    else()
      # No cache directory is present, simply clone into target directory
      # and update it.
      _cpm_clone_git_repo(${repo} ${dir} ${tag})
      _cpm_update_git_repo(${dir} ${tag})
    endif()

  else()
    # Target directory found, attempt to update.
    _cpm_update_git_repo(${dir} ${tag})
  endif()

endmacro()
