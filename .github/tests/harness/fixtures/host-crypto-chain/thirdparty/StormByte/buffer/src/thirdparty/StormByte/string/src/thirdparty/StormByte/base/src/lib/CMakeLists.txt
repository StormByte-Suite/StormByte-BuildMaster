include(GNUInstallDirs)
set(_srcs "${CMAKE_CURRENT_SOURCE_DIR}/base.c")
buildmaster_component(
    cr-base
    "Harness crypto-chain base"
    "${_srcs}"
    ""
    static
    "cr-base"
    "BACKEND=host"
)
target_include_directories(cr-base PUBLIC "${CMAKE_CURRENT_SOURCE_DIR}")
install(TARGETS cr-base ARCHIVE DESTINATION ${CMAKE_INSTALL_LIBDIR})
install(FILES cr_base.h DESTINATION ${CMAKE_INSTALL_INCLUDEDIR})
