# Database.a PRIVATE→pq. The parent exe links only sl-db.
# sl-db_static.txt must carry sl-pq so flatten emits -L/-lsl_pq.

buildmaster_component(
	sl-pq
	"Harness static pq"
	"${CMAKE_CURRENT_SOURCE_DIR}/pq"
	""
	static
	"sl_pq"
)
buildmaster_component(
	sl-db
	"Harness static db"
	"${CMAKE_CURRENT_SOURCE_DIR}/db"
	""
	static
	"sl_db"
)
buildmaster_depend(sl-db sl-pq)
buildmaster_link(sl-db sl-pq)

add_executable(links_static_closure_test links_static_closure_test.c)
target_include_directories(links_static_closure_test PRIVATE
	"${BUILDMASTER_INSTALL_INCLUDEDIR}")
target_link_directories(links_static_closure_test PRIVATE
	"${BUILDMASTER_INSTALL_LIBDIR}")
target_link_libraries(links_static_closure_test PRIVATE sl-db)
add_dependencies(links_static_closure_test sl-db_install sl-pq_install)
set_target_properties(links_static_closure_test PROPERTIES
	BUILD_RPATH "${BUILDMASTER_INSTALL_LIBDIR}")

add_custom_target(links_static_closure_test_run
	COMMAND ${CMAKE_COMMAND} -E env
		"LD_LIBRARY_PATH=${BUILDMASTER_INSTALL_LIBDIR}:$ENV{LD_LIBRARY_PATH}"
		"DYLD_LIBRARY_PATH=${BUILDMASTER_INSTALL_LIBDIR}:$ENV{DYLD_LIBRARY_PATH}"
		"$<TARGET_FILE:links_static_closure_test>"
	DEPENDS links_static_closure_test
	COMMENT "[BuildMaster/Core     ]: run links_static_closure_test"
	VERBATIM
)
