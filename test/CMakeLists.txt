project(libhandler_tests LANGUAGES C)

# Compile all tests into a single executable 
add_executable(main-tests 
    main-tests.c 
    tests.c
    perf.c
    test-amb.c
    test-dynamic.c
    test-excn.c
    test-exn.c
    test-general.c
    test-raise.c
    test-state.c
    test-state-alloc.c
    test-tailops.c
    test-yieldn.c
    tests.h
    perf.h
)

target_include_directories(main-tests PUBLIC ${PROJECT_SOURCE_DIR})

target_link_libraries(main-tests libhandler)

enable_testing()

# Run all tests as a test-suite 
add_test(NAME main-tests COMMAND main-tests)

#TODO: Consider using first-class test suite for better integration 
#           with tools (CTest, Visual Studio, CI, Etc).
#           Each test source file would then be it's own test and exe.


