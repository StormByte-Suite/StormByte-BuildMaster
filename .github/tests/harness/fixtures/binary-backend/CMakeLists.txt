if(NOT BM_TEST_REPO_ROOT)
	get_filename_component(BM_TEST_REPO_ROOT
		"${CMAKE_CURRENT_SOURCE_DIR}/../../../.."
		ABSOLUTE
	)
endif()

add_custom_target(binary_backend_run
	COMMAND ${CMAKE_COMMAND}
		-DBB_BM_ROOT=${BM_TEST_REPO_ROOT}
		-DBB_SRC=${CMAKE_CURRENT_SOURCE_DIR}
		-DBB_WORK=${CMAKE_BINARY_DIR}/binary-backend
		-DBB_GENERATOR=${CMAKE_GENERATOR}
		-DBB_BUILD_TYPE=${CMAKE_BUILD_TYPE}
		-DBB_C_COMPILER=${CMAKE_C_COMPILER}
		-DBB_CXX_COMPILER=${CMAKE_CXX_COMPILER}
		-P ${CMAKE_CURRENT_SOURCE_DIR}/run.cmake
	COMMENT "[BuildMaster/Core     ]: binary backend zip, link and run"
	VERBATIM
)
