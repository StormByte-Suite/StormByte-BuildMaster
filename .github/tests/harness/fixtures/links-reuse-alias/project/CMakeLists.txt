cmake_minimum_required(VERSION 3.21)
project(ra-top C)

if(NOT RA_BM_ROOT)
	message(FATAL_ERROR "links-reuse-alias: RA_BM_ROOT is empty")
endif()
add_subdirectory("${RA_BM_ROOT}" "${CMAKE_BINARY_DIR}/buildmaster")
include("${RA_BM_ROOT}/helpers.cmake")

# Declaration order matters: ra-log's nested configure publishes
# links/ra-base.cmake before ra-sys's nested configure reuses it.
buildmaster_component(
	ra-log
	"Harness reuse-alias logger"
	"${CMAKE_CURRENT_SOURCE_DIR}/log"
	"RA_BM_ROOT=${RA_BM_ROOT}"
	shared
	"ra-log"
)
buildmaster_component(
	ra-sys
	"Harness reuse-alias system"
	"${CMAKE_CURRENT_SOURCE_DIR}/sys"
	"RA_BM_ROOT=${RA_BM_ROOT}"
	shared
	"ra-sys"
)
