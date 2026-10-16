cmake_minimum_required(VERSION 3.21)
project(neg_binary_headers LANGUAGES C)
add_subdirectory("${BM_TEST_REPO_ROOT}" "${CMAKE_CURRENT_BINARY_DIR}/bm")
include("${BM_TEST_REPO_ROOT}/helpers.cmake")
buildmaster_component(
	neg-bin-hd
	"neg binary headers"
	"https://example.invalid/neg-bin.zip"
	""
	headers
	""
	"BACKEND=binary"
)
