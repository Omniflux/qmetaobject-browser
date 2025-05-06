# Configure CMAKE
cmake_minimum_required (VERSION 3.30)
list (APPEND CMAKE_MODULE_PATH ${CMAKE_CURRENT_SOURCE_DIR}/cmake/Modules)

# Setup Project
project ("QMetaObject Browser" VERSION 0.0.1.0 DESCRIPTION "DAZ Studio QMetaObject Browser Plugin" LANGUAGES CXX)
set (PROJECT_AUTHOR "Omni Flux")
set (PROJECT_COPYRIGHT "Copyright (C) 2025")
configure_file (config.h.in config.h @ONLY)

# Build in parallel with MSVC
add_compile_options ($<$<OR:$<CXX_COMPILER_ID:MSVC>,$<C_COMPILER_ID:MSVC>>:/MP>)

# Find external dependencies
find_package (DAZStudioSDK 4.5 REQUIRED)

if (DAZStudioSDK_TOOLKIT_INCOMPATIBLE)
	message (SEND_ERROR)
endif()

# Enable Qt Auto MOC/UIC/RCC
set (CMAKE_AUTOMOC ON)
set (CMAKE_AUTOUIC ON)
set (CMAKE_AUTORCC ON)

# Configure DAZ Studio plugin
add_library (of_qmetaobjectbrowser MODULE)
target_compile_definitions (of_qmetaobjectbrowser PRIVATE $<$<PLATFORM_ID:Windows>:WIN32_LEAN_AND_MEAN NOMINMAX>)
target_link_libraries (of_qmetaobjectbrowser PRIVATE DAZStudioSDK::DAZStudioSDK Qt4::QtCore Qt4::QtGui Qt4::QtScript)

target_sources (of_qmetaobjectbrowser PRIVATE FILE_SET generated_headers TYPE HEADERS BASE_DIRS "${CMAKE_CURRENT_BINARY_DIR}" FILES
	"${CMAKE_CURRENT_BINARY_DIR}/config.h"
)

target_sources (of_qmetaobjectbrowser PRIVATE FILE_SET HEADERS FILES
	qmetaobjectbrowser.hpp
)

target_sources (of_qmetaobjectbrowser PRIVATE
	$<$<PLATFORM_ID:Windows>:resourcescript.rc>
	qmetaobjectbrowser.cpp
	qmetaobjectplugin.cpp
)