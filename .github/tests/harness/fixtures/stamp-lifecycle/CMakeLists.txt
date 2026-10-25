cmake_minimum_required(VERSION 3.21)
project(StampLifecycle LANGUAGES C)

set(CMAKE_INSTALL_LIBDIR lib64 CACHE STRING "" FORCE)
include(GNUInstallDirs)
add_subdirectory("${BM_ROOT}" buildmaster_src)
include("${BM_ROOT}/helpers.cmake")

# A sibling consumer must see the producer before Make evaluates its link rule.
add_subdirectory(consumer)
foreach(_mode static shared headers)
	if(BACKEND STREQUAL "meson")
		set(_options "-Dfixture_mode=${_mode}")
	else()
		set(_options "-DFIXTURE_MODE=${_mode}")
	endif()
	buildmaster_component(
		lifecycle-${_mode} "Lifecycle ${_mode}"
		"${CMAKE_CURRENT_SOURCE_DIR}/upstream"
		"${_options}"
		"${_mode}" "lifecycle-${_mode}" "BACKEND=${BACKEND};RENAME=OFF;IPO=OFF")
endforeach()
if(NOT BACKEND STREQUAL "meson")
	buildmaster_depend(lifecycle-shared lifecycle-static)
endif()
target_link_libraries(consumer PRIVATE lifecycle-static lifecycle-shared lifecycle-headers)

file(WRITE "${CMAKE_BINARY_DIR}/paths.cmake"
	"set(PREFIX [==[${BUILDMASTER_INSTALL_DIR}]==])\n"
	"set(LIBDIR [==[${BUILDMASTER_INSTALL_LIBDIR}]==])\n")
foreach(_mode static shared headers)
	get_property(_bd GLOBAL PROPERTY BUILDMASTER_COMPONENT_lifecycle-${_mode}_BUILDDIR)
	file(APPEND "${CMAKE_BINARY_DIR}/paths.cmake"
		"set(BD_${_mode} [==[${_bd}]==])\n")
endforeach()
