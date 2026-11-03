cmake_minimum_required(VERSION 3.21)
project(links-reenabled-dependency C)

include(GNUInstallDirs)

add_library(rr-static STATIC static.c)
set_target_properties(rr-static PROPERTIES
	OUTPUT_NAME rr-dep
	POSITION_INDEPENDENT_CODE ON
)
install(TARGETS rr-static ARCHIVE DESTINATION "${CMAKE_INSTALL_LIBDIR}")

if(NOT WIN32)
	add_library(rr-shared SHARED shared.c)
	set_target_properties(rr-shared PROPERTIES OUTPUT_NAME rr-dep)
	install(TARGETS rr-shared LIBRARY DESTINATION "${CMAKE_INSTALL_LIBDIR}")
endif()
