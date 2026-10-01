if(NOT BM_TEST_REPO_ROOT)
	get_filename_component(BM_TEST_REPO_ROOT
		"${CMAKE_CURRENT_SOURCE_DIR}/../../../.."
		ABSOLUTE
	)
endif()

# Own bindir: run.cmake configures static, switches to shared, then changes
# C flags, and checks every nested tree was configured again each time.
add_custom_target(mode_switch_run
	COMMAND ${CMAKE_COMMAND}
		-DMS_BM_ROOT=${BM_TEST_REPO_ROOT}
		-DMS_SRC=${CMAKE_CURRENT_SOURCE_DIR}/project
		-DMS_BIN=${CMAKE_BINARY_DIR}/mode_switch
		-DMS_GENERATOR=${CMAKE_GENERATOR}
		-DMS_BUILD_TYPE=${CMAKE_BUILD_TYPE}
		-DMS_C_COMPILER=${CMAKE_C_COMPILER}
		-DMS_CXX_COMPILER=${CMAKE_CXX_COMPILER}
		-P ${CMAKE_CURRENT_SOURCE_DIR}/run.cmake
	COMMENT "[BuildMaster/Core     ]: mode-switch (mode/ABI change reconfigures)"
	VERBATIM
)
