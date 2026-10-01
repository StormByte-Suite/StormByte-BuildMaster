# datadir driver (cmake -P).
# Inputs: DD_BM_ROOT DD_SRC DD_BIN DD_GENERATOR DD_BUILD_TYPE
#         DD_C_COMPILER DD_CXX_COMPILER
# FILES archives (top project and a nested BuildMaster) must land in
# <BUILDMASTER_DATADIR>/downloads: -D, then ENV, else BuildMaster's bindir.
# A second build dir sharing the data dir must reuse them.

foreach(_v DD_BM_ROOT DD_SRC DD_BIN DD_GENERATOR)
	if("${${_v}}" STREQUAL "")
		message(FATAL_ERROR "datadir: ${_v} is empty")
	endif()
endforeach()

file(REMOVE_RECURSE "${DD_BIN}")
set(_pack "${DD_BIN}/pack")
file(MAKE_DIRECTORY "${_pack}/content")
file(WRITE "${_pack}/content/mark.txt" "datadir\n")
set(_archives top_payload.tar.gz nest_payload.tar.gz)
foreach(_a IN LISTS _archives)
	execute_process(
		COMMAND "${CMAKE_COMMAND}" -E tar czf "${_pack}/${_a}" mark.txt
		WORKING_DIRECTORY "${_pack}/content"
		RESULT_VARIABLE _rc)
	if(NOT _rc EQUAL 0)
		message(FATAL_ERROR "datadir: tar ${_a} failed")
	endif()
endforeach()
file(SHA256 "${_pack}/top_payload.tar.gz" _hash_top)
file(SHA256 "${_pack}/nest_payload.tar.gz" _hash_nest)
file(TO_CMAKE_PATH "${_pack}" _pack_url)

## @brief Configure + build `DD_SRC` into `_bld` under `cmake -E env ${_env}`.
## @param[in] _label Step name.
## @param[in] _bld   Build directory.
## @param[in] _env   `cmake -E env` arguments (may be empty).
## @param[in] ARGN   Extra configure arguments.
function(_dd_build _label _bld _env)
	execute_process(
		COMMAND "${CMAKE_COMMAND}" -E env ${_env}
			"${CMAKE_COMMAND}" -S "${DD_SRC}" -B "${_bld}" -G "${DD_GENERATOR}"
			"-DCMAKE_BUILD_TYPE=${DD_BUILD_TYPE}"
			"-DCMAKE_C_COMPILER=${DD_C_COMPILER}"
			"-DCMAKE_CXX_COMPILER=${DD_CXX_COMPILER}"
			"-DDD_BM_ROOT=${DD_BM_ROOT}"
			"-DDD_URL_TOP=file://${_pack_url}/top_payload.tar.gz"
			"-DDD_HASH_TOP=${_hash_top}"
			"-DDD_URL_NEST=file://${_pack_url}/nest_payload.tar.gz"
			"-DDD_HASH_NEST=${_hash_nest}"
			${ARGN}
		RESULT_VARIABLE _rc
		OUTPUT_VARIABLE _out
		ERROR_VARIABLE _out)
	if(NOT _rc EQUAL 0)
		message(FATAL_ERROR "datadir: ${_label} configure failed (${_rc})\n${_out}")
	endif()
	execute_process(
		COMMAND "${CMAKE_COMMAND}" -E env ${_env}
			"${CMAKE_COMMAND}" --build "${_bld}"
		RESULT_VARIABLE _rc
		OUTPUT_VARIABLE _out
		ERROR_VARIABLE _out)
	if(NOT _rc EQUAL 0)
		message(FATAL_ERROR "datadir: ${_label} build failed (${_rc})\n${_out}")
	endif()
endfunction()

## @brief FATAL unless both archives are in `_dir`/downloads.
function(_dd_expect_in _label _dir)
	foreach(_a IN LISTS _archives)
		if(NOT EXISTS "${_dir}/downloads/${_a}")
			file(GLOB_RECURSE _where "${DD_BIN}/*/${_a}")
			message(FATAL_ERROR
				"datadir: ${_label}: ${_a} not in ${_dir}/downloads\nfound: ${_where}")
		endif()
	endforeach()
endfunction()

## @brief FATAL if any archive was downloaded under `_dir`.
function(_dd_expect_none _label _dir)
	foreach(_a IN LISTS _archives)
		file(GLOB_RECURSE _hit "${_dir}/${_a}")
		if(_hit)
			message(FATAL_ERROR "datadir: ${_label}: stray download ${_hit}")
		endif()
	endforeach()
endfunction()

set(_unset "--unset=BUILDMASTER_DATADIR")

# -D
_dd_build("-D" "${DD_BIN}/a" "${_unset}" "-DBUILDMASTER_DATADIR=${DD_BIN}/data_d")
_dd_expect_in("-D" "${DD_BIN}/data_d")
_dd_expect_none("-D" "${DD_BIN}/a")

# Fresh build dir, same data dir, sources gone: must hit the cache.
foreach(_a IN LISTS _archives)
	file(RENAME "${_pack}/${_a}" "${_pack}/${_a}.away")
endforeach()
_dd_build("cache" "${DD_BIN}/b" "${_unset}" "-DBUILDMASTER_DATADIR=${DD_BIN}/data_d")
_dd_expect_none("cache" "${DD_BIN}/b")
foreach(_a IN LISTS _archives)
	file(RENAME "${_pack}/${_a}.away" "${_pack}/${_a}")
endforeach()

# ENV
_dd_build("env" "${DD_BIN}/c" "BUILDMASTER_DATADIR=${DD_BIN}/data_env")
_dd_expect_in("env" "${DD_BIN}/data_env")
_dd_expect_none("env" "${DD_BIN}/c")

# -D wins over ENV
_dd_build("-D+env" "${DD_BIN}/d" "BUILDMASTER_DATADIR=${DD_BIN}/data_env2"
	"-DBUILDMASTER_DATADIR=${DD_BIN}/data_d2")
_dd_expect_in("-D+env" "${DD_BIN}/data_d2")
_dd_expect_none("-D+env" "${DD_BIN}/data_env2")
_dd_expect_none("-D+env" "${DD_BIN}/d")

# Default: BuildMaster's bindir
_dd_build("default" "${DD_BIN}/e" "${_unset}")
_dd_expect_in("default" "${DD_BIN}/e/buildmaster")

message(STATUS "datadir: OK")
