===
CPM
===

CMake C++ Package Manager.

+---------------+--------------------------------------------------------------+
|  **Warning**  |  CPM is alpha software. The module code is complete but CPM  |
|               |  externals are missing. Feel free to evaluate CPM but please |
|               |  wait until CPM leaves alpha before using it in projects.    |
+---------------+--------------------------------------------------------------+

Using CPM
=========

To use CPM in your C++ project, include the following at the top of your
CMakeLists.txt::

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
  include(${CPM_DIR}/CPM.cmake)
  
  # Include any modules and externals here...
  
  # Finalize CPM.
  CPM_Finish()

Then add the ``${CPM_LIBRARIES}`` variable to your `target_link_libraries`.
That's it. You will be able to start using CPM modules right away by adding
something like::

  CPM_AddModule("spire"
    GIT_REPOSITORY "https://github.com/SCIInstitute/spire"
    GIT_TAG "v0.7.0")

to the "# Include any modules here..." section mentioned in the first snippet.
This will automatically download, build, and link version 0.7.0 of a thin
OpenGL client named Spire. A new namespace is generated for 'spire' and a
preprocessor definition for this namespace is automatically added to your
project. This definition always follows the form "`CPM_<NAME>_NS`" where
`<NAME>` is the first argument of your call to `CPM_AddModule`. The name is
always capitalized before being added to your preprocessor definitions.

So, in the 'spire' example above we would have a new preprocessor definition
`CPM_SPIRE_NS` added to our project. This declares the namepsace under which
we have bound Spire and you can access spire through this namespace:
`CPM_SPIRE_NS::Interface`. In general you will want to rename the namespace
to something more appropriate: `namespace Spire = CPM_SPIRE_NS`.

Using this approach, we can *statically* link against multiple different
versions of the spire library and control a number of settings regarding how
these libraries are linked into your program.  Linking against different
versions of a library becomes very useful if multiple modules depend on
different versions of the same library.

CPM Externals
-------------

If the library you are interested in isn't a CPM module, try using CPM
externals. While you won't be able to link against multiple versions of the
library, you can quickly include the library if there is a CPM formula for it
in the CPM externals repository. If the library is hosted in a public
location, use the URL of the library in CMake:

``
CPM_AddExternal('http://my.repo.com')
``

otherwise you may attempt to reference the library by name directly:

``
CPM_AddExternal('mongdb-c')
``

If you don't find a formula, kindly consider contributing one to our externals
repository. We're always looking to expand these formula to different
libraries.

Advantages of Using CPM
-----------------------

* Automatically manages code retrieval and the build.
* You can use multiple different versions of the same statically linked module
  in the same build without shared libraries.
* All module code will be included in any generated project solution.
* Encourages small, well-tested and composable code modules. Similar to NPM.

Building CPM Modules
====================

When building CPM modules for others to use, there are some basic guidelines
that you should follow. 

The rest of the guidelines follow below.

CMakeLists.txt Entry
--------------------

There must be a CMakeLists.txt at the root of your module project and this
CMakeLists.txt file must contain all relevant CPM directives and code (see
below). Do not use `add_subdirectory` to change to another directory and issue
CPM_ calls.

Add the following to the top of your CMakeLists.txt file for your module. It
is only slightly larger than what is required if you were using CPM as an end
user:

``
``

Alternatively, if you are not using CPM dependencies in your module, you can
include this minimal CMakeLists.txt entry:

``

``

A file with the following in it is also required:

``

``

Include this file everywhere you use the CPM namespace.

Library target name
-------------------

Ensure that your generated library target name is ``. This will match up with
what CPM is expecting and allow your module to function properly with other
users' code.

Includes & Include Directories
------------------------------

All of your module's public interface headers should be in the 'include'
subdirectory. Additionally, you should include cpm/cpm.h. This header will
include your unique namespace definitions and any additional using directives
for CPM modules that you are using.

Wrapping Namespace
------------------

CPM allows multiple different versions of the same module to be used in the
same static linkage unit. As such, when you are building a module for CPM (not
when you are using CPM modules!), you should surround your top-level namespace
directive in CPM_NAMESPACE tags like so::

  CPM_NAMESPACE
  namespace Spire {
  
  } // namespace Spire
  CPM_NAMESPACE

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

Matching module versions
------------------------

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

Force only one module version
-----------------------------

This issues arises, for example, if you are using something like the OpenGL
extension wrangler. The extension wrangler depends on OpenGL context specific
funciton binding. So calling 'wrangled' functions from multiple static
libraries will cause undue amounts of chaos. Most users won't need to worry
about this corner case. This is a particular affectation of OpenGL's context
handling and Extension Wrangler's binding of function pointers.

To enforce this during the CMake configure step, include a call to
`CPM_ForceOnlyOneModuleVersion` anywhere in your module's CMakeLists.txt file.
Usually this call is made directly after calling `CPM_InitModule`.

Building CPM Externals
======================


FAQ
===

Why add_subdirectory instead of ExternalProject?
------------------------------------------------

CPM was initially built using external projects but the external project
mechanism proved to be too restrictive. When using external projects, a
cmake+build+cmake+build cycle was required to detect all static dependencies.
One of CPM's tenets is to never require a departure from the standard cmake +
build sequence, so we couldn't use external projects as-is.

After working on CPM it became clear that `add_subdirectory` was the right
choice. `add_subdirectory` allows us to easily enforce configuration
constraints, such as only allowing one version of a library to be statically
linked, without needing to read/write to files and use the akward double
configure and build cycle.

Another advantage of `add_subdirectory` is that it include's the module's
source code as part of any project solution that is generated from CMake. See
the `CPM Advantages` section.

How do I see the module hierarchy?
----------------------------------

When building your project define: `CPM_SHOW_HIERARCHY=TRUE`.

On the command line this would look something like

``cmake -DCPM_SHOW_HIERARCHY=TRUE ...``

