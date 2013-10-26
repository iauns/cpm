===
CPM
===

CMake C++ Package Manager.

CPM is designed to save you time and promote small, well-tested, and composable
C++ modules. It allows you to link against multiple different versions of the
same static library so that you can include other C++ modules that may depend
on older or newer versions of the same modules you are using. CPM will also
automatically download and build these C++ modules for you. CPM's goal is to
help support the growth of a module eco-system similar to that of Node.js'.

You can also manage external C or C++ libraries that do not use CPM. Using CPM
externals is akin to using CMake's external project mechanism with the external
project details hidden.

  Note: Modules are fully implemented but external libraries are not.

+---------------+--------------------------------------------------------------+
|  **Warning**  |  CPM is alpha software. The module code is complete but CPM  |
|               |  externals are missing. Feel free to evaluate CPM but please |
|               |  wait until CPM leaves alpha before using it in projects.    |
+---------------+--------------------------------------------------------------+

Using CPM
=========

To use CPM in your C++ project include the following at the top of your
CMakeLists.txt::

  #------------------------------------------------------------------------------
  # Required CPM Setup - See: http://github.com/iauns/cpm
  #------------------------------------------------------------------------------
  set(CPM_DIR "${CMAKE_CURRENT_BINARY_DIR}/cpm-packages" CACHE TYPE STRING)
  if(${CPM_DIR} MATCHES "${CMAKE_CURRENT_BINARY_DIR}")
    message("NOTE: Placing CPM in the binary directory is not recommended.")
    message("      Place CPM alongside the binary directory so that you don't need to")
    message("      recompile your modules everytime you clean your project.")
    message("      Use the CPM_DIR variable to set the CPM directory.")
  endif()
  
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
  
  CPM_Finish()

Then add the ``${CPM_LIBRARIES}`` variable to your ``target_link_libraries``.
That's it. You will be able to start using CPM modules right away by adding
something like::

  CPM_AddModule("spire"
    GIT_REPOSITORY "https://github.com/SCIInstitute/spire"
    GIT_TAG "v0.7.0")

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
class through this namespace like so: ``CPM_SPIRE_NS::Interface``. In general
you will want to rename the namespace to something more appropriate:
``namespace spire = CPM_SPIRE_NS;``. It has been our experience that building a
header containing all of your module namespaces is quite useful. Something like
the following::

  #ifndef NAMESPACES_H
  #define NAMESPACES_H

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

Also be sure to place your calls to CPM_AddModule before your call to
CPM_Finish. The ``# Include any modules here...`` section mentioned in the
first snippet indicates where you should place calls to ``CPM_AddModule`` and
``CPM_AddExternal``.

CPM Externals
-------------

If the library you are interested in isn't a CPM module, try using CPM
externals. While you won't be able to statically link against multiple versions
of the library you can quickly include it if there is a CPM external formula
for it. If the library is hosted in a public location, use the URL of the
library::

  CPM_AddExternal("Full URL goes here")

Otherwise you may attempt to reference the library by name directly::

  CPM_AddExternal("mongodb-c")

If you don't find a formula for a library that you would like to use, kindly
consider contributing one to our CPM externals repository. We're always looking
to expand these formula.

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

Add the following to the top of the CMakeLists.txt for your module:: 

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
      execute_process(
        COMMAND "${GIT_EXECUTABLE}" clone https://github.com/iauns/cpm ${CPM_DIR}
        RESULT_VARIABLE error_code
        OUTPUT_VARIABLE head_sha)
      if(error_code)
        message(FATAL_ERROR "CPM failed to get the hash for HEAD")
      endif()
    endif()
    include(${CPM_DIR}/CPM.cmake)
  endif()
  
  # Include CPM modules or externals here (with CPM_AddModule / CPM_AddExternal).
  
  CPM_InitModule(${CPM_MODULE_NAME})

Be sure to update the ``<name>`` at the beginning of the snippet. ``<name>`` 
is placed in the namespace preprocessor definition for your module. For example,
if ``<name>`` is 'spire' then the preprocessor definition that will be added
to your project will be ``CPM_SPIRE_NS``. Use this definition as a wrapper
around your code and namespaces. Don't worry about users using the same name in
their call to CPM_AddModule as the name you choose in your call to
CPM_InitModule. CPM will automatically handle this for you. Also use
``CPM_LIB_TARGET_NAME`` as the name of your library in add_library and include
``CPM_LIBRARIES`` in target_link_libraries for your static library. Example::

  # Our CPM module library
  add_library(${CPM_LIB_TARGET_NAME} ${Source})
  target_link_libraries(${CPM_LIB_TARGET_NAME} ${CPM_LIBRARIES})

Here is an example class that demonstrates the namespace wrapping::

  namespace CPM_SPIRE_NS {

  ... code here ...

  } // namespace CPM_SPIRE_NS

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
namespaces in CPM_[module name]_NS tags or use CPM_[module name]_NS as your top
level namespace, like so::

  namespace CPM_[module name]_NS {

    ...  

  } // namespace CPM_[module name]_NS

The [module name] part of the definition's name comes directly from your call
to CPM_AddModule. The first argument given to CPM_AddModule becomes [module
name] in your application.

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
following structure::

  Root of [module name]
    |-> CMakeLists.txt
    |-> 3rdParty
    |-> test
    |-> [module name]
      |-> [public headers go here]  
      |-> src
        |-> [private headers and source code]

Using this structure users would include your public headers using::

  #include <[module name]/interface.h>

Also, CPM allows users to add a custom prefix onto the beginning of your
path. This allows them to fix naming conflicts without having to patch or
contact upstream. To include a public header file with a modified prefix use::

  #include <[prefix]/[module name]/interface.h>

Include Path
------------

By default, the root of your project is added to the include path along with
the 3rdParty directory. Note that the 3rdParty directory is added as a SYSTEM
include directory. This is to ignore warnings coming from headers which you do
not have control over.

Please use the 3rdParty directory at the root of your project sparingly. The
includes in this directory will be exposed to all of the users of your module.

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

Sally codes CPM module ``A`` in which she wants to expose a class from Bob's CPM
module ``B``. Sally currently has version 0.11 of Bob's module ``B``. A new
programmer, James, wants to use Sally's module ``A`` module.

Force only one module version
-----------------------------

This issues arises, for example, if you are using something like the OpenGL
extension wrangler. The extension wrangler depends on OpenGL context specific
funciton binding. So calling 'wrangled' functions from multiple static
libraries will cause undue amounts of chaos. Most users won't need to worry
about this corner case. This is a particular affectation of OpenGL's context
handling and Extension Wrangler's binding of function pointers.

To enforce this during the CMake configure step, include a call to
``CPM_ForceOnlyOneModuleVersion`` anywhere in your module's CMakeLists.txt file.
Usually this call is made directly after calling ``CPM_InitModule``.

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

After working on CPM it became clear that ``add_subdirectory`` was the right
choice. ``add_subdirectory`` allows us to easily enforce configuration
constraints, such as only allowing one version of a library to be statically
linked, without needing to read/write to files and use the akward double
configure and build cycle.

Another advantage of ``add_subdirectory`` is that it include's the module's
source code as part of any project solution that is generated from CMake. See
the ``CPM Advantages`` section.

How do I see the module dependency hierarchy?
---------------------------------------------

When building your project define: ``CPM_SHOW_HIERARCHY=TRUE``.

On the command line this would look something like

  cmake -DCPM_SHOW_HIERARCHY=TRUE ...

