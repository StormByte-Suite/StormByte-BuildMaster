include(GNUInstallDirs)
set(_srcs "${CMAKE_CURRENT_SOURCE_DIR}/system.c")
buildmaster_component(
    cr-system
    "Harness crypto-chain system"
    "${_srcs}"
    ""
    static
    "cr-system"
    "BACKEND=host"
)
target_include_directories(cr-system PUBLIC "${CMAKE_CURRENT_SOURCE_DIR}")
buildmaster_link(cr-system cr-string)
if(APPLE)
    target_link_libraries(cr-system PUBLIC "-framework CoreFoundation")
endif()
install(TARGETS cr-system ARCHIVE DESTINATION ${CMAKE_INSTALL_LIBDIR})
install(FILES cr_system.h DESTINATION ${CMAKE_INSTALL_INCLUDEDIR})
