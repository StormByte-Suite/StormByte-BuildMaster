include(GNUInstallDirs)
set(_srcs "${CMAKE_CURRENT_SOURCE_DIR}/cryptopp.c")
buildmaster_component(
    cr-pp
    "Harness crypto-chain cryptopp"
    "${_srcs}"
    ""
    static
    "cr-pp"
    "BACKEND=host"
)
target_include_directories(cr-pp PUBLIC "${CMAKE_CURRENT_SOURCE_DIR}")
install(TARGETS cr-pp ARCHIVE DESTINATION ${CMAKE_INSTALL_LIBDIR})
install(FILES cr_cryptopp.h DESTINATION ${CMAKE_INSTALL_INCLUDEDIR})
