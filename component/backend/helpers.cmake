# =============================================================================
# component/backend/helpers.cmake — CMake and Meson backend entry
# =============================================================================

include("${CMAKE_CURRENT_LIST_DIR}/cmake/helpers.cmake")
include("${CMAKE_CURRENT_LIST_DIR}/meson/helpers.cmake")
include("${CMAKE_CURRENT_LIST_DIR}/host/helpers.cmake")

if(NOT DEFINED BUILDMASTER_FACTORY_BACKENDS)
	set(BUILDMASTER_FACTORY_BACKENDS "cmake;meson;host")
endif()
