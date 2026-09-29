cmake_minimum_required(VERSION 3.20)
project(hn-system C)

include(GNUInstallDirs)

add_library(hn-system STATIC system.c)
install(TARGETS hn-system ARCHIVE DESTINATION ${CMAKE_INSTALL_LIBDIR})
install(FILES hn_system.h DESTINATION ${CMAKE_INSTALL_INCLUDEDIR})
