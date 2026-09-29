cmake_minimum_required(VERSION 3.28)
project(hn-top C)

if(NOT HN_BM_ROOT)
	message(FATAL_ERROR "host-nested-reconfigure: HN_BM_ROOT is empty")
endif()
add_subdirectory("${HN_BM_ROOT}" "${CMAKE_BINARY_DIR}/buildmaster")
include("${HN_BM_ROOT}/helpers.cmake")

# Title differs from the nested one on purpose: both processes write
# links/hn-buffer.cmake.
buildmaster_component(
	hn-buffer
	"Harness nested-reconfigure parent buffer"
	"${CMAKE_CURRENT_SOURCE_DIR}/buffer"
	"HN_BM_ROOT=${HN_BM_ROOT}"
	static
	"hn-buffer"
	"ALIAS=Hn::Buffer"
)

buildmaster_component(
	hn-crypto
	"Harness nested-reconfigure crypto"
	"${CMAKE_CURRENT_SOURCE_DIR}/crypto/crypto.c"
	""
	static
	"hn-crypto"
	"BACKEND=host"
)
target_include_directories(hn-crypto PUBLIC "${CMAKE_CURRENT_SOURCE_DIR}/crypto")
buildmaster_link(hn-crypto hn-buffer)

add_executable(hn_test "${CMAKE_CURRENT_SOURCE_DIR}/crypto/hn_test.c")
target_link_libraries(hn_test PRIVATE hn-crypto)
