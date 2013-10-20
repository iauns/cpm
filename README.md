CPM
===

CMake C/C++ Package Manager.

Using CPM
=========

To use CPM in your C++ project, include the following at the top of your
CMakeLists.txt:

```
#------------------------------------------------------------------------------
# Required CPM Setup - See: http://github.com/iauns/cpm
#------------------------------------------------------------------------------
set (CPM_DIR "${CMAKE_CURRENT_BINARY_DIR}/cpm-packages" CACHE TYPE STRING)
if (${CPM_DIR} MATCHES "${CMAKE_CURRENT_BINARY_DIR}")
  message("NOTE: Placing CPM in the binary directory is not recommended.")
endif ()

find_package(Git)
if(NOT GIT_FOUND)
  message(FATAL_ERROR "CPM requires Git.")
endif()
if (NOT EXISTS ${CPM_DIR}/CPM.cmake)
  execute_process(
    COMMAND "${GIT_EXECUTABLE}" clone https://github.com/iauns/cpm ${CPM_DIR}
    RESULT_VARIABLE error_code
    OUTPUT_VARIABLE head_sha
    )
  if(error_code)
    message(FATAL_ERROR "CPM failed to get the hash for HEAD")
  endif()
endif()

set(CMAKE_MODULE_PATH ${CMAKE_MODULE_PATH} ${CPM_DIR})
include(CPM)
```

Then add the `${CPM_LIBRARIES}` variable to your `target_link_libraries`.

That's it. You should be able to start using CPM modules right away by adding
something like:

```
CPM_AddModule("SpireModule"
  GIT_REPOSITORY "https://github.com/SCIInstitute/spire"
  GIT_TAG "v0.7.0")
```

This will automatically download, build, and link version 0.7.0 of a thin
OpenGL client named Spire.

Advantages of Using CPM
=======================

* Automatically manages code retrieval and the build.
* You can use multiple different versions of the same statically linked module
  in the same build without shared libraries.
* All module code will be included in any generated project solution.
* Encourages small, well-tested and composable code modules. Similar to NPM.

Disadvantages of Using CPM
==========================

* Only supports Git.

Building CPM Modules
====================

When building CPM modules, there are some basic guidelines that you should
follow.

Include Directories
-------------------

All of your module's public interface headers should be in the 'include'
subdirectory.

Wrapping Namespace
------------------

CPM allows multiple different versions of the same module to be used in the
same static linkage unit. As such, when you are building a module for CPM (not
when you are using CPM modules!), you should surround your top-level namespace
directive in CPM_NAMESPACE tags like so:

```
CPM_NAMESPACE
namespace Spire {

} // namespace Spire
CPM_NAMESPACE
```

This is *not* required, but it is *heavily* recommended when you are building
CPM modules. If you want your users to be able to use multiple versions of
your module within the same static linkage unit, you must include this.

Why would you want to let users utilize multiple versions of your module?
Most of the time users don't know that they are actually using multiple
different versions of your module. A more recent version of your module may be
included directly by the user then an older version of your module may be
pulled in as a dependency of another module the user is relying on.

Common Issues
=============

Below are some common issues users encounter and solutions to them.

Ensuring matching module versions
---------------------------------

Some module interfaces require the ability to expose classes from other
included modules. This is allowed. By doing this, you tie your module and its
users to a particular version of the exposed module. To do this, in your
module interface files, make sure you don't include your automatically
generated 'cpm.h' headers (you shouldn't do this anyways). You should
reference CPM's automatically generated unique ID namespace name 

An example may help illustrate this better:

Sally codes CPM module `A` in which she wants to expose a class from Bob's CPM
module `B`. Sally currently has version 0.11 of Bob's module `B`. A new
programmer, James, wants to use Sally's module `A` module.

Ensuring a module is only included once in a static linkage unit
----------------------------------------------------------------

This issues arises, for example, if you are using something like the OpenGL
extension wrangler. The extension wrangler depends on OpenGL context specific
funciton binding. So calling 'wrangled' functions from multiple static
libraries will cause undue amounts of chaos. Most users won't need to worry
about this corner case. This is a particular affectation of OpenGL's context
handling and Extension Wrangler's binding of function pointers.

FAQ
===

Why add_subdirectory instead of External Projects?
--------------------------------------------------

CPM was initially built using external projects, but the external project
mechanism proved to be too restrictive. When using external projects, a
cmake+build+cmake cycle was required to detect all static dependencies. One of
CPM's tenets is to never require a departure from the standard cmake + build,
so we couldn't use external projects as-is.

Another advantage of `add_subdirectory` is that it include's the module's
source code as part of any project solution that is generated from CMake. See
the `CPM Advantages` section.

