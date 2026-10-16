cmake_minimum_required(VERSION 3.21)
project(widget_producer LANGUAGES C)
include(GNUInstallDirs)
add_library(widget SHARED widget.c)
target_compile_definitions(widget PRIVATE WIDGET_BUILD)
target_include_directories(widget PUBLIC ${CMAKE_CURRENT_SOURCE_DIR})
install(TARGETS widget
	RUNTIME DESTINATION ${CMAKE_INSTALL_BINDIR}
	LIBRARY DESTINATION ${CMAKE_INSTALL_LIBDIR}
	ARCHIVE DESTINATION ${CMAKE_INSTALL_LIBDIR})
install(FILES widget.h DESTINATION ${CMAKE_INSTALL_INCLUDEDIR})
