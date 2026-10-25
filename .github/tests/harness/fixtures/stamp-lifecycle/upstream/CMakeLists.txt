cmake_minimum_required(VERSION 3.21)
project(LifecycleDependency LANGUAGES C)
include(GNUInstallDirs)

if(FIXTURE_MODE STREQUAL "headers")
	install(FILES header.h DESTINATION "${CMAKE_INSTALL_INCLUDEDIR}/lifecycle")
else()
	string(TOUPPER "${FIXTURE_MODE}" _type)
	add_library(lifecycle-${FIXTURE_MODE} ${_type} value.c)
	target_compile_definitions(lifecycle-${FIXTURE_MODE} PRIVATE
		"VALUE_FUNCTION=lifecycle_${FIXTURE_MODE}")
	if(FIXTURE_MODE STREQUAL "shared")
		set_target_properties(lifecycle-shared PROPERTIES VERSION 1.0 SOVERSION 1)
	endif()
	install(TARGETS lifecycle-${FIXTURE_MODE}
		ARCHIVE DESTINATION "${CMAKE_INSTALL_LIBDIR}"
		LIBRARY DESTINATION "${CMAKE_INSTALL_LIBDIR}"
		RUNTIME DESTINATION "${CMAKE_INSTALL_BINDIR}")
endif()
install(CODE "file(APPEND \"${CMAKE_BINARY_DIR}/install-count.txt\" \"install\\n\")")
