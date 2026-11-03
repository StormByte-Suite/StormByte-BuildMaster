cmake_minimum_required(VERSION 3.21)
project(links-reenabled C)

if(NOT RR_BM_ROOT)
	message(FATAL_ERROR "links-reenabled: RR_BM_ROOT is empty")
endif()
add_subdirectory("${RR_BM_ROOT}" "${CMAKE_BINARY_DIR}/buildmaster")
include("${RR_BM_ROOT}/helpers.cmake")

option(RR_ENABLE "Enable the bundled dependency" ON)

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

if(RR_ENABLE)
	buildmaster_component(
		rr-dep
		"Harness re-enabled dependency"
		"${CMAKE_CURRENT_SOURCE_DIR}/dep"
		""
		static
		"rr-dep"
	)
	buildmaster_link(rr-host rr-dep)
endif()

add_executable(rr-check check.c)
target_link_libraries(rr-check PRIVATE rr-host)
set_target_properties(rr-check PROPERTIES
	RUNTIME_OUTPUT_DIRECTORY "${CMAKE_BINARY_DIR}/bin"
	BUILD_RPATH "${CMAKE_BINARY_DIR};${BUILDMASTER_INSTALL_LIBDIR}"
)
