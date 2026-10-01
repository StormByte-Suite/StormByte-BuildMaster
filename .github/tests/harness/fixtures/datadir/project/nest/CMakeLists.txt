cmake_minimum_required(VERSION 3.20)
project(dd-nest C)
include(GNUInstallDirs)

if(NOT DD_BM_ROOT)
	message(FATAL_ERROR "datadir nest: DD_BM_ROOT is empty")
endif()
add_subdirectory("${DD_BM_ROOT}" "${CMAKE_CURRENT_BINARY_DIR}/buildmaster")
include("${DD_BM_ROOT}/helpers.cmake")

buildmaster_component(
	dd-inner
	"Harness datadir inner"
	"${CMAKE_CURRENT_SOURCE_DIR}/inner"
	""
	static
	"ddinner"
	"FILES={URL=${DD_URL_NEST};NAME=nest;EXPECTED_HASH=SHA256=${DD_HASH_NEST}}"
)

add_library(ddnest STATIC nest.c)
install(TARGETS ddnest ARCHIVE DESTINATION ${CMAKE_INSTALL_LIBDIR})
