if(NOT BM_TEST_REPO_ROOT)
	get_filename_component(BM_TEST_REPO_ROOT
		"${CMAKE_CURRENT_SOURCE_DIR}/../../../.."
		ABSOLUTE
	)
endif()

# Own bindirs: run.cmake configures with -D, ENV, both, and neither, and
# checks where FILES archives (top and nested BuildMaster) land.
add_custom_target(datadir_run
	COMMAND ${CMAKE_COMMAND}
		-DDD_BM_ROOT=${BM_TEST_REPO_ROOT}
		-DDD_SRC=${CMAKE_CURRENT_SOURCE_DIR}/project
		-DDD_BIN=${CMAKE_BINARY_DIR}/datadir
		-DDD_GENERATOR=${CMAKE_GENERATOR}
		-DDD_BUILD_TYPE=${CMAKE_BUILD_TYPE}
		-DDD_C_COMPILER=${CMAKE_C_COMPILER}
		-DDD_CXX_COMPILER=${CMAKE_CXX_COMPILER}
		-P ${CMAKE_CURRENT_SOURCE_DIR}/run.cmake
	COMMENT "[BuildMaster/Core     ]: datadir (downloads under BUILDMASTER_DATADIR)"
	VERBATIM
)
