cmake_minimum_required(VERSION 3.20)
project(dd-lib C)
include(GNUInstallDirs)

add_library(ddtop STATIC dd.c)
install(TARGETS ddtop ARCHIVE DESTINATION ${CMAKE_INSTALL_LIBDIR})
