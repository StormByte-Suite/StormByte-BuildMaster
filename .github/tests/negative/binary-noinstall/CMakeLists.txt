cmake_minimum_required(VERSION 3.21)
project(neg_binary_noinstall LANGUAGES C)
add_subdirectory("${BM_TEST_REPO_ROOT}" "${CMAKE_CURRENT_BINARY_DIR}/bm")
include("${BM_TEST_REPO_ROOT}/helpers.cmake")
buildmaster_component(
	neg-bin-ni
	"neg binary NOINSTALL"
	"https://example.invalid/neg-bin.zip"
	""
	shared
	negbin
	"BACKEND=binary;NOINSTALL"
)
