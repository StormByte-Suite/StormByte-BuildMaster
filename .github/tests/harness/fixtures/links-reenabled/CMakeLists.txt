if(NOT BM_TEST_REPO_ROOT)
	get_filename_component(BM_TEST_REPO_ROOT
		"${CMAKE_CURRENT_SOURCE_DIR}/../../../.."
		ABSOLUTE
	)
endif()

add_custom_target(links_reenabled_run
	COMMAND ${CMAKE_COMMAND}
		-DRR_BM_ROOT=${BM_TEST_REPO_ROOT}
		-DRR_SRC=${CMAKE_CURRENT_SOURCE_DIR}/project
		-DRR_BIN=${CMAKE_BINARY_DIR}/links_reenabled
		-DRR_GENERATOR=${CMAKE_GENERATOR}
		-DRR_BUILD_TYPE=${CMAKE_BUILD_TYPE}
		-DRR_C_COMPILER=${CMAKE_C_COMPILER}
		-DRR_EXE_SUFFIX=${CMAKE_EXECUTABLE_SUFFIX}
		-P ${CMAKE_CURRENT_SOURCE_DIR}/run.cmake
	COMMENT "[BuildMaster/Core     ]: links-reenabled (restore owned components)"
	VERBATIM
)
