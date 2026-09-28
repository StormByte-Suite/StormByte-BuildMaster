if(NOT BM_TEST_REPO_ROOT)
    get_filename_component(BM_TEST_REPO_ROOT
        "${CMAKE_CURRENT_SOURCE_DIR}/../../../.."
        ABSOLUTE
    )
endif()
set(_BM_ANY_SRC "${CMAKE_CURRENT_SOURCE_DIR}/host")
set(_BM_ANY_BIN "${CMAKE_BINARY_DIR}/bootstrap_anywhere")
set(_BM_ANY_EXE "${_BM_ANY_BIN}/anywhere_host${CMAKE_EXECUTABLE_SUFFIX}")
add_custom_target(bootstrap_anywhere_run
    COMMAND ${CMAKE_COMMAND} -E rm -rf "${_BM_ANY_BIN}"
    COMMAND ${CMAKE_COMMAND}
        -S "${_BM_ANY_SRC}"
        -B "${_BM_ANY_BIN}"
        -G "${CMAKE_GENERATOR}"
        -DCMAKE_BUILD_TYPE=${CMAKE_BUILD_TYPE}
        -DCMAKE_C_COMPILER=${CMAKE_C_COMPILER}
        -DCMAKE_CXX_COMPILER=${CMAKE_CXX_COMPILER}
        -DBM_ANYWHERE_BM=${BM_TEST_REPO_ROOT}
    COMMAND ${CMAKE_COMMAND} --build "${_BM_ANY_BIN}" --target anywhere_host
    COMMAND "${_BM_ANY_EXE}"
    COMMENT "[BuildMaster/Core     ]: bootstrap BM from absolute path (not thirdparty sibling)"
    VERBATIM
)
