# Contains abstractions that operate across all of CPM's supported source
# control management systems.

macro(_cpm_scm_update dir tag offline)
  if (DEFINED _CPM_REPO_GIT_REPOSITORY)
    _cpm_update_git_repo(${dir} ${tag} ${offline})
  elseif(DEFINED _CPM_REPO_SVN_REPOSITORY)
    _cpm_update_svn_repo(${dir} ${tag} ${offline})
  elseif(DEFINED _CPM_REPO_HG_REPOSITORY)
    _cpm_update_hg_repo(${dir} ${tag} ${offline})
  else()
    message(FATAL_ERROR "_cpm_scm_update: Invalid SCM type.")
  endif()
endmacro()

macro(_cpm_scm_clone repo dir tag)
  if (DEFINED _CPM_REPO_GIT_REPOSITORY)
    _cpm_clone_git_repo(${repo} ${dir} ${tag})
  elseif(DEFINED _CPM_REPO_SVN_REPOSITORY)
    _cpm_clone_svn_repo(${repo} ${dir} ${tag})
  elseif(DEFINED _CPM_REPO_HG_REPOSITORY)
    _cpm_clone_hg_repo(${repo} ${dir} ${tag})
  else()
    message(FATAL_ERROR "_cpm_scm_clone: Invalid SCM type.")
  endif()
endmacro()

macro(_cpm_ensure_scm_repo_is_current use_caching tag repo dir)

  # Ensure we don't perform updates in any SCM if we are in 'offline' mode.
  set(_cpm_scm_is_offline TRUE)
  if (NOT ((DEFINED CPM_OFFLINE) AND (CPM_OFFLINE)))
    set(_cpm_scm_is_offline FALSE)
  endif()

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
          _cpm_scm_update(${__CPM_ENSURE_CACHE_DIR} ${tag} ${_cpm_scm_is_offline})
        endif()

        # We are positive the directory exists, although it may not be
        # updated. Copy it.
        file(COPY "${__CPM_ENSURE_CACHE_DIR}/" DESTINATION ${dir})

        # Update repo once more when it is in the target directory.
        # We will need this call to set the correct tag if we fix the todo
        # item above.
        _cpm_scm_update(${dir} ${tag} ${_cpm_scm_is_offline})
      else()
        if (NOT _cpm_scm_is_offline)
          message(STATUS "Creating cached version of ${repo}.")
          # If we can write to the cache directory, then clone it, update it,
          # then copy it to the target directory.
          if (DEFINED CPM_MODULE_CACHE_NO_WRITE)
            # Clone directly into the target directory.
            _cpm_scm_clone(${repo} ${dir} ${tag})
            _cpm_scm_update(${dir} ${tag} FALSE)
          else()
            _cpm_scm_clone(${repo} ${__CPM_ENSURE_CACHE_DIR} ${tag})
            _cpm_scm_update(${__CPM_ENSURE_CACHE_DIR} ${tag} FALSE)
            file(COPY "${__CPM_ENSURE_CACHE_DIR}/" DESTINATION ${dir})
            _cpm_scm_update(${dir} ${tag} FALSE) # Sanity
          endif()
        else()
          message(FATAL_ERROR "Unable to download or create cached version of ${repo} because CPM_OFFLINE is set.")
        endif()
      endif()

    else()
      if (NOT _cpm_scm_is_offline)
        # No cache directory is present, simply clone into target directory
        # and update it.
        _cpm_scm_clone(${repo} ${dir} ${tag})
        _cpm_scm_update(${dir} ${tag} FALSE)
      else()
        message(FATAL_ERROR "Unable to download ${repo} because CPM_OFFLINE is set.")
      endif()
    endif()

  else()
    # Target directory found, attempt to update.
    _cpm_scm_update(${dir} ${tag} ${_cpm_scm_is_offline})
  endif()
  
endmacro()
