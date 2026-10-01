cmake_minimum_required(VERSION 3.20)
project(dd-top C)

foreach(_v DD_BM_ROOT DD_URL_TOP DD_HASH_TOP DD_URL_NEST DD_HASH_NEST)
	if("${${_v}}" STREQUAL "")
		message(FATAL_ERROR "datadir: ${_v} is empty")
	endif()
endforeach()
add_subdirectory("${DD_BM_ROOT}" "${CMAKE_BINARY_DIR}/buildmaster")
include("${DD_BM_ROOT}/helpers.cmake")

set(_top_hash ";EXPECTED_HASH=SHA256=${DD_HASH_TOP}")
if(DD_HASH_TOP STREQUAL "NONE")
	set(_top_hash "")
endif()

buildmaster_component(
	dd-top
	"Harness datadir top"
	"${CMAKE_CURRENT_SOURCE_DIR}/lib"
	""
	static
	"ddtop"
	"FILES={URL=${DD_URL_TOP};NAME=top${_top_hash}}"
)

# Nested BuildMaster: its FILES must use the outermost data dir.
buildmaster_component(
	dd-nest
	"Harness datadir nested"
	"${CMAKE_CURRENT_SOURCE_DIR}/nest"
	"DD_BM_ROOT=${DD_BM_ROOT};DD_URL_NEST=${DD_URL_NEST};DD_HASH_NEST=${DD_HASH_NEST}"
	static
	"ddnest"
)
