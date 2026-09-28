cmake_minimum_required(VERSION 3.20)
project(AnywhereLeaf LANGUAGES C)

include(GNUInstallDirs)

add_library(anywhere_leaf STATIC anywhere_leaf.c)
target_include_directories(anywhere_leaf PUBLIC "${CMAKE_CURRENT_SOURCE_DIR}")
install(TARGETS anywhere_leaf
	ARCHIVE DESTINATION ${CMAKE_INSTALL_LIBDIR}
	LIBRARY DESTINATION ${CMAKE_INSTALL_LIBDIR}
)
install(FILES anywhere_leaf.h DESTINATION ${CMAKE_INSTALL_INCLUDEDIR})
