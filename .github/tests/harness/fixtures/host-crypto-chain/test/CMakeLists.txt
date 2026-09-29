include(GNUInstallDirs)
add_executable(host_crypto_chain_test crypto_test.c)
target_include_directories(host_crypto_chain_test
	PRIVATE
		"${CMAKE_CURRENT_SOURCE_DIR}"
		"${BUILDMASTER_INSTALL_DIR}/${CMAKE_INSTALL_INCLUDEDIR}"
)
buildmaster_link(host_crypto_chain_test cr-crypto)
if(WIN32)
	add_custom_target(host_crypto_chain_test_run
		COMMAND ${CMAKE_COMMAND} -E env
			"PATH=${BUILDMASTER_INSTALL_DIR}/bin;$ENV{PATH}"
			"$<TARGET_FILE:host_crypto_chain_test>"
		WORKING_DIRECTORY "${CMAKE_CURRENT_BINARY_DIR}"
		COMMENT "[BuildMaster/Core     ]: run host_crypto_chain_test"
		VERBATIM
	)
else()
	set(_bm_run_env "")
	list(APPEND _bm_run_env "PATH=${BUILDMASTER_INSTALL_DIR}/bin:$ENV{PATH}")
	list(APPEND _bm_run_env "LD_LIBRARY_PATH=${BUILDMASTER_INSTALL_DIR}/${CMAKE_INSTALL_LIBDIR}")
	list(APPEND _bm_run_env "DYLD_LIBRARY_PATH=${BUILDMASTER_INSTALL_DIR}/${CMAKE_INSTALL_LIBDIR}")
	add_custom_target(host_crypto_chain_test_run
		COMMAND ${CMAKE_COMMAND} -E env ${_bm_run_env}
			"$<TARGET_FILE:host_crypto_chain_test>"
		WORKING_DIRECTORY "${CMAKE_CURRENT_BINARY_DIR}"
		COMMENT "[BuildMaster/Core     ]: run host_crypto_chain_test"
		VERBATIM
	)
endif()
add_dependencies(host_crypto_chain_test_run host_crypto_chain_test)
