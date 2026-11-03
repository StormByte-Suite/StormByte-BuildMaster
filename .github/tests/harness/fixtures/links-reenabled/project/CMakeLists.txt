cmake_minimum_required(VERSION 3.21)
project(links-reenabled C)

if(NOT RR_BM_ROOT)
	message(FATAL_ERROR "links-reenabled: RR_BM_ROOT is empty")
endif()
add_subdirectory("${RR_BM_ROOT}" "${CMAKE_BINARY_DIR}/buildmaster")
include("${RR_BM_ROOT}/helpers.cmake")

option(RR_ENABLE "Enable the bundled dependency" ON)
option(RR_SYSTEM "Use the system dependency" OFF)

buildmaster_component(
	rr-host
	"Harness re-enabled host"
	"${CMAKE_CURRENT_SOURCE_DIR}/host.c"
	""
	shared
	"rr-host"
	"BACKEND=host"
)
set_target_properties(rr-host PROPERTIES
	WINDOWS_EXPORT_ALL_SYMBOLS ON
	BUILD_RPATH "${BUILDMASTER_INSTALL_LIBDIR}"
)
target_compile_definitions(rr-host PRIVATE "RR_ENABLED=$<BOOL:${RR_ENABLE}>")

if(RR_ENABLE)
	if(RR_SYSTEM)
		add_library(rr-system STATIC system.c)
		set_target_properties(rr-system PROPERTIES POSITION_INDEPENDENT_CODE ON)
		add_library(rr-dep INTERFACE IMPORTED GLOBAL)
		target_link_libraries(rr-dep INTERFACE rr-system)
		set(_rr_expected 7)
	else()
		buildmaster_component(
			rr-dep
			"Harness re-enabled dependency"
			"${CMAKE_CURRENT_SOURCE_DIR}/dep"
			""
			static
			"rr-dep"
		)
		set(_rr_expected 42)
	endif()
	buildmaster_link(rr-host rr-dep)
else()
	set(_rr_expected 17)
endif()

add_executable(rr-check check.c)
target_link_libraries(rr-check PRIVATE rr-host)
target_compile_definitions(rr-check PRIVATE "RR_EXPECTED=${_rr_expected}")
set_target_properties(rr-check PROPERTIES
	RUNTIME_OUTPUT_DIRECTORY "${CMAKE_BINARY_DIR}/bin"
	BUILD_RPATH "${CMAKE_BINARY_DIR};${BUILDMASTER_INSTALL_LIBDIR}"
)

function(_rr_verify_system_links)
	if(NOT RR_ENABLE OR NOT RR_SYSTEM)
		return()
	endif()
	get_target_property(_links rr-host LINK_LIBRARIES)
	if("-lrr-dep" IN_LIST _links OR "rr-dep.lib" IN_LIST _links)
		message(FATAL_ERROR "links-reenabled: SYSTEM host still links the bundled dependency")
	endif()
	get_target_property(_dirs rr-dep INTERFACE_LINK_DIRECTORIES)
	if("${BUILDMASTER_INSTALL_LIBDIR}" IN_LIST _dirs)
		message(FATAL_ERROR "links-reenabled: SYSTEM target inherited the bundled library directory")
	endif()
	get_target_property(_system_links rr-dep INTERFACE_LINK_LIBRARIES)
	if(NOT "${_system_links}" STREQUAL "rr-system")
		message(FATAL_ERROR "links-reenabled: SYSTEM target inherited bundled link dependencies")
	endif()
endfunction()
cmake_language(DEFER CALL _rr_verify_system_links)
