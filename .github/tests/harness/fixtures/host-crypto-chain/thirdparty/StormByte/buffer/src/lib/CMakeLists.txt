include(GNUInstallDirs)
set(_srcs "${CMAKE_CURRENT_SOURCE_DIR}/buffer.c")
buildmaster_component(
    cr-buffer
    "Harness crypto-chain buffer"
    "${_srcs}"
    ""
    static
    "cr-buffer"
    "BACKEND=host"
)
target_include_directories(cr-buffer PUBLIC "${CMAKE_CURRENT_SOURCE_DIR}")
buildmaster_link(cr-buffer cr-logger)
buildmaster_link(cr-buffer cr-system)
install(TARGETS cr-buffer ARCHIVE DESTINATION ${CMAKE_INSTALL_LIBDIR})
install(FILES cr_buffer.h DESTINATION ${CMAKE_INSTALL_INCLUDEDIR})
