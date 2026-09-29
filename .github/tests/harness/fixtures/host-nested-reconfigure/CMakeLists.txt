if(NOT BM_TEST_REPO_ROOT)
	get_filename_component(BM_TEST_REPO_ROOT
		"${CMAKE_CURRENT_SOURCE_DIR}/../../../.."
		ABSOLUTE
	)
endif()

# Parent cmake component whose nested BM project declares the same id
# with BACKEND=host (StormByte-Crypto → Buffer). Own bindir: run.cmake
# drives configure → build → build → nested reconfigure → build.
add_custom_target(host_nested_reconfigure_run
	COMMAND ${CMAKE_COMMAND}
		-DHN_BM_ROOT=${BM_TEST_REPO_ROOT}
		-DHN_SRC=${CMAKE_CURRENT_SOURCE_DIR}/project
		-DHN_BIN=${CMAKE_BINARY_DIR}/host_nested_reconfigure
		-DHN_GENERATOR=${CMAKE_GENERATOR}
		-DHN_BUILD_TYPE=${CMAKE_BUILD_TYPE}
		-DHN_C_COMPILER=${CMAKE_C_COMPILER}
		-DHN_CXX_COMPILER=${CMAKE_CXX_COMPILER}
		-P ${CMAKE_CURRENT_SOURCE_DIR}/run.cmake
	COMMENT "[BuildMaster/Core     ]: host-nested-reconfigure (nested reconfigure keeps deps)"
	VERBATIM
)
