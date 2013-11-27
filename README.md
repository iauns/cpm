CPM
===

[![Build Status](https://travis-ci.org/iauns/cpm.png)](https://travis-ci.org/iauns/cpm)

C++ Package Manager based on CMake.

CPM is designed to save you time and promote small, well-tested, and composable
C++ modules. It allows you to link against multiple different versions of the
same static library so that you can include other C++ modules that may depend
on older or newer versions of the same modules you are using. CPM will also
automatically download and build these C++ modules for you. CPM's goal is to
help support the growth of a "do one thing and do it well" module ecosystem in
C++. To explore the ecosystem head on over to the CPM website:
http://cpmcpp.org (or http://cmakepm.org).

Using CPM, you can also manage C or C++ libraries that do not use CPM. A number
of what we call 'external' modules are already in the
[cpm-modules](https://github.com/iauns/cpm-modules.git) repository.  These
modules abstract away the details of writing a CMake external project for
you. Just be aware that you cannot statically link against multiple different
versions of these external modules because they are not built as CPM modules.
Although the changes necessary to convert a code base to a CPM module are
minor mostly dealing with namespace names.

Below is a simple example of a CMakeLists.txt file that uses 3 different
modules. The modules are a simple OpenGL wrapper library name Spire, MongoDB's
C library, and G-truc's GLSL vector math library. See the next section for a
full explanation of how to use CPM and work with the namespaces it creates.
Example:

```cmake
  cmake_minimum_required(VERSION 2.8.0 FATAL_ERROR)
  project(Viewer)
  
  #------------------------------------------------------------------------------
  # CPM Setup - See: http://github.com/iauns/cpm
  #------------------------------------------------------------------------------
  set(CPM_DIR "${CMAKE_CURRENT_BINARY_DIR}/cpm_packages" CACHE TYPE STRING)
  find_package(Git)
  if(NOT GIT_FOUND)
    message(FATAL_ERROR "CPM requires Git.")
  endif()
  if (NOT EXISTS ${CPM_DIR}/CPM.cmake)
    message(STATUS "Cloning repo (https://github.com/iauns/cpm)")
    execute_process(
      COMMAND "${GIT_EXECUTABLE}" clone https://github.com/iauns/cpm ${CPM_DIR}
      RESULT_VARIABLE error_code
      OUTPUT_QUIET ERROR_QUIET)
    if(error_code)
      message(FATAL_ERROR "CPM failed to get the hash for HEAD")
    endif()
  endif()
  include(${CPM_DIR}/CPM.cmake)

  #------------------------------------------------------------------------------
  # Add CPM Modules
  #------------------------------------------------------------------------------
  
  # ++ MODULE: Spire
  CPM_AddModule("spire"
    GIT_REPOSITORY "https://github.com/SCIInstitute/spire"
    GIT_TAG "v0.7.0")

  # ++ EXTERNAL-MODULE: MongoDB
  CPM_AddModule("mongodb"
    GIT_REPOSITORY "https://github.com/iauns/cpm-mongoc"
    GIT_TAG "origin/master")

  # ++ EXTERNAL-MODULE: GLM
  CPM_AddModule("glm"
    GIT_REPOSITORY "https://github.com/iauns/cpm-glm"
    GIT_TAG "0.9.4.6"
    USE_EXISTING_VER TRUE)
  
  CPM_Finish()
  
  #-----------------------------------------------------------------------
  # Setup source
  #-----------------------------------------------------------------------
  file(GLOB Sources
    "${CMAKE_CURRENT_SOURCE_DIR}/*.cpp"
    "${CMAKE_CURRENT_SOURCE_DIR}/*.hpp"
    )
  
  #-----------------------------------------------------------------------
  # Setup executable
  #-----------------------------------------------------------------------
  set(EXE_NAME myViewer)
  add_executable(${EXE_NAME} ${Sources})
  target_link_libraries(${EXE_NAME} ${CPM_LIBRARIES})

```

Each module's github webpage will tell you what files to `#include` in your
project.

Using CPM
=========

To use CPM in your C++ project include the following at the top of your
CMakeLists.txt:

```cmake
  #------------------------------------------------------------------------------
  # Required CPM Setup - See: http://github.com/iauns/cpm
  #------------------------------------------------------------------------------
  # You may set CPM_DIR to any path you want. Outside of the binary directory,
  # or anywhere on your harddrive. Any project that wants to use the same
  # version of any module can benefit immediately from the built packages.
  # Just be careful of pre-project settings for modules.
  set(CPM_DIR "${CMAKE_CURRENT_BINARY_DIR}/cpm-packages" CACHE TYPE STRING)
  
  find_package(Git)
  if(NOT GIT_FOUND)
    message(FATAL_ERROR "CPM requires Git.")
  endif()
  if (NOT EXISTS ${CPM_DIR}/CPM.cmake)
    message(STATUS "Cloning repo (https://github.com/iauns/cpm)")
    execute_process(
      COMMAND "${GIT_EXECUTABLE}" clone https://github.com/iauns/cpm ${CPM_DIR}
      RESULT_VARIABLE error_code
      OUTPUT_QUIET ERROR_QUIET)
    if(error_code)
      message(FATAL_ERROR "CPM failed to get the hash for HEAD")
    endif()
  endif()
  include(${CPM_DIR}/CPM.cmake)
  
  # Include any modules and externals here...
  
  CPM_Finish()

```

Then add the ``${CPM_LIBRARIES}`` variable to your ``target_link_libraries``.
That's it. You will be able to start using CPM modules right away by adding
something like:

```cmake
  CPM_AddModule("spire"
    GIT_REPOSITORY "https://github.com/SCIInstitute/spire"
    GIT_TAG "v0.7.0")
```

This snippet will automatically download, build, and link version 0.7.0 of a
thin OpenGL client named Spire. A new namespace is generated for 'spire' and a
preprocessor definition for this namespace is automatically added to your
project. The namespace preprocessor definition always follows the form
"``CPM_<NAME>_NS``" where ``<NAME>`` is the first argument of your call to
``CPM_AddModule``. The name is always capitalized before being added to your
preprocessor definitions.

For example, in the 'spire' snippet above, the preprocessor definition
``CPM_SPIRE_NS`` would be added to our project. This declares the namepsace
under which CPM has bound the 'Spire' module. You can access spire's interface
class through this namespace like so: ``CPM_SPIRE_NS::Interface``. You may 
want to rename the namespace to something more appropriate: ``namespace spire
= CPM_SPIRE_NS;``. But that's entirely up to you. Depending on your needs,
using the CPM namespace as-is may be all you need.

Be sure to place all calls to `CPM_AddModule` before the call to
`CPM_Finish`. The ``# Include any modules here...`` section mentioned in the
first snippet indicates where you should place calls to ``CPM_AddModule``.

Includes
--------

Every module's root directory will be added to your include path. It is common
that every module's github page describes what file or files you should
include in your project. The paths to these files will be relative to the
module's root directory. So you can copy the include directive directly from
the module's github page into your code. For example, to access Spire's
functionality we would include its interface header file like so:

```
#include <spire/Interface.h>
```

CPM Externals
-------------

If the library you are interested in isn't a CPM module, try browsing through
the CPM externals listed on http://cpmcpp.com. While you won't be able to
statically link against multiple versions of an external library, you can
quickly include it. Just use `CPM_AddModule` as you would with any other
module.

If you don't find a formula for your favorite library, kindly consider
contributing one to our CPM modules repository.

Advantages
----------

* Automatically manages code retrieval and the building of CPM modules and externals.
* Allows the use of multiple different versions of the same statically linked
  module in the same executable.
* Built entirely in CMake. Nothing else is required.
* Encourages small well-tested and composable code modules.
* All CPM module code will be included in any generated project solution.
* Will automatically detect naming conflicts based on the names you assign 
  modules.

Limitations
-----------

* Only supports git.

Building CPM Modules
====================

If you only want to use pre-existing CPM modules and aren't interested in
building modules yourself, feel free to skip this section. But, if you are
interested in building CPM modules then please read on as some guidelines and
requirements are listed below.

CMakeLists.txt Entry
--------------------

There must be a CMakeLists.txt at the root of your module project and this
CMakeLists.txt file must contain all relevant CPM directives and code (see
below). Do not use issue calls to CPM (``CPM_*``) in a subdirectory
(``add_subdirectory``).

Add the following to the top of the CMakeLists.txt for your module:

```cmake
  #-----------------------------------------------------------------------
  # CPM configuration
  #-----------------------------------------------------------------------
  set(CPM_MODULE_NAME <name>)
  set(CPM_LIB_TARGET_NAME ${CPM_MODULE_NAME})
  
  if ((DEFINED CPM_DIR) AND (DEFINED CPM_UNIQUE_ID) AND (DEFINED CPM_TARGET_NAME))
    set(CPM_LIB_TARGET_NAME ${CPM_TARGET_NAME})
    set(CMAKE_MODULE_PATH ${CMAKE_MODULE_PATH} ${CPM_DIR})
    include(CPM)
  else()
    set(CPM_DIR "${CMAKE_CURRENT_BINARY_DIR}/cpm-packages" CACHE TYPE STRING)
    find_package(Git)
    if(NOT GIT_FOUND)
      message(FATAL_ERROR "CPM requires Git.")
    endif()
    if (NOT EXISTS ${CPM_DIR}/CPM.cmake)
      message(STATUS "Cloning repo (https://github.com/iauns/cpm)")
      execute_process(
        COMMAND "${GIT_EXECUTABLE}" clone https://github.com/iauns/cpm ${CPM_DIR}
        RESULT_VARIABLE error_code
        OUTPUT_QUIET ERROR_QUIET)
      if(error_code)
        message(FATAL_ERROR "CPM failed to get the hash for HEAD")
      endif()
    endif()
    include(${CPM_DIR}/CPM.cmake)
  endif()
  
  # Include CPM modules or externals here (with CPM_AddModule).
  
  CPM_InitModule(${CPM_MODULE_NAME})
```

Be sure to update the ``<name>`` at the beginning of the snippet. ``<name>`` 
is placed in the namespace preprocessor definition for your module. For example,
if ``<name>`` is 'spire' then the preprocessor definition that will be added
to your project will be ``CPM_SPIRE_NS``. Use this definition as a wrapper
around your code and namespaces. Don't worry about users using the same name in
their call to `CPM_AddModule` as the name you choose in your call to
`CPM_InitModule`. CPM will automatically handle this for you. Also use
``CPM_LIB_TARGET_NAME`` as the name of your library in `add_library` and include
``CPM_LIBRARIES`` in `target_link_libraries` for your static library. Example:

```cmake
  # Our CPM module library
  add_library(${CPM_LIB_TARGET_NAME} ${Source})
  target_link_libraries(${CPM_LIB_TARGET_NAME} ${CPM_LIBRARIES})
```

Here is an example class that demonstrates the namespace wrapping:

```cpp
  namespace CPM_SPIRE_NS {

  ... code here ...

  } // namespace CPM_SPIRE_NS
```

Library target name
-------------------

If you used the code snippet above be sure that your generated library target
name is `${CPM_LIB_TARGET_NAME}`. This will ensure your library target name 
matches with what CPM is expecting.

Wrapping Namespace
------------------

CPM allows multiple different versions of the same module to be used in the
same static linkage unit. As such, when you are building a module for CPM (not
when you are using CPM modules!), you should either surround your top-level
namespaces in `CPM_[module name]_NS` tags or use `CPM_[module name]_NS` as your top
level namespace, like so:

```cpp
  namespace CPM_[module name]_NS {

    ...  

  } // namespace CPM_[module name]_NS
```

The ``[module name]`` part of the preprocessor definition's name comes from
your call to `CPM_AddModule`. The first argument given to `CPM_InitModule` becomes
``[module name]`` in your application.

Note that this is *not* required but it is *heavily* recommended when you are
building CPM modules. If you want your users to be able to use multiple
versions of your module within the same static linkage unit you must include
this.

Why would you want to let users utilize multiple versions of your module?
Users won't know that they are actually using multiple different versions of
your module. A more recent version of your module may be included by the user
and an older version of your module may be pulled in as a dependency of
another module the user is relying on.

Directory Structure
-------------------

In order to avoid header name conflicts CPM modules adhere to the directory
following structure:

```
  Root of [module name]
    |-> CMakeLists.txt
    |-> test
    |-> [module name]
      |-> [public headers go here]  
      |-> src
        |-> [private headers and source code]
```

Using this structure users would include your public headers using:

```
  #include <[module name]/interface.h>
```

Include Path
------------

By default, the root of your project is added to the include path. If you need
to expose more directories to the consumer of your module use the
``CPM_ExportAdditionalIncludeDir`` function to add directories to the
consumer's include path. The first and only argument to
``CPM_ExportAdditionalIncludeDir`` is the directory you want to add to the
path. Be sure to clearly document any changes you make to the include path in
your module's README.

Definitions
-----------

Just as with the include paths above you can set preprocessor definitions for
the consumer. Use the function ``CPM_ExportAdditionalDefinition``, like below:

```
  CPM_ExportAdditionalDefinition("-DMONGO_HAVE_STDINT")
```

Targets
-------

If you have additional targets, or don't want to use the target name that
CPM generates for you, you can use the `CPM_ExportAdditionalLibraryTarget`
function that comes with CPM.

```
  CPM_ExportAdditionaLibraryTarget("MyTargetName")
```

This target will be added to the `target_link_libraries` call issued by the
consumer of your module.

Registering Your Module
-----------------------

Once you have finished writing your module, fork
http://github.com/iauns/cpm-modules.git and submit your module via a pull
request. You only have to do this once per module, and your module will be
registered with the cpm website.

Note that this step is *not* mandatory. You can use your module without
registering it by just pointing CPM to the URL of your git repository.
Although module registration is recommended because registering your
repository makes it easier for others to find.

Building Externals
------------------

If you are wrapping non-CPM code then you are likely building a CPM external.
Building an external is just like building a module except for a call to:

```
  CPM_ForceOnlyOneModuleVersion()
```

somewhere in your module's CMakeLists.txt file. This function ensures exactly
one (and only one) version of your module is ever statically linked.

In addition to this, you should reference the original repository in your
cpm-modules JSON file by adding the 'external' key/value pair. The key being
'external' and the value being be a URL locating the repository for which you
have created this external. 

Common Issues
=============

Below are some common issues users encounter and solutions to them.

Exposing foreign module interfaces
----------------------------------

Some modules require the ability to expose classes from other included modules.
This is allowed by tagging the module that you plan on exporting with
``EXPORT_MODULE TRUE`` just like:

```
  CPM_AddModule("GLM"
    GIT_REPOSITORY "https://github.com/iauns/cpm-glm"
    GIT_TAG "origin/master"
    USE_EXISTING_VER TRUE
    EXPORT_MODULE TRUE    # Use EXPORT_MODULE sparingly. We expose GLM's interface
    )                     # through our own interface hence why we export it.
```

In this case, GLM's definitions and include paths will be exported to the
direct consumer of your module. It will not export this module to any parents
of your consumer.

Using an existing module version
--------------------------------

CPM allows you the flexibility of selecting the most recently used version of a
particular module instead of the version you requested. This is useful when you
are working with externals or modules that require you to only use one version.
Simply add ``USE_EXISTING_VER TRUE`` in your call to ``CPM_AddModule``. An
example of this is given above in the section on exposing foreign module
interfaces.

For example, if a module you added (lets call this module `B`) requested
version `v0.9.1` of module `A`, and you subsequently requested `v0.9.5` of
module `A`, then your version would be upgraded to `v0.9.5` to comply with the
pre-existing version of the module if you specified `USE_EXISTING_VER TRUE`
when adding module `A`. It is considered best practice to set
`USE_EXSTING_VER` to `TRUE` when adding *externals* (not regular modules) to
your project. Especially when building modules for others to use.

When adding regular non-external modules, you may consider using this
option to reduce the size of your executable if multiple different versions of
the same module are being used. Just be weary of compiler errors due to
version conflicts. In most cases, this option should be avoided when using
regular, non-external, CPM modules.

Force only one module version
-----------------------------

As pointed out in the externals section you may force all consumers, indirect
or direct, of your module to use only one version. Most module creators won't
need to worry about this corner case, but it is required that all externals
use this. Include a call to ``CPM_ForceOnlyOneModuleVersion`` anywhere in
your module's CMakeLists.txt file to enforce this. Usually this call is made
directly after calling ``CPM_InitModule``.

If you do this, you should indicate that your module is an 'external' in your
module's JSON file. Even if you don't use any external code. It is important
to separate these modules from 'regular' modules, and the nomenclature we have
chosen for these types of modules are 'externals'.

Downloading repos without external projects
-------------------------------------------

CPM provides a utility function that allows you to download repositories at
configuration time. This function is: `CPM_EnsureRepoIsCurrent`. This function
will also ensure the tag you specify is up to date and the repo is present
before continuing execution of CMakeLists.txt. You can download both git
repositories and SVN repositories using this function. For a reference
regarding the function's parameters, see the comments at the top of CPM.cmake.

For examples of using this function, see the
[google test](https://github.com/iauns/cpm-google-test) CPM external.

FAQ
===

Why not CMake external projects?
------------------------------------------------

CPM was initially built using external projects but the external project
mechanism proved to be too restrictive. When using external projects, a
cmake+build+cmake+build cycle was required to detect all static dependencies.
One of CPM's tenets is to never require a departure from the standard cmake +
build sequence, so we couldn't use external projects as-is.

After working on CPM it became clear that ``add_subdirectory`` was the right
choice. ``add_subdirectory`` allows us to easily enforce configuration
constraints such as only allowing one version of a library to be statically
linked without needing to read/write to files and use the akward double
configure and build cycle.

Another advantage of ``add_subdirectory`` is that it include's the module's
source code as part of any project solution that is generated from CMake. See
the ``CPM Advantages`` section.

How do I see the module dependency hierarchy?
---------------------------------------------

When building your project define: ``CPM_SHOW_HIERARCHY=TRUE``.

On the command line this would look something like

```
  cmake -DCPM_SHOW_HIERARCHY=TRUE ...
```

A module's namespace isn't declared!
----------------------------------------------------------

If you know for certain the the module's header file has been included, then
this is most likely due to the use of conflicting header guards.

How do I Manage CPM Namespaces?
-------------------------------

If the `CPM_<NAME>_NS` namespace declarations are hurting your eyes, it has
been our experience that building a header that renames all of the module
namespaces is quite useful. Something akin to the following:

```cpp
  #ifndef __MY_NAMESPACES_H
  #define __MY_NAMESPACES_H

  // 'Forward declaration' of CPM module namespaces.
  namespace CPM_SPIRE_NS {}
  namespace CPM_SPIRE_SCIRUN_NS {}
  ... (more forward declarations) ...
  
  // Renaming the namespaces in our top level namespace.
  namespace my_namespace {
    namespace spire     = CPM_SPIRE_NS;
    namespace spire_sr  = CPM_SPIRE_SCIRUN_NS;
  }

  #endif
```

Remember not to expose your namespaces.h header file in your public interface.
Use the preprocessor definitions in your public interface. If you absolutely
must include the namespaces header file in your public interface, then ensure
you give the include guard for your namespaces header a unique name.


