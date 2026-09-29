include(GNUInstallDirs)
set(_srcs "${CMAKE_CURRENT_SOURCE_DIR}/logger.c")
buildmaster_component(
    cr-logger
    "Harness crypto-chain logger"
    "${_srcs}"
    ""
    static
    "cr-logger"
    "BACKEND=host"
)
target_include_directories(cr-logger PUBLIC "${CMAKE_CURRENT_SOURCE_DIR}")
buildmaster_link(cr-logger cr-string)
install(TARGETS cr-logger ARCHIVE DESTINATION ${CMAKE_INSTALL_LIBDIR})
install(FILES cr_logger.h DESTINATION ${CMAKE_INSTALL_INCLUDEDIR})
