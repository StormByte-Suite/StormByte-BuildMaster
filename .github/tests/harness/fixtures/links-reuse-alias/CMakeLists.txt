if(NOT BM_TEST_REPO_ROOT)
	get_filename_component(BM_TEST_REPO_ROOT
		"${CMAKE_CURRENT_SOURCE_DIR}/../../../.."
		ABSOLUTE
	)
endif()

# Own bindir: ra-log's nested project publishes links/ra-base.cmake with
# ALIAS=Ra::Base. ra-sys's nested project reuses ra-base and links the
# SHARED host ra-sys to the alias. run.cmake checks the edge, the links
# file and the nested link line.
add_custom_target(links_reuse_alias_run
	COMMAND ${CMAKE_COMMAND}
		-DRA_BM_ROOT=${BM_TEST_REPO_ROOT}
		-DRA_SRC=${CMAKE_CURRENT_SOURCE_DIR}/project
		-DRA_BIN=${CMAKE_BINARY_DIR}/links_reuse_alias
		-DRA_GENERATOR=${CMAKE_GENERATOR}
		-DRA_BUILD_TYPE=${CMAKE_BUILD_TYPE}
		-DRA_C_COMPILER=${CMAKE_C_COMPILER}
		-DRA_CXX_COMPILER=${CMAKE_CXX_COMPILER}
		-P ${CMAKE_CURRENT_SOURCE_DIR}/run.cmake
	COMMENT "[BuildMaster/Core     ]: links-reuse-alias (reused ALIAS links the id)"
	VERBATIM
)
