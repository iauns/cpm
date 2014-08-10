macro(_cpm_clone_svn_repo repo dir revision trustCert svn_user_pw_args)
  if (NOT ${trustCert} STREQUAL " ")
    set(validTrustCert ${trustCert})
  endif()
  if (NOT ${svn_user_pw_args} STREQUAL " ")
    set(valid_svn_user_pw_args ${svn_user_pw_args})
  endif()
  message(STATUS "SVN checking out repo (${repo} @ revision ${revision})")
  set(cmd ${Subversion_SVN_EXECUTABLE} co ${repo} -r ${revision}
    --non-interactive ${validTrustCert} ${valid_svn_user_pw_args} ${dir})
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
endmacro()

macro(_cpm_update_svn_repo dir revision trustCert svn_user_pw_args)
  if (NOT ${trustCert} STREQUAL " ")
    set(validTrustCert ${trustCert})
  endif()
  if (NOT ${svn_user_pw_args} STREQUAL " ")
    set(valid_svn_user_pw_args ${svn_user_pw_args})
  endif()
  set(cmd ${Subversion_SVN_EXECUTABLE} up -r ${revision}
    --non-interactive ${validTrustCert} ${valid_svn_user_pw_args})
  execute_process(
    COMMAND ${cmd}
    RESULT_VARIABLE result
    WORKING_DIRECTORY "${dir}"
    OUTPUT_QUIET
    ERROR_QUIET)
  if (result)
    set(msg "Command failed: ${result}. ")
    set(msg "${msg} '${cmd}'")
    set(msg "Skipping SVN update. ${msg}.")
    message(STATUS "${msg}")
  endif()
endmacro()

macro(_cpm_ensure_svn_repo_is_current use_caching)
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
  else()
    set(trustCert " ")
  endif()

  set(svn_user_pw_args " ")
  if((DEFINED _CPM_REPO_SVN_USERNAME) AND (_CPM_REPO_SVN_USERNAME))
    set(svn_user_pw_args ${svn_user_pw_args} "--username=${_CPM_REPO_SVN_USERNAME}")
  endif()
  if((DEFINED _CPM_REPO_SVN_PASSWORD) AND (_CPM_REPO_SVN_PASSWORD))
    set(svn_user_pw_args ${svn_user_pw_args} "--password=${_CPM_REPO_SVN_PASSWORD}")
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

        # Update cached version of repo.
        if (NOT DEFINED CPM_MODULE_CACHE_NO_WRITE)
          _cpm_update_svn_repo(${__CPM_ENSURE_CACHE_DIR} ${revision} ${trustCert} ${svn_user_pw_args})
        endif()

        # We are positive the directory exists, although it may not be
        # updated. Copy it.
        file(COPY "${__CPM_ENSURE_CACHE_DIR}/" DESTINATION ${dir})

        _cpm_update_svn_repo(${dir} ${revision} ${trustCert} ${svn_user_pw_args})
      else()
        message(STATUS "Creating cached version of ${repo}.")
        # If we can write to the cache directory, then clone it, update it,
        # then copy it to the target directory.
        if (DEFINED CPM_MODULE_CACHE_NO_WRITE)
          # Clone directly into the target directory.
          _cpm_clone_svn_repo(${repo} ${dir} ${revision} ${trustCert} ${svn_user_pw_args})
          _cpm_update_svn_repo(${dir} ${revision} ${trustCert} ${svn_user_pw_args})
        else()
          _cpm_clone_svn_repo(${repo} ${__CPM_ENSURE_CACHE_DIR} ${revision} ${trustCert} ${svn_user_pw_args})
          _cpm_update_svn_repo(${__CPM_ENSURE_CACHE_DIR} ${revision} ${trustCert} ${svn_user_pw_args})
          file(COPY "${__CPM_ENSURE_CACHE_DIR}/" DESTINATION ${dir})
          _cpm_update_svn_repo(${dir} ${revision} ${trustCert} ${svn_user_pw_args})
        endif()
      endif()

    else()
      # No cache directory is present, simply clone into target directory
      # and update it.
      _cpm_clone_svn_repo(${repo} ${dir} ${revision} ${trustCert} ${svn_user_pw_args})
      _cpm_update_svn_repo(${dir} ${revision} ${trustCert} ${svn_user_pw_args})
    endif()

  else()

    _cpm_update_svn_repo(${dir} ${revision} ${trustCert} ${svn_user_pw_args})

  endif()

endmacro()

