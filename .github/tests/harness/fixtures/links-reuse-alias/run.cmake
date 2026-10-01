# links-reuse-alias driver (cmake -P).
# Inputs: RA_BM_ROOT RA_SRC RA_BIN RA_GENERATOR RA_BUILD_TYPE
#         RA_C_COMPILER RA_CXX_COMPILER

# -P scripts start with every policy unset; IN_LIST needs CMP0057.
cmake_minimum_required(VERSION 3.21)

foreach(_v RA_BM_ROOT RA_SRC RA_BIN RA_GENERATOR)
	if("${${_v}}" STREQUAL "")
		message(FATAL_ERROR "links-reuse-alias: ${_v} is empty")
	endif()
endforeach()

set(_bld "${RA_BIN}/build")
set(_links "${_bld}/buildmaster/links")
set(_nested "${_bld}/buildmaster/bm/ra-sys")

file(REMOVE_RECURSE "${RA_BIN}")
file(MAKE_DIRECTORY "${RA_BIN}")

## @brief Run a command; FATAL with its output on failure.
## @param[in] _label Step name for the error.
function(_ra_run _label)
	execute_process(
		COMMAND ${ARGN}
		RESULT_VARIABLE _rc
		OUTPUT_VARIABLE _out
		ERROR_VARIABLE _out
	)
	if(NOT _rc EQUAL 0)
		message(FATAL_ERROR "links-reuse-alias: ${_label} failed (${_rc})\n${_out}")
	endif()
endfunction()

_ra_run("configure"
	"${CMAKE_COMMAND}" -S "${RA_SRC}" -B "${_bld}" -G "${RA_GENERATOR}"
	"-DCMAKE_BUILD_TYPE=${RA_BUILD_TYPE}"
	"-DCMAKE_C_COMPILER=${RA_C_COMPILER}"
	"-DCMAKE_CXX_COMPILER=${RA_CXX_COMPILER}"
	"-DRA_BM_ROOT=${RA_BM_ROOT}")
# ra-sys links with --no-undefined / -undefined,error: no -lra-base, no build.
_ra_run("build" "${CMAKE_COMMAND}" --build "${_bld}"
	--target ra-log_install ra-sys_install)
set(_built FALSE)
foreach(_lib libra-sys.so libra-sys.dylib ra-sys.dll)
	if(EXISTS "${_nested}/${_lib}")
		set(_built TRUE)
	endif()
endforeach()
if(NOT _built)
	message(FATAL_ERROR "links-reuse-alias: ra-sys was not linked in ${_nested}")
endif()

# The ra-sys nested configure must have taken the reuse path.
set(_needs "${_nested}/bm-reuse-needs.txt")
if(NOT EXISTS "${_needs}")
	message(FATAL_ERROR "links-reuse-alias: ${_needs} missing")
endif()
file(STRINGS "${_needs}" _need_ids)
if(NOT "ra-base" IN_LIST _need_ids)
	message(FATAL_ERROR
		"links-reuse-alias: ra-sys did not reuse ra-base (needs: ${_need_ids})")
endif()

# links/ra-sys.cmake stores the raw id, never the alias.
file(READ "${_links}/ra-sys.cmake" _txt)
if(NOT "${_txt}" MATCHES "set\\(_bm_links_dests \"([^\"]*)\"\\)")
	message(FATAL_ERROR "links-reuse-alias: no dests in links/ra-sys.cmake\n${_txt}")
endif()
set(_dests "${CMAKE_MATCH_1}")
if(NOT "ra-base" IN_LIST _dests OR "Ra::Base" IN_LIST _dests)
	message(FATAL_ERROR
		"links-reuse-alias: links/ra-sys.cmake dests are '${_dests}' (want ra-base, no Ra::Base)")
endif()

# Flatten read links/ra-base.cmake: its libdir and stem are on the line.
file(READ "${_links}/ra-base.cmake" _btxt)
if(NOT "${_btxt}" MATCHES "set\\(_BM_LINKS_LIBDIR \"([^\"]*)\"\\)"
		OR "${CMAKE_MATCH_1}" STREQUAL "")
	message(FATAL_ERROR "links-reuse-alias: no libdir in links/ra-base.cmake\n${_btxt}")
endif()
set(_libdir "${CMAKE_MATCH_1}")
file(READ "${_nested}/build.ninja" _ninja)
string(REPLACE "\\" "/" _ninja "${_ninja}")
if(NOT "${_ninja}" MATCHES "(-lra-base|ra-base\\.lib)")
	message(FATAL_ERROR "links-reuse-alias: ra-sys link line has no ra-base")
endif()
string(FIND "${_ninja}" "${_libdir}" _hit)
if(_hit LESS 0)
	message(FATAL_ERROR
		"links-reuse-alias: ra-sys link line has no libdir ${_libdir}")
endif()
message(STATUS "links-reuse-alias: OK")
