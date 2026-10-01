cmake_minimum_required(VERSION 3.20)
project(ms-top C)

if(NOT MS_BM_ROOT)
	message(FATAL_ERROR "mode-switch: MS_BM_ROOT is empty")
endif()
if(NOT MS_MODE)
	message(FATAL_ERROR "mode-switch: MS_MODE is empty")
endif()
add_subdirectory("${MS_BM_ROOT}" "${CMAKE_BINARY_DIR}/buildmaster")
include("${MS_BM_ROOT}/helpers.cmake")

buildmaster_component(
	ms-cmake
	"Harness mode-switch CMake"
	"${CMAKE_CURRENT_SOURCE_DIR}/cmake"
	""
	${MS_MODE}
	"mscmake"
)

# Meson import-library naming on Windows differs per toolchain; Unix only.
if(NOT WIN32)
	buildmaster_component(
		ms-meson
		"Harness mode-switch Meson"
		"${CMAKE_CURRENT_SOURCE_DIR}/meson"
		""
		${MS_MODE}
		"msmeson"
	)
endif()
