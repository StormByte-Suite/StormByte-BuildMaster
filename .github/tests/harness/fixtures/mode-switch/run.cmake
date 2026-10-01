# mode-switch driver (cmake -P).
# Inputs: MS_BM_ROOT MS_SRC MS_BIN MS_GENERATOR MS_BUILD_TYPE
#         MS_C_COMPILER MS_CXX_COMPILER
# One build dir: static → shared → new C flags → unchanged. Each change
# must reach the nested tree; the last build must not reconfigure.

foreach(_v MS_BM_ROOT MS_SRC MS_BIN MS_GENERATOR)
	if("${${_v}}" STREQUAL "")
		message(FATAL_ERROR "mode-switch: ${_v} is empty")
	endif()
endforeach()

set(_bld "${MS_BIN}/build")
set(_cm "${_bld}/buildmaster/bm/ms-cmake")
set(_ms "${_bld}/buildmaster/bm/ms-meson")
set(_with_meson TRUE)
if(CMAKE_HOST_WIN32)
	set(_with_meson FALSE)
endif()

file(REMOVE_RECURSE "${MS_BIN}")
file(MAKE_DIRECTORY "${MS_BIN}")

## @brief Run a command; FATAL with its output on failure.
## @param[in]  _label   Step name for the error.
## @param[out] _out_var Parent-scope combined stdout + stderr.
function(_ms_run _label _out_var)
	execute_process(
		COMMAND ${ARGN}
		RESULT_VARIABLE _rc
		OUTPUT_VARIABLE _out
		ERROR_VARIABLE _out
	)
	if(NOT _rc EQUAL 0)
		message(FATAL_ERROR "mode-switch: ${_label} failed (${_rc})\n${_out}")
	endif()
	set(${_out_var} "${_out}" PARENT_SCOPE)
endfunction()

## @brief Configure the top project with `_mode` and `_cflags`, then build.
## @param[in]  _label   Step name.
## @param[in]  _mode    `static` or `shared`.
## @param[in]  _cflags  Top-level CMAKE_C_FLAGS.
## @param[out] _out_var Parent-scope configure + build output.
function(_ms_step _label _mode _cflags _out_var)
	_ms_run("${_label} configure" _cfg
		"${CMAKE_COMMAND}" -S "${MS_SRC}" -B "${_bld}" -G "${MS_GENERATOR}"
		"-DCMAKE_BUILD_TYPE=${MS_BUILD_TYPE}"
		"-DCMAKE_C_COMPILER=${MS_C_COMPILER}"
		"-DCMAKE_CXX_COMPILER=${MS_CXX_COMPILER}"
		"-DCMAKE_C_FLAGS=${_cflags}"
		"-DMS_BM_ROOT=${MS_BM_ROOT}"
		"-DMS_MODE=${_mode}")
	_ms_run("${_label} build" _bout "${CMAKE_COMMAND}" --build "${_bld}")
	set(${_out_var} "${_cfg}\n${_bout}" PARENT_SCOPE)
endfunction()

## @brief FATAL unless both nested trees carry `_mode` and `_mark` (or no mark).
function(_ms_check _label _mode _mark)
	set(_want "OFF")
	if(_mode STREQUAL "shared")
		set(_want "ON")
	endif()
	file(STRINGS "${_cm}/CMakeCache.txt" _bsl REGEX "^BUILD_SHARED_LIBS:")
	if(NOT "${_bsl}" MATCHES "=${_want}$")
		message(FATAL_ERROR
			"mode-switch: ${_label}: nested CMake kept '${_bsl}', want ${_want}")
	endif()
	file(STRINGS "${_cm}/CMakeCache.txt" _cf REGEX "^CMAKE_C_FLAGS:")
	if(NOT "${_mark}" STREQUAL "" AND NOT "${_cf}" MATCHES "${_mark}")
		message(FATAL_ERROR
			"mode-switch: ${_label}: nested CMake kept '${_cf}', want ${_mark}")
	endif()
	if(NOT _with_meson)
		return()
	endif()
	file(READ "${_ms}/meson-info/intro-buildoptions.json" _json)
	string(JSON _n LENGTH "${_json}")
	math(EXPR _last "${_n} - 1")
	set(_lib "")
	set(_cargs "")
	foreach(_i RANGE ${_last})
		string(JSON _name GET "${_json}" ${_i} name)
		if(_name STREQUAL "default_library")
			string(JSON _lib GET "${_json}" ${_i} value)
		elseif(_name STREQUAL "c_args")
			string(JSON _cargs GET "${_json}" ${_i} value)
		endif()
	endforeach()
	if(NOT _lib STREQUAL _mode)
		message(FATAL_ERROR
			"mode-switch: ${_label}: nested Meson kept default_library=${_lib}, want ${_mode}")
	endif()
	if(NOT "${_mark}" STREQUAL "" AND NOT "${_cargs}" MATCHES "${_mark}")
		message(FATAL_ERROR
			"mode-switch: ${_label}: nested Meson kept c_args=${_cargs}, want ${_mark}")
	endif()
endfunction()

## @brief FATAL unless `_out` reconfigured every nested tree (or none).
function(_ms_reconfigured _label _out _expect)
	set(_titles "Harness mode-switch CMake")
	if(_with_meson)
		list(APPEND _titles "Harness mode-switch Meson")
	endif()
	foreach(_t IN LISTS _titles)
		string(FIND "${_out}" "Reconfiguring ${_t}:" _at)
		if(_expect AND _at EQUAL -1)
			message(FATAL_ERROR "mode-switch: ${_label}: ${_t} was not reconfigured\n${_out}")
		elseif(NOT _expect AND NOT _at EQUAL -1)
			message(FATAL_ERROR "mode-switch: ${_label}: ${_t} reconfigured without changes\n${_out}")
		endif()
	endforeach()
endfunction()

_ms_step("static" static "" _out)
_ms_check("static" static "")

_ms_step("shared" shared "" _out)
_ms_reconfigured("shared" "${_out}" TRUE)
_ms_check("shared" shared "")

_ms_step("abi" shared "-DMS_ABI_MARK=1" _out)
_ms_reconfigured("abi" "${_out}" TRUE)
_ms_check("abi" shared "MS_ABI_MARK")

_ms_step("unchanged" shared "-DMS_ABI_MARK=1" _out)
_ms_reconfigured("unchanged" "${_out}" FALSE)
_ms_check("unchanged" shared "MS_ABI_MARK")

message(STATUS "mode-switch: OK")
