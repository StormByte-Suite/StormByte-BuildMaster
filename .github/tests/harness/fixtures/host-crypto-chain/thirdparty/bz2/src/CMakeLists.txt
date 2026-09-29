include(GNUInstallDirs)
set(_srcs "${CMAKE_CURRENT_SOURCE_DIR}/bz2.c")
buildmaster_component(
    cr-bz2
    "Harness crypto-chain bzip2"
    "${_srcs}"
    ""
    static
    "cr-bz2"
    "BACKEND=host"
)
target_include_directories(cr-bz2 PUBLIC "${CMAKE_CURRENT_SOURCE_DIR}")
install(TARGETS cr-bz2 ARCHIVE DESTINATION ${CMAKE_INSTALL_LIBDIR})
install(FILES cr_bz2.h DESTINATION ${CMAKE_INSTALL_INCLUDEDIR})
