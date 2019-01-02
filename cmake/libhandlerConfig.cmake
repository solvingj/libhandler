# Use helper functions from CMake modules
include (CheckSymbolExists)
include (CheckIncludeFile)


# Values come from uname where supported, PROCESSOR_ARCHITECTURE on windows
set(LH_TARGET ${CMAKE_SYSTEM_PROCESSOR}-${CMAKE_SYSTEM_NAME})

message(STATUS "LH_TARGET : ${LH_TARGET}")

set(LH_ABI_ARCH ${CMAKE_SYSTEM_PROCESSOR})

message(STATUS "LH_ABI_ARCH : ${LH_ABI_ARCH}")

if ("${CMAKE_C_COMPILER_ID}" STREQUAL "Clang")
    if(WIN32)
	set(LH_CCNAME clang-cl)
    else()
        set(LH_CCNAME clang)
    endif()
elseif ("${CMAKE_C_COMPILER_ID}" STREQUAL "GNU")
    set(LH_CCNAME gcc)
elseif ("${CMAKE_C_COMPILER_ID}" STREQUAL "MSVC")
    set(LH_CCNAME cl)
endif()

message(STATUS "LH_CCNAME : ${LH_CCNAME}")

# Explicitly select setjmp assembly file based on platform
if(WIN32)
    if(CMAKE_GENERATOR_PLATFORM MATCHES ARM.*)
        if(CMAKE_SIZEOF_VOID_P EQUAL 4)
            set(ASM_SETJMP_FILE setjmp_arm.s)
        else()
            set(ASM_SETJMP_FILE setjmp_arm64.s)
        endif()
    else()
        if(CMAKE_SIZEOF_VOID_P EQUAL 4)
            set(ASM_SETJMP_FILE setjmp_x86.asm)
        else()
            set(ASM_SETJMP_FILE setjmp_x64.asm)
        endif()        
    endif()
elseif(UNIX)
    if(CMAKE_SIZEOF_VOID_P EQUAL 4)
        set(ASM_SETJMP_FILE setjmp_amd32.s)
    else()
        set(ASM_SETJMP_FILE setjmp_amd64.s)
    endif()
elseif(CMAKE_GENERATOR_PLATFORM MATCHES ARM.*)
    if(CMAKE_SIZEOF_VOID_P EQUAL 4)
        set(ASM_SETJMP_FILE setjmp_arm.s)
    else()
        set(ASM_SETJMP_FILE setjmp_arm64.s)
    endif()
endif()

# Explicitly select setjmp assembly file based on platform
if(ASM_SETJMP_FILE)
    set(ASM_SETJMP_FILE src/asm/${ASM_SETJMP_FILE})
    set(HAS_ASMSETJMP TRUE)
    message(STATUS "Using custom setjmp assembly file: ${ASM_SETJMP_FILE}")
else()
    message(STATUS "Not using custom setjmp assembly file: ${ASM_SETJMP_FILE}")
endif()

# Parse assembly file to find and set the size of jump buffer
if(HAS_ASMSETJMP)
    file(
        STRINGS 
            ${ASM_SETJMP_FILE}
            SIZEOF_LINE_FOUND
            REGEX sizeof
    )
    if(SIZEOF_LINE_FOUND)
        string(REGEX MATCH [0-9]+ ASM_JMPBUF_SIZE ${SIZEOF_LINE_FOUND})
        if(ASM_JMPBUF_SIZE)
            message(STATUS "Size of ASM Jump Buffer : ${ASM_JMPBUF_SIZE}")
        endif()
    endif()
endif()

# Fallback to known platform implementations of setjmp 
if(NOT HAS_ASMSETJMP)
    check_symbol_exists(sigsetjmp setjmp.h HAS_SIGSETJMP)
    if(NOT HAS_SIGSETJMP)
        check_symbol_exists(_setjmp setjmp.h HAS__SETJMP)
        if(NOT HAS__SETJMP)
            check_symbol_exists(setjmp setjmp.h HAS_SETJMP)
            if(HAS_SETJMP)
                message(STATUS "Regular setjmp found; this may be not most efficient. "
                                          "Consider adding an assembly definition in src/asm. ")
            endif()
        endif()
    endif()
endif()


# Parse assembly file to find and set preprocessor definition for linked exception frames for C++
if(HAS_ASMSETJMP)
    file(
        STRINGS 
        ${ASM_SETJMP_FILE} 
        ASM_HAS_EXN_FRAMES 
        REGEX _lh_get_exn_top
    )
    if(ASM_HAS_EXN_FRAMES)
        message(STATUS "Found _lh_get_exn_top: Will use linked exception frames for C++ (and SEH)")
        set_source_files_properties(${ASM_SETJMP_FILE} PROPERTIES COMPILE_FLAGS "/safeseh")
    else()
        message(STATUS "Did not find _lh_get_exn_top: Will not use linked exception frames for C++")
    endif()
else()
    message(STATUS "Did not find _lh_get_exn_top: Will not use linked exception frames for C++")
endif()

# Validate all required symbols and headers exist
check_include_file(stdbool.h HAS_STDBOOL_H)
check_symbol_exists(strncat_s string.h HAS_STRNCAT_S)
check_symbol_exists(strerror_s string.h HAS_STRERROR_S)
check_symbol_exists(memcpy_s string.h HAS_MEMCPY_S)
check_symbol_exists(memmove_s string.h HAS_MEMMOVE_S)
check_symbol_exists(alloca alloca.h HAS_ALLOCA_H)
if(NOT HAS_ALLOCA_H)
    check_include_file(malloc.h HAS__ALLOCA)
endif()


# Replace strings in cenv.h.in file with CMake variable values: 
#
#  #cmakedefine HAS_STRNCAT_S 
#  
#  ...becomes one of the following...
#
#  #define HAS_STRNCAT_S
#  ...or...
#  /* #undef HAS_STRNCAT_S */
#
# #define LH_CCNAME "${LH_CCNAME}"
#
#  ...becomes something like: 
#
#  #define LH_CCNAME "cl"
#
configure_file(
    ${PROJECT_SOURCE_DIR}/inc/cenv.h.in 
    generated/inc/cenv.h
)

