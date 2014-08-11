# CPM's support for SVN.

# NOTE: _svn_cpm_trustCert and _svn_cpm_user_pw_args are special variables
#       that are set in _cpm_ensure_svn_repo_is_current. They are passed
#       through all macro calls into the clone and update functions.
macro(_cpm_clone_svn_repo repo dir revision)
  if (NOT ${_svn_cpm_trustCert} STREQUAL " ")
    set(validTrustCert ${_svn_cpm_trustCert})
  endif()
  if (NOT ${_svn_cpm_user_pw_args} STREQUAL " ")
    set(valid_svn_user_pw_args ${_svn_cpm_user_pw_args})
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

macro(_cpm_update_svn_repo dir revision offline)
  if (NOT offline)
    if (NOT ${_svn_cpm_trustCert} STREQUAL " ")
      set(validTrustCert ${_svn_cpm_trustCert})
    endif()
    if (NOT ${_svn_cpm_user_pw_args} STREQUAL " ")
      set(valid_svn_user_pw_args ${_svn_cpm_user_pw_args})
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
  else()
    message(STATUS "SVN: CPM_OFFLINE set. Ignoring SVN update to revision.")
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
    set(_svn_cpm_trustCert "--trust-server-cert")
  else()
    set(_svn_cpm_trustCert " ")
  endif()

  set(_svn_cpm_user_pw_args " ")
  if((DEFINED _CPM_REPO_SVN_USERNAME) AND (_CPM_REPO_SVN_USERNAME))
    set(_svn_cpm_user_pw_args ${_svn_cpm_user_pw_args} "--username=${_CPM_REPO_SVN_USERNAME}")
  endif()
  if((DEFINED _CPM_REPO_SVN_PASSWORD) AND (_CPM_REPO_SVN_PASSWORD))
    set(_svn_cpm_user_pw_args ${_svn_cpm_user_pw_args} "--password=${_CPM_REPO_SVN_PASSWORD}")
  endif()

  _cpm_ensure_scm_repo_is_current(${use_caching} ${tag} ${repo} ${dir})
endmacro()

