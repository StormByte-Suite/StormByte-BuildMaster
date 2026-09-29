cmake_minimum_required(VERSION 3.20)
project(hn-logger C)

include(GNUInstallDirs)

add_library(hn-logger STATIC logger.c)
install(TARGETS hn-logger ARCHIVE DESTINATION ${CMAKE_INSTALL_LIBDIR})
install(FILES hn_logger.h DESTINATION ${CMAKE_INSTALL_INCLUDEDIR})
