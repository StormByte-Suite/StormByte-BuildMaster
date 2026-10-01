cmake_minimum_required(VERSION 3.21)
project(ra-log-proj C)

include(GNUInstallDirs)

set(CMAKE_WINDOWS_EXPORT_ALL_SYMBOLS ON)

if(NOT RA_BM_ROOT)
	message(FATAL_ERROR "links-reuse-alias log: RA_BM_ROOT is empty")
endif()
add_subdirectory("${RA_BM_ROOT}" "${CMAKE_BINARY_DIR}/buildmaster")
include("${RA_BM_ROOT}/helpers.cmake")

# Winner: publishes links/ra-base.cmake with the alias.
buildmaster_component(
	ra-base
	"Harness reuse-alias base"
	"${CMAKE_CURRENT_SOURCE_DIR}/../base"
	""
	shared
	"ra-base"
	"ALIAS=Ra::Base"
)

buildmaster_component(
	ra-log
	"Harness reuse-alias logger"
	"${CMAKE_CURRENT_SOURCE_DIR}/log.c"
	""
	shared
	"ra-log"
	"BACKEND=host"
)
target_include_directories(ra-log PRIVATE "${CMAKE_CURRENT_SOURCE_DIR}/../base")
if(NOT WIN32 AND NOT APPLE)
	target_link_options(ra-log PRIVATE "LINKER:--no-undefined")
elseif(APPLE)
	target_link_options(ra-log PRIVATE "LINKER:-undefined,error")
endif()
buildmaster_link(ra-log Ra::Base)

install(TARGETS ra-log
	ARCHIVE DESTINATION ${CMAKE_INSTALL_LIBDIR}
	LIBRARY DESTINATION ${CMAKE_INSTALL_LIBDIR}
	RUNTIME DESTINATION ${CMAKE_INSTALL_BINDIR}
)
