# PSn00bSDK main build script
# (C) 2021 spicyjpeg - MPL licensed

# NOTE: CMake doesn't support using multiple toolchains in a single project,
# so we can't use add_subdirectory() to build both the libraries and tools. A
# workaround is to use ExternalProject_Add() to launch multiple independent
# CMake instances, creating what's known as a "superbuild".

cmake_minimum_required(VERSION 3.21)
include(ExternalProject)

project(
	PSn00bSDK
	LANGUAGES    NONE
	# IMPORTANT TODO: set a version number
	VERSION      0.1.0
	DESCRIPTION  "Open source PlayStation 1 SDK"
	HOMEPAGE_URL "http://lameguy64.net/?page=psn00bsdk"
)

# Including this without initializing at least one language throws a warning and
# there's no way to mute it.
include(GNUInstallDirs)

## Settings

# These are passed through to libpsn00b and the examples (they are defined in
# the toolchain file).
set(
	PSN00BSDK_TC $ENV{PSN00BSDK_TC}
	CACHE PATH   "Path to the GCC toolchain's installation directory"
)
set(
	PSN00BSDK_TARGET mipsel-unknown-elf
	CACHE STRING     "GCC toolchain target triplet"
)

set(
	SKIP_TINYXML2 OFF
	CACHE BOOL    "Skip downloading and building tinyxml2 (if already installed)"
)
set(
	SKIP_MKPSXISO OFF
	CACHE BOOL    "Skip downloading and building mkpsxiso (if already installed)"
)
set(
	SKIP_EXAMPLES OFF
	CACHE BOOL    "Skip building SDK examples (not required for installation)"
)

# Forward some important variables to mkpsxiso and to the subprojects (they are
# not inherited automatically as they are not environment variables). This also
# sets all subprojects to "install" everything to a temporary directory in the
# build tree, so they don't actually get installed until "cmake --install" is
# invoked (ExternalProject_Add() runs the subprojects' install step at build
# time).
set(
	COMMON_ARGS
	-DPSN00BSDK_TC:PATH=${PSN00BSDK_TC}
	-DPSN00BSDK_TARGET:STRING=${PSN00BSDK_TARGET}
	-DCMAKE_BUILD_TYPE:STRING=${CMAKE_BUILD_TYPE}
)
set(
	EXT_LIBRARY_ARGS
	-DCMAKE_TOOLCHAIN_FILE:FILEPATH=${CMAKE_TOOLCHAIN_FILE}
	-DCMAKE_INSTALL_PREFIX:PATH=${PROJECT_BINARY_DIR}/install_temp
	-DCMAKE_MSVC_RUNTIME_LIBRARY:STRING=MultiThreaded$<$<CONFIG:Debug>:Debug>
)
set(
	SUBPROJECT_ARGS
	-DCMAKE_TOOLCHAIN_FILE:FILEPATH=${CMAKE_TOOLCHAIN_FILE}
	-DCMAKE_INSTALL_PREFIX:PATH=${PROJECT_BINARY_DIR}/install_tree
)
set(
	EXAMPLES_ARGS
	-DCMAKE_TOOLCHAIN_FILE:FILEPATH=${PROJECT_BINARY_DIR}/install_tree/${CMAKE_INSTALL_LIBDIR}/libpsn00b/cmake/sdk.cmake
	-DCMAKE_INSTALL_PREFIX:PATH=${PROJECT_BINARY_DIR}/examples
)

## External dependencies

if(NOT SKIP_TINYXML2)
	list(APPEND SUBPROJECT_ARGS -Dtinyxml2_ROOT:PATH=${PROJECT_BINARY_DIR}/install_temp)

	ExternalProject_Add(
		tinyxml2
		GIT_REPOSITORY   "https://github.com/leethomason/tinyxml2"
		CMAKE_CACHE_ARGS ${COMMON_ARGS} ${EXT_LIBRARY_ARGS}
		INSTALL_DIR      install_temp
	)
else()
	list(APPEND SUBPROJECT_ARGS -Dtinyxml2_ROOT:PATH=${tinyxml2_ROOT})

	# Create a dummy target so CMake doesn't throw missing dependency errors.
	add_library(tinyxml2 INTERFACE)
endif()

if(NOT SKIP_MKPSXISO)
	ExternalProject_Add(
		mkpsxiso
		GIT_REPOSITORY   "https://github.com/Lameguy64/mkpsxiso"
		CMAKE_CACHE_ARGS ${COMMON_ARGS} ${SUBPROJECT_ARGS}
		INSTALL_DIR      install_tree
		DEPENDS          tinyxml2
	)
else()
	add_library(mkpsxiso INTERFACE)
endif()

## Subprojects

ExternalProject_Add(
	libpsn00b
	SOURCE_DIR       ${PROJECT_SOURCE_DIR}/libpsn00b
	CMAKE_CACHE_ARGS ${COMMON_ARGS} ${SUBPROJECT_ARGS}
	INSTALL_DIR      install_tree
)
ExternalProject_Add(
	tools
	SOURCE_DIR       ${PROJECT_SOURCE_DIR}/tools
	CMAKE_CACHE_ARGS ${COMMON_ARGS} ${SUBPROJECT_ARGS}
	INSTALL_DIR      install_tree
	DEPENDS          tinyxml2
)
ExternalProject_Add(
	examples
	SOURCE_DIR       ${PROJECT_SOURCE_DIR}/examples
	CMAKE_CACHE_ARGS ${COMMON_ARGS} ${EXAMPLES_ARGS}
	INSTALL_DIR      examples
	DEPENDS          libpsn00b tools mkpsxiso
	EXCLUDE_FROM_ALL ${SKIP_EXAMPLES}
)

# Install all files in the temporary installation tree, as well as static files
# from the source tree, when "cmake --install" is invoked.
install(
	DIRECTORY   ${PROJECT_BINARY_DIR}/install_tree/ # THE TRAILING SLASH IS IMPORTANT
	DESTINATION .
	COMPONENT   sdk
	USE_SOURCE_PERMISSIONS
)
install(
	DIRECTORY   doc template
	DESTINATION ${CMAKE_INSTALL_DATADIR}/psn00bsdk
	COMPONENT   docs
)

## CPack configuration

include(cpack/setup.cmake)