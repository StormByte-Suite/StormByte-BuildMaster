cmake_minimum_required(VERSION 3.21)

foreach(_v RR_BM_ROOT RR_SRC RR_BIN RR_GENERATOR RR_C_COMPILER)
	if("${${_v}}" STREQUAL "")
		message(FATAL_ERROR "links-reenabled: ${_v} is empty")
	endif()
endforeach()

include(ProcessorCount)
ProcessorCount(_jobs)
if(NOT _jobs GREATER 0)
	message(FATAL_ERROR "links-reenabled: could not determine the processor count")
endif()

string(RANDOM LENGTH 16 ALPHABET 0123456789abcdef _test_id)
set(_bld "${RR_BIN}/${_test_id}")
if(EXISTS "${_bld}")
	message(FATAL_ERROR "links-reenabled: test directory already exists: ${_bld}")
endif()

function(_rr_run _label _out_var)
	execute_process(
		COMMAND ${ARGN}
		RESULT_VARIABLE _rc
		OUTPUT_VARIABLE _stdout
		ERROR_VARIABLE _stderr
	)
	if(NOT _rc STREQUAL "0")
		message(FATAL_ERROR "links-reenabled: ${_label} failed (${_rc})\n${_stdout}\n${_stderr}")
	endif()
	set(${_out_var} "${_stdout}\n${_stderr}" PARENT_SCOPE)
endfunction()

function(_rr_configure _label _enabled _out_var)
	_rr_run("${_label} configure" _output
		"${CMAKE_COMMAND}" -S "${RR_SRC}" -B "${_bld}" -G "${RR_GENERATOR}"
		"-DCMAKE_BUILD_TYPE=${RR_BUILD_TYPE}"
		"-DCMAKE_C_COMPILER=${RR_C_COMPILER}"
		"-DRR_BM_ROOT=${RR_BM_ROOT}"
		"-DRR_ENABLE=${_enabled}")
	set(${_out_var} "${_output}" PARENT_SCOPE)
endfunction()

function(_rr_build_and_run _label)
	set(_build_args --build "${_bld}" --parallel "${_jobs}")
	if(NOT "${RR_BUILD_TYPE}" STREQUAL "")
		list(APPEND _build_args --config "${RR_BUILD_TYPE}")
	endif()
	_rr_run("${_label} build" _output "${CMAKE_COMMAND}" ${_build_args} --target rr-check)

	set(_exe "${_bld}/bin/rr-check${RR_EXE_SUFFIX}")
	if(NOT EXISTS "${_exe}" AND NOT "${RR_BUILD_TYPE}" STREQUAL "")
		set(_exe "${_bld}/bin/${RR_BUILD_TYPE}/rr-check${RR_EXE_SUFFIX}")
	endif()
	if(CMAKE_HOST_WIN32)
		set(ENV{PATH} "${_bld}/bin;${_bld}/bin/${RR_BUILD_TYPE};${_bld};${_bld}/${RR_BUILD_TYPE};${_bld}/buildmaster/install/bin;$ENV{PATH}")
	endif()
	_rr_run("${_label} executable" _output "${_exe}")
	_rr_run("${_label} install target" _output
		"${CMAKE_COMMAND}" ${_build_args} --target rr-dep_install)
endfunction()

_rr_configure("initial" ON _out)
_rr_build_and_run("initial")

_rr_configure("disabled" OFF _out)
set(_links "${_bld}/buildmaster/links/rr-dep.cmake")
if(NOT EXISTS "${_links}")
	message(FATAL_ERROR "links-reenabled: dependency metadata disappeared while disabled")
endif()
file(STRINGS "${_bld}/bm-owned-links.txt" _owned)
if("rr-dep" IN_LIST _owned)
	message(FATAL_ERROR "links-reenabled: disabled dependency remains in the current ownership list")
endif()

_rr_configure("re-enabled" ON _out)
_rr_build_and_run("re-enabled")

file(REMOVE "${_bld}/bm-owned-links.txt")
_rr_configure("missing ownership list" ON _out)
_rr_build_and_run("missing ownership list")

message(STATUS "links-reenabled: OK")
