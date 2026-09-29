include(GNUInstallDirs)
set(_srcs "${CMAKE_CURRENT_SOURCE_DIR}/crypto.c")
buildmaster_component(
    cr-crypto
    "Harness crypto-chain crypto"
    "${_srcs}"
    ""
    static
    "cr-crypto"
    "BACKEND=host"
)
target_include_directories(cr-crypto PUBLIC "${CMAKE_CURRENT_SOURCE_DIR}")
buildmaster_link(cr-crypto cr-buffer)
buildmaster_link(cr-crypto cr-bz2)
buildmaster_link(cr-crypto cr-pp)
install(TARGETS cr-crypto ARCHIVE DESTINATION ${CMAKE_INSTALL_LIBDIR})
install(FILES cr_crypto.h DESTINATION ${CMAKE_INSTALL_INCLUDEDIR})
