cmake_minimum_required(VERSION 3.21)
project(neg_alias_reuse_conflict LANGUAGES C)
add_subdirectory("${BM_TEST_REPO_ROOT}" "${CMAKE_CURRENT_BINARY_DIR}/bm")
include("${BM_TEST_REPO_ROOT}/helpers.cmake")

# Another process already published neg-reused with ALIAS Neg::Shared.
# Minimal file on purpose: the reader must not rely on the template.
file(WRITE "${BUILDMASTER_LINKS_DIR}/neg-reused.cmake"
	"set(_BM_LINKS_ORIGIN_TITLE \"ghost\")\n"
	"set(_BM_LINKS_ID \"neg-reused\")\n"
	"if(NOT TARGET neg-reused)\n"
	"\tadd_library(neg-reused INTERFACE IMPORTED)\n"
	"endif()\n"
	"set(_bm_links_aliases \"Neg::Shared\")\n"
	"set(_bm_links_dests \"\")\n"
)

buildmaster_component(
	neg-owner
	"Negative alias owner"
	"${CMAKE_CURRENT_SOURCE_DIR}/include"
	""
	headers
	""
	"ALIAS=Neg::Shared"
)

# Reuse of neg-reused: Neg::Shared already maps to neg-owner.
buildmaster_component(
	neg-reused
	"Negative reused"
	"${CMAKE_CURRENT_SOURCE_DIR}/include"
	""
	headers
	""
)
