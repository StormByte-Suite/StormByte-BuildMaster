cmake_minimum_required(VERSION 3.21)
project(neg_binary_meta LANGUAGES C)
add_subdirectory("${BM_TEST_REPO_ROOT}" "${CMAKE_CURRENT_BINARY_DIR}/bm")
include("${BM_TEST_REPO_ROOT}/helpers.cmake")
buildmaster_meta(neg-bin-meta "neg binary meta")
buildmaster_meta_add(neg-bin-meta neg-bin-mem)
buildmaster_component(
	neg-bin-mem
	"neg binary meta member"
	"https://example.invalid/neg-bin.zip"
	""
	shared
	negbin
	"BACKEND=binary"
)
