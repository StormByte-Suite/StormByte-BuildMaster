cmake_minimum_required(VERSION 3.21)
project(ra-sys-proj C)

include(GNUInstallDirs)

set(CMAKE_WINDOWS_EXPORT_ALL_SYMBOLS ON)

if(NOT RA_BM_ROOT)
	message(FATAL_ERROR "links-reuse-alias sys: RA_BM_ROOT is empty")
endif()
add_subdirectory("${RA_BM_ROOT}" "${CMAKE_BINARY_DIR}/buildmaster")
include("${RA_BM_ROOT}/helpers.cmake")

# links/ra-base.cmake already exists (ra-log): configure is skipped and
# only the file's IMPORTED stub + ALIAS reach this process.
buildmaster_component(
	ra-base
	"Harness reuse-alias base (system copy)"
	"${CMAKE_CURRENT_SOURCE_DIR}/../base"
	""
	shared
	"ra-base"
	"ALIAS=Ra::Base"
)

buildmaster_component(
	ra-sys
	"Harness reuse-alias system"
	"${CMAKE_CURRENT_SOURCE_DIR}/sys.c"
	""
	shared
	"ra-sys"
	"BACKEND=host"
)
target_include_directories(ra-sys PRIVATE "${CMAKE_CURRENT_SOURCE_DIR}/../base")
# Linux would accept a DSO with undefined Base symbols; refuse it.
if(NOT WIN32 AND NOT APPLE)
	target_link_options(ra-sys PRIVATE "LINKER:--no-undefined")
elseif(APPLE)
	target_link_options(ra-sys PRIVATE "LINKER:-undefined,error")
endif()
buildmaster_link(ra-sys Ra::Base)

install(TARGETS ra-sys
	ARCHIVE DESTINATION ${CMAKE_INSTALL_LIBDIR}
	LIBRARY DESTINATION ${CMAKE_INSTALL_LIBDIR}
	RUNTIME DESTINATION ${CMAKE_INSTALL_BINDIR}
)
