# Old enough to support Ubuntu Trusty.
cmake_minimum_required(VERSION 2.8.12)

# Sets newer variable expansion rules for older cmakes. 
if(POLICY CMP0054)
  cmake_policy(SET CMP0054 NEW)
endif()

project(libhandler LANGUAGES C)

if(MSVC)
    message(STATUS "Enabling MASM language support.")
    enable_language(ASM_MASM)
else()
    message(STATUS "Enabling ASM language support.")
    enable_language(ASM)
endif()

set (LIBHANDLER_VERSION_MAJOR 0)
set (LIBHANDLER_VERSION_MINOR 6)
set (LIBHANDLER_VERSION_PATCH 0)
set (LIBHANDLER_VERSION ${LIBHANDLER_VERSION_MAJOR}.${LIBHANDLER_VERSION_MINOR}.${LIBHANDLER_VERSION_PATCH})
set (LIBHANDLER_SOVERSION 0)
set (VERSION ${LIBHANDLER_VERSION})

option(LIBHANDLER_BUILD_TESTING "Enable building of unit tests for libhandler" ON)

# Handle platform-related logic in separate file, including:
# - Setting LH_TARGET
# - Setting LH_CCNAME
# - Setting LH_ABI_ARCH
# - Conditionally setting ASM_HAS_EXN_FRAMES
# - Conditionally setting ASM_SETJMP_FILE
# - Conditionally setting ASM_JMPBUF_SIZE
# - Conditional fallback to other setjmp implementations
# - Setting various definitions based on symbols and headers
# - Generating cenv.h based on aforementioned definitions
include(cmake/libhandlerConfig.cmake)

# Define static library with sources.  Notes:
# - Headers are listed so IDE's can find them
# - ASM_SETJMP_FILE will be empty string if not found
add_library(libhandler
    STATIC
        src/libhandler.c
        src/exception.c
        inc/libhandler.h
        inc/cenv.h
        ${ASM_SETJMP_FILE}
)

target_include_directories(libhandler 
    PUBLIC 
        inc
        $<BUILD_INTERFACE:${CMAKE_CURRENT_BINARY_DIR}/generated/inc>
)

if(LIBHANDLER_BUILD_TESTING)
    # Enable CTest functionality for unit tests
    include(CTest)
    message(STATUS "Adding libhandler unit tests")
    add_subdirectory(test)
else()
    message(STATUS "Skipping libhandler unit tests")
endif()
