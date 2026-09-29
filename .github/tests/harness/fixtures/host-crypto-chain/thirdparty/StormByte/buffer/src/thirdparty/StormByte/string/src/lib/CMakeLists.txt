include(GNUInstallDirs)
set(_srcs "${CMAKE_CURRENT_SOURCE_DIR}/string.c")
buildmaster_component(
    cr-string
    "Harness crypto-chain string"
    "${_srcs}"
    ""
    static
    "cr-string"
    "BACKEND=host"
)
target_include_directories(cr-string PUBLIC "${CMAKE_CURRENT_SOURCE_DIR}")
buildmaster_link(cr-string cr-base)
install(TARGETS cr-string ARCHIVE DESTINATION ${CMAKE_INSTALL_LIBDIR})
install(FILES cr_string.h DESTINATION ${CMAKE_INSTALL_INCLUDEDIR})
