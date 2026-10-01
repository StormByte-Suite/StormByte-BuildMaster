cmake_minimum_required(VERSION 3.20)
project(dd-inner C)
include(GNUInstallDirs)

add_library(ddinner STATIC inner.c)
install(TARGETS ddinner ARCHIVE DESTINATION ${CMAKE_INSTALL_LIBDIR})
