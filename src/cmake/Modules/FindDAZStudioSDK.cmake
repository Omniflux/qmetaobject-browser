# Distributed under the OSI-approved BSD 3-Clause License.  See accompanying
# file Copyright.txt or https://cmake.org/licensing for details.

#[=======================================================================[.rst:
FindDAZStudioSDK
----------------

Find DAZ Studio SDK include dirs and libraries

Use this module by invoking :command:`find_package` with the form:

.. code-block:: cmake

  find_package(DAZStudioSDK
    [version] [EXACT]      # Minimum or EXACT version e.g. 4.5
    [REQUIRED]             # Fail with error if DAZ Studio SDK is not found
    )

This module finds headers and libraries.

Result Variables
^^^^^^^^^^^^^^^^

This module defines the following variables:

``DAZStudioSDK_FOUND``
  True if headers and requested libraries were found.

``DAZStudioSDK_TOOLKIT_INCOMPATIBLE``
  True if the current compiler toolkit will produce a shared library incompatible with DAZ Studio

``DAZStudioSDK_INCLUDE_DIR``
  DAZ Studio SDK include directory.

``DAZStudioSDK_LIBRARY_DIR``
  Link directories for DAZ Studio SDK libraries.

``DAZStudioSDK_ROOT``
  DAZ Studio SDK root directory.

``DAZStudioSDK_LIBRARY``
  DAZ Studio SDK library to be linked.

``DAZStudioSDK_VERSION``
  DAZ Studio SDK version number in ``W.X.Y.Z`` format.

``DAZStudioSDK_VERSION_MAJOR``
  DAZ Studio SDK major version number (``W`` in ``W.X.Y.Z``).

``DAZStudioSDK_VERSION_MINOR``
  DAZ Studio SDK major version number (``X`` in ``W.X.Y.Z``).

``DAZStudioSDK_VERSION_REV``
  DAZ Studio SDK revision version number (``Y`` in ``W.X.Y.Z``).

``DAZStudioSDK_VERSION_BUILD``
  DAZ Studio SDK build version number (``Z`` in ``W.X.Y.Z``).

Cache variables
^^^^^^^^^^^^^^^

Search results are saved persistently in CMake cache entries:

``DAZStudioSDK_INCLUDE_DIR``
  Directory containing DAZ Studio SDK headers.

``DAZStudioSDK_LIBRARY_DIR``
  Directory containing DAZ Studio SDK libraries.

Hints
^^^^^

This module reads hints about search locations from a variable:

``DAZStudioSDK_ROOT_DIR``
  Preferred installation prefix.

Users may set this hint or results as ``CACHE`` entries.  Projects
should not read these entries directly but instead use the above
result variables.  One may specify this hint as an environment
variable if it is not specified as a CMake variable or cache entry.

Imported Targets
^^^^^^^^^^^^^^^^

This module defines the following :prop_tgt:`IMPORTED` targets:

``DAZStudioSDK::DAZStudioSDK``
  Target for dependencies.

Examples
^^^^^^^^

Find DAZ Studio SDK libraries and use imported target:

.. code-block:: cmake

  find_package(DAZStudioSDK 4.5 REQUIRED)
  add_executable(foo foo.cc)
  target_link_libraries(foo DAZStudioSDK::DAZStudioSDK)

.. code-block:: cmake

  find_package(DAZStudioSDK 4.5)
  if(DAZStudioSDK_FOUND)
    include_directories(${DAZStudioSDK_INCLUDE_DIRS})
    add_executable(foo foo.cc)
    target_link_libraries(foo ${DAZStudioSDK_LIBRARIES})
  endif()
#]=======================================================================]

include (FindPackageHandleStandardArgs)

# Get user specified directory to search
set (DAZStudioSDK_ROOT_DIR "${DAZStudioSDK_ROOT_DIR}" CACHE PATH "Directory to search")

# Check Windows registry for DAZ Studio Content paths to search (DIM installs the SDK here)
if (WIN32)
	execute_process(
		COMMAND powershell
		 (Get-ItemProperty -Path 'HKCU:\\Software\\DAZ\\Studio*\\' -Name 'ContentDir*' |
		  Select ContentDir* |
		  ForEach-Object { $_.PSObject.Properties | ForEach-Object { $_.Value} } |
		  Sort-Object -Unique
		 ) -replace ' ', '\\ '
		OUTPUT_VARIABLE _SEARCH_PATHS
	)
	string (REGEX REPLACE "\n" ";" _SEARCH_PATHS "${_SEARCH_PATHS}")
endif()

# Search for the include directory
find_path (DAZStudioSDK_INCLUDE_DIR
	NAMES
	 dzversion.h
	HINTS
	 ${DAZStudioSDK_ROOT_DIR}
	 $ENV{DAZStudioSDK_ROOT_DIR}
	 ${_SEARCH_PATHS}
	PATH_SUFFIXES
	 include/
	 DAZStudio4.5+\ SDK/include/
)

# Get the SDK directory root
cmake_path (GET DAZStudioSDK_INCLUDE_DIR PARENT_PATH DAZStudioSDK_ROOT)
set (DAZStudioSDK_ROOT "${DAZStudioSDK_ROOT}" CACHE PATH "DAZ Studio SDK root directory")

# Get the SDK version
if (DAZStudioSDK_INCLUDE_DIR)
	file (STRINGS ${DAZStudioSDK_INCLUDE_DIR}/dzversion.h _temp REGEX "^#define DZ_SDK_VERSION_(MAJOR|MINOR|REV|BUILD)[ \t]+([0-9]+)$")
	if ("${_temp}" MATCHES "#define DZ_SDK_VERSION_MAJOR[ \t]+([0-9]+)")
		set (DAZStudioSDK_VERSION_MAJOR ${CMAKE_MATCH_1})
	endif()
	if ("${_temp}" MATCHES "#define DZ_SDK_VERSION_MINOR[ \t]+([0-9]+)")
		set (DAZStudioSDK_VERSION_MINOR ${CMAKE_MATCH_1})
	endif()
	if ("${_temp}" MATCHES "#define DZ_SDK_VERSION_REV[ \t]+([0-9]+)")
		set (DAZStudioSDK_VERSION_REV ${CMAKE_MATCH_1})
	endif()
	if ("${_temp}" MATCHES "#define DZ_SDK_VERSION_BUILD[ \t]+([0-9]+)")
		set (DAZStudioSDK_VERSION_BUILD ${CMAKE_MATCH_1})
	endif()
	set (DAZStudioSDK_VERSION "${DAZStudioSDK_VERSION_MAJOR}.${DAZStudioSDK_VERSION_MINOR}.${DAZStudioSDK_VERSION_REV}.${DAZStudioSDK_VERSION_BUILD}")
endif()

# Setup library path prefixes and library suffixes
if (WIN32)
	set (_QT_LIB_SUFFIX ${DAZStudioSDK_VERSION_MAJOR})

	if (CMAKE_SIZEOF_VOID_P EQUAL 4)
		set (_LIB_PATH_SUFFIX Win32)
	else()
		set (_LIB_PATH_SUFFIX x64)
	endif()
elseif (APPLE)
	set (_QT_LIB_SUFFIX "")

	if (CMAKE_SIZEOF_VOID_P EQUAL 4)
		set (_LIB_PATH_SUFFIX Mac32)
	else()
		set (_LIB_PATH_SUFFIX Mac64)
	endif()
endif()

# Find dzcore library
find_library (DAZStudioSDK_LIBRARY
	NAMES
	 dzcore
	HINTS
	 ${DAZStudioSDK_ROOT}
	NO_DEFAULT_PATH
	PATH_SUFFIXES
	 lib/${_LIB_PATH_SUFFIX}
)

# Get the library directory
cmake_path (GET DAZStudioSDK_LIBRARY PARENT_PATH DAZStudioSDK_LIBRARY_DIR)

# Find DAZ PreCompiler
find_program (DAZStudioSDK_DPC
	NAMES
	 dpc
	HINTS
	 ${DAZStudioSDK_ROOT}
	NO_DEFAULT_PATH
	PATH_SUFFIXES
	 bin/${_LIB_PATH_SUFFIX}
)

# Get the binary directory
cmake_path (GET DAZStudioSDK_DPC PARENT_PATH DAZStudioSDK_BINARY_DIR)

# Setup exported symbols files
if (WIN32)
	set (DAZStudioSDK_DEF_FILE "${CMAKE_CURRENT_BINARY_DIR}/DAZStudioPluginLinker.def")
	if (NOT EXISTS ${DAZStudioSDK_DEF_FILE})
		file (WRITE ${DAZStudioSDK_DEF_FILE}
"EXPORTS
	getSDKVersion	@1
	getPluginDefinition	@2
SECTIONS
	.data READ WRITE"
		)
	endif()
elseif (APPLE)
	find_file (DAZStudioSDK_EXPORTED_SYMBOLS_FILE
		NAMES
		 exportedPluginSymbols.txt
		PATHS
		 ${DAZStudioSDK_INCLUDE_DIR}
		NO_DEFAULT_PATH
	)
endif()

# Find QMake
find_program (QT_QMAKE_EXECUTABLE
	NAMES
	 qmake
	HINTS
	 ${DAZStudioSDK_BINARY_DIR}
	NO_DEFAULT_PATH
)

# Find QtCore library
find_library (QT_QTCORE_LIBRARY_RELEASE
	NAMES
	 QtCore${_QT_LIB_SUFFIX}
	HINTS
	 ${DAZStudioSDK_LIBRARY_DIR}
	NO_DEFAULT_PATH
)

# Find QtCore include directory
find_path (QT_QTCORE_INCLUDE_DIR
	NAMES
	 qconfig.h
	HINTS
	 ${DAZStudioSDK_INCLUDE_DIR}
	NO_DEFAULT_PATH
	PATH_SUFFIXES
	 QtCore
)

# Provide fake Qt MKSPECS directory
set(QT_MKSPECS_DIR "${CMAKE_CURRENT_BINARY_DIR}/fake_mkspecs" CACHE PATH "")
file(MAKE_DIRECTORY "${QT_MKSPECS_DIR}/default")

# Find Qt4
set(QT_BINARY_DIR ${DAZStudioSDK_BINARY_DIR} CACHE PATH "")
set(QT_HEADERS_DIR ${DAZStudioSDK_INCLUDE_DIR} CACHE PATH "")
find_package(Qt4 4.8.1 REQUIRED COMPONENTS QtCore QtGui QtNetwork QtOpenGl QtScript QtSql QtXml)

# Export the library directory, libraries, and import target
if (EXISTS ${DAZStudioSDK_LIBRARY})
	add_library (DAZStudioSDK::DAZStudioSDK SHARED IMPORTED)
	set_target_properties (DAZStudioSDK::DAZStudioSDK
		PROPERTIES
		INTERFACE_LINK_LIBRARIES
		 ${DAZStudioSDK_LIBRARY}
		INTERFACE_INCLUDE_DIRECTORIES
		 ${DAZStudioSDK_INCLUDE_DIR}
	)
	add_compile_options ($<$<OR:$<CXX_COMPILER_ID:MSVC>,$<C_COMPILER_ID:MSVC>>:/MP>)
	
	if (WIN32)
		set_property (TARGET DAZStudioSDK::DAZStudioSDK PROPERTY IMPORTED_IMPLIB ${DAZStudioSDK_LIBRARY})
		target_sources (DAZStudioSDK::DAZStudioSDK INTERFACE ${DAZStudioSDK_DEF_FILE})

		if (CMAKE_SIZEOF_VOID_P EQUAL 4)
			add_compile_definitions (_WIN32_WINNT=0x0501)
		else()
			add_compile_definitions (_WIN32_WINNT=0x0502)
		endif()
	elseif (APPLE)
		set_property (TARGET DAZStudioSDK::DAZStudioSDK PROPERTY IMPORTED_LOCATION ${DAZStudioSDK_LIBRARY})
		set_property (TARGET DAZStudioSDK::DAZStudioSDK PROPERTY XCODE_ATTRIBUTE_EXPORTED_SYMBOLS_FILE ${DAZStudioSDK_EXPORTED_SYMBOLS_FILE}) # Not tested
	endif()

	add_executable (DAZStudioSDK::PreCompiler IMPORTED)
	set_target_properties (DAZStudioSDK::PreCompiler
		PROPERTIES
		IMPORTED_LOCATION
		 ${DAZStudioSDK_DPC}
	)
endif()

# Check the toolkit
set (DAZStudioSDK_TOOLKIT_INCOMPATIBLE NO)
if (WIN32)
	if (DAZStudioSDK_VERSION_MAJOR EQUAL 4)
		if (NOT CMAKE_GENERATOR_TOOLSET STREQUAL "v100")
			if (NOT CMAKE_GENERATOR_TOOLSET STREQUAL "Windows7.1SDK")
				message (WARNING "DAZ Studio ${DAZStudioSDK_VERSION_MAJOR} SDK requires MSVC toolkit v100 or Windows7.1SDK")
				set (DAZStudioSDK_TOOLKIT_INCOMPATIBLE YES)
			endif()
		endif()
	endif()
endif()

# Cleanup CMake UI
mark_as_advanced (DAZStudioSDK_DPC DAZStudioSDK_INCLUDE_DIR DAZStudioSDK_LIBRARY)

# Report problems
find_package_handle_standard_args (DAZStudioSDK REQUIRED_VARS DAZStudioSDK_LIBRARY_DIR DAZStudioSDK_INCLUDE_DIR DAZStudioSDK_ROOT DAZStudioSDK_LIBRARY VERSION_VAR DAZStudioSDK_VERSION)