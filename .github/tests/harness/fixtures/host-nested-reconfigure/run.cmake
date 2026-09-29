# host-nested-reconfigure driver (cmake -P).
# Inputs: HN_BM_ROOT HN_SRC HN_BIN HN_GENERATOR HN_BUILD_TYPE
#         HN_C_COMPILER HN_CXX_COMPILER
# The project is copied so step 4 can add a source without touching the repo.

foreach(_v HN_BM_ROOT HN_SRC HN_BIN HN_GENERATOR)
	if("${${_v}}" STREQUAL "")
		message(FATAL_ERROR "host-nested-reconfigure: ${_v} is empty")
	endif()
endforeach()

set(_src "${HN_BIN}/src")
set(_bld "${HN_BIN}/build")
set(_nested "${_bld}/buildmaster/bm/hn-buffer")

file(REMOVE_RECURSE "${HN_BIN}")
file(MAKE_DIRECTORY "${HN_BIN}")
file(COPY "${HN_SRC}/" DESTINATION "${_src}")

## @brief Run a command; FATAL with its output on failure.
## @param[in] _label Step name for the error.
## @param[out] _out_var Parent-scope combined stdout + stderr.
function(_hn_run _label _out_var)
	execute_process(
		COMMAND ${ARGN}
		RESULT_VARIABLE _rc
		OUTPUT_VARIABLE _out
		ERROR_VARIABLE _out
	)
	if(NOT _rc EQUAL 0)
		message(FATAL_ERROR "host-nested-reconfigure: ${_label} failed (${_rc})\n${_out}")
	endif()
	set(${_out_var} "${_out}" PARENT_SCOPE)
endfunction()

## @brief FATAL if a configure skipped an id this build dir published.
function(_hn_no_self_skip _label _out)
	if("${_out}" MATCHES "already built by '[^']*' \\((hn-[a-z]+)\\)")
		message(FATAL_ERROR
			"host-nested-reconfigure: ${_label} skipped its own '${CMAKE_MATCH_1}'\n${_out}")
	endif()
endfunction()

## @brief FATAL if an unchanged build re-ran CMake (parent or nested).
function(_hn_no_rerun _label _out)
	if("${_out}" MATCHES "Re-running CMake")
		message(FATAL_ERROR
			"host-nested-reconfigure: ${_label} re-ran CMake without changes\n${_out}")
	endif()
endfunction()

## @brief FATAL unless the nested host objects wait on Logger/System install.
function(_hn_nested_edges _label)
	file(STRINGS "${_nested}/build.ninja" _lines
		REGEX "^build cmake_object_order_depends_target_hn-buffer:")
	foreach(_dep hn-logger_install hn-system_install)
		if(NOT "${_lines}" MATCHES "${_dep}")
			message(FATAL_ERROR
				"host-nested-reconfigure: ${_label}: hn-buffer objects do not wait on ${_dep}\n${_lines}")
		endif()
	endforeach()
endfunction()

# 1. Fresh configure + build.
_hn_run("configure" _out
	"${CMAKE_COMMAND}" -S "${_src}" -B "${_bld}" -G "${HN_GENERATOR}"
	"-DCMAKE_BUILD_TYPE=${HN_BUILD_TYPE}"
	"-DCMAKE_C_COMPILER=${HN_C_COMPILER}"
	"-DCMAKE_CXX_COMPILER=${HN_CXX_COMPILER}"
	"-DHN_BM_ROOT=${HN_BM_ROOT}")
_hn_run("build 1" _out "${CMAKE_COMMAND}" --build "${_bld}")
_hn_no_self_skip("build 1" "${_out}")
_hn_no_rerun("build 1" "${_out}")
_hn_nested_edges("build 1")

# 2. Second build without changes.
_hn_run("build 2" _out "${CMAKE_COMMAND}" --build "${_bld}")
_hn_no_self_skip("build 2" "${_out}")
_hn_no_rerun("build 2" "${_out}")

# 3. Force a nested reconfigure: GLOB mismatch + newer links files.
file(WRITE "${_src}/buffer/src/extra.c" "int hn_buffer_extra(void) { return 0; }\n")
file(GLOB _links "${_bld}/buildmaster/links/*.cmake")
file(TOUCH ${_links})
_hn_run("build 3" _out "${CMAKE_COMMAND}" --build "${_bld}")
_hn_no_self_skip("build 3" "${_out}")
file(STRINGS "${_nested}/CMakeCache.txt" _nl REGEX "contained a newline")
if(_nl)
	message(FATAL_ERROR
		"host-nested-reconfigure: build 3: toolchain dump split a list value\n${_nl}")
endif()
_hn_nested_edges("build 3")
if(NOT EXISTS "${_nested}/CMakeFiles/hn-buffer.dir/src/extra.c.o"
		AND NOT EXISTS "${_nested}/CMakeFiles/hn-buffer.dir/src/extra.c.obj")
	message(FATAL_ERROR "host-nested-reconfigure: build 3 did not pick up extra.c")
endif()

# 4. Top-level reconfigure of an existing build dir.
_hn_run("reconfigure" _out "${CMAKE_COMMAND}" "${_bld}")
_hn_no_self_skip("reconfigure" "${_out}")
_hn_run("build 4" _out "${CMAKE_COMMAND}" --build "${_bld}" --target hn_test)
_hn_no_self_skip("build 4" "${_out}")

file(GLOB_RECURSE _exe "${_bld}/hn_test" "${_bld}/hn_test.exe")
if(NOT _exe)
	message(FATAL_ERROR "host-nested-reconfigure: hn_test not built")
endif()
list(GET _exe 0 _exe)
_hn_run("hn_test" _out "${_exe}")
message(STATUS "host-nested-reconfigure: OK")
