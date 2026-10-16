cmake_minimum_required(VERSION 3.21)
project(widget_consumer LANGUAGES C)
if(NOT BM_ROOT OR NOT WIDGET_URL OR NOT GADGET_URL)
	message(FATAL_ERROR "BM_ROOT, WIDGET_URL and GADGET_URL are required")
endif()
add_subdirectory("${BM_ROOT}" "${CMAKE_BINARY_DIR}/bm")
include("${BM_ROOT}/helpers.cmake")

buildmaster_group(binaries "Prebuilt")
buildmaster_component(
	widget-bin
	"Widget prebuilt"
	"${WIDGET_URL}"
	""
	shared
	widget
	"BACKEND=binary;ALIAS=Widget::Lib"
)
buildmaster_link(widget-bin gadget-bin)
buildmaster_component(
	gadget-bin
	"Gadget prebuilt"
	"${GADGET_URL}"
	""
	shared
	gadget
	"BACKEND=binary;ALIAS=Gadget::Lib"
)
buildmaster_group_add(binaries widget-bin gadget-bin)
buildmaster_component(
	widget-use
	"Widget use"
	"${CMAKE_CURRENT_SOURCE_DIR}/use"
	""
	static
	widgetuse
)
buildmaster_link(widget-use widget-bin)
buildmaster_group_add(binaries widget-use)

add_executable(widget_drive "${CMAKE_CURRENT_SOURCE_DIR}/main.c")
target_link_libraries(widget_drive PRIVATE Widget::Lib)
set_target_properties(widget_drive PROPERTIES
	RUNTIME_OUTPUT_DIRECTORY "${CMAKE_BINARY_DIR}"
	RUNTIME_OUTPUT_DIRECTORY_DEBUG "${CMAKE_BINARY_DIR}"
	RUNTIME_OUTPUT_DIRECTORY_RELEASE "${CMAKE_BINARY_DIR}"
	RUNTIME_OUTPUT_DIRECTORY_RELWITHDEBINFO "${CMAKE_BINARY_DIR}"
	RUNTIME_OUTPUT_DIRECTORY_MINSIZEREL "${CMAKE_BINARY_DIR}"
	BUILD_RPATH "${BUILDMASTER_INSTALL_LIBDIR}"
	INSTALL_RPATH "${BUILDMASTER_INSTALL_LIBDIR}")
file(WRITE "${CMAKE_BINARY_DIR}/binary-paths.txt"
	"lib=${BUILDMASTER_INSTALL_LIBDIR}\nbin=${BUILDMASTER_INSTALL_BINDIR}\nexe=${CMAKE_BINARY_DIR}/widget_drive${CMAKE_EXECUTABLE_SUFFIX}\n")
