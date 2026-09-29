cmake_minimum_required(VERSION 3.28)
project(hn-buffer-proj C)

include(GNUInstallDirs)

if(NOT HN_BM_ROOT)
	message(FATAL_ERROR "host-nested-reconfigure buffer: HN_BM_ROOT is empty")
endif()
add_subdirectory("${HN_BM_ROOT}" "${CMAKE_BINARY_DIR}/buildmaster")
include("${HN_BM_ROOT}/helpers.cmake")

buildmaster_component(
	hn-logger
	"Harness nested-reconfigure logger"
	"${CMAKE_CURRENT_SOURCE_DIR}/../logger"
	""
	static
	"hn-logger"
)
buildmaster_component(
	hn-system
	"Harness nested-reconfigure system"
	"${CMAKE_CURRENT_SOURCE_DIR}/../system"
	""
	static
	"hn-system"
)

# CONFIGURE_DEPENDS: a new source re-runs CMake inside this nested build.
file(GLOB_RECURSE HN_SOURCES CONFIGURE_DEPENDS "${CMAKE_CURRENT_SOURCE_DIR}/src/*.c")
buildmaster_component(
	hn-buffer
	"Harness nested-reconfigure buffer"
	"${HN_SOURCES}"
	""
	static
	"hn-buffer"
	"BACKEND=host;ALIAS=Hn::Buffer"
)
target_include_directories(hn-buffer PUBLIC "${CMAKE_CURRENT_SOURCE_DIR}/src")
buildmaster_link(hn-buffer hn-logger)
buildmaster_link(hn-buffer hn-system)

install(TARGETS hn-buffer ARCHIVE DESTINATION ${CMAKE_INSTALL_LIBDIR})
install(FILES src/hn_buffer.h DESTINATION ${CMAKE_INSTALL_INCLUDEDIR})
