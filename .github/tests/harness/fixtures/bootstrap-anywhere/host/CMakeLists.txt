cmake_minimum_required(VERSION 3.20)
project(BuildMasterAnywhereHost LANGUAGES C)
include(GNUInstallDirs)
if(NOT BM_ANYWHERE_BM)
    message(FATAL_ERROR "BM_ANYWHERE_BM is empty")
endif()
add_subdirectory("${BM_ANYWHERE_BM}" "${CMAKE_CURRENT_BINARY_DIR}/bm_abs")
buildmaster_component(
    anywhere-leaf
    "Anywhere leaf"
    "${CMAKE_CURRENT_SOURCE_DIR}/leaf"
    ""
    static
    "anywhere_leaf"
)
add_executable(anywhere_host "${CMAKE_CURRENT_SOURCE_DIR}/anywhere_host.c")
target_include_directories(anywhere_host PRIVATE "${CMAKE_CURRENT_SOURCE_DIR}/leaf")
target_link_libraries(anywhere_host PRIVATE anywhere-leaf)
