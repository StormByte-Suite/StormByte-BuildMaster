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

## @brief FATAL unless `_dir`/tmp exists and holds no partial download.
function(_dd_expect_clean_tmp _label _dir)
	if(NOT IS_DIRECTORY "${_dir}/tmp")
		message(FATAL_ERROR "datadir: ${_label}: ${_dir}/tmp missing")
	endif()
	file(GLOB _parts "${_dir}/tmp/*.part")
	if(_parts)
		message(FATAL_ERROR "datadir: ${_label}: partial download left: ${_parts}")
	endif()
endfunction()

## @brief Configure-only command line for `_bld` (no env, no build).
## @param[out] _out_var Parent-scope argv list.
function(_dd_cfg_cmd _out_var _bld)
	set(${_out_var}
		"${CMAKE_COMMAND}" -E env --unset=BUILDMASTER_DATADIR
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
		PARENT_SCOPE)
endfunction()

set(_unset "--unset=BUILDMASTER_DATADIR")

# -D

# Failed download (hash never matches): nothing reaches downloads/.
_dd_cfg_cmd(_cmd "${DD_BIN}/f"
	"-DBUILDMASTER_DATADIR=${DD_BIN}/data_bad"
	"-DDD_HASH_TOP=0000000000000000000000000000000000000000000000000000000000000000")
execute_process(COMMAND ${_cmd}
	RESULT_VARIABLE _rc OUTPUT_VARIABLE _out ERROR_VARIABLE _out)
if(_rc EQUAL 0)
	message(FATAL_ERROR "datadir: bad hash: configure succeeded\n${_out}")
endif()
if(NOT "${_out}" MATCHES "Hash mismatch")
	message(FATAL_ERROR "datadir: bad hash: failed for another reason\n${_out}")
endif()
if(EXISTS "${DD_BIN}/data_bad/downloads/top_payload.tar.gz")
	message(FATAL_ERROR "datadir: bad hash: rejected archive published to downloads/")
endif()
_dd_expect_clean_tmp("bad hash" "${DD_BIN}/data_bad")

# Failed transfer without a hash must not leave a file that a later run
# would take as a cache hit.
file(RENAME "${_pack}/top_payload.tar.gz" "${_pack}/top_payload.tar.gz.away")
_dd_cfg_cmd(_cmd "${DD_BIN}/g"
	"-DBUILDMASTER_DATADIR=${DD_BIN}/data_nohash" "-DDD_HASH_TOP=NONE")
execute_process(COMMAND ${_cmd}
	RESULT_VARIABLE _rc OUTPUT_VARIABLE _out ERROR_VARIABLE _out)
file(RENAME "${_pack}/top_payload.tar.gz.away" "${_pack}/top_payload.tar.gz")
if(_rc EQUAL 0)
	message(FATAL_ERROR "datadir: failed transfer: configure succeeded\n${_out}")
endif()
if(EXISTS "${DD_BIN}/data_nohash/downloads/top_payload.tar.gz")
	message(FATAL_ERROR "datadir: failed transfer: partial archive published to downloads/")
endif()
_dd_expect_clean_tmp("failed transfer" "${DD_BIN}/data_nohash")
_dd_cfg_cmd(_cmd "${DD_BIN}/g"
	"-DBUILDMASTER_DATADIR=${DD_BIN}/data_nohash" "-DDD_HASH_TOP=NONE")
execute_process(COMMAND ${_cmd}
	RESULT_VARIABLE _rc OUTPUT_VARIABLE _out ERROR_VARIABLE _out)
if(NOT _rc EQUAL 0)
	message(FATAL_ERROR "datadir: retry after failed transfer failed\n${_out}")
endif()
file(SHA256 "${DD_BIN}/data_nohash/downloads/top_payload.tar.gz" _got)
if(NOT _got STREQUAL _hash_top)
	message(FATAL_ERROR "datadir: retry after failed transfer kept a bad archive")
endif()

# Two configures racing on one fresh data dir.
_dd_cfg_cmd(_cmd1 "${DD_BIN}/p1" "-DBUILDMASTER_DATADIR=${DD_BIN}/data_par")
_dd_cfg_cmd(_cmd2 "${DD_BIN}/p2" "-DBUILDMASTER_DATADIR=${DD_BIN}/data_par")
# Piped COMMANDs run concurrently; the first logs to a file so it never
# blocks on a pipe the second does not read.
file(WRITE "${DD_BIN}/p1.cmake"
"set(_c [==[${_cmd1}]==])
execute_process(COMMAND \${_c} RESULT_VARIABLE _rc
	OUTPUT_FILE [==[${DD_BIN}/p1.log]==] ERROR_FILE [==[${DD_BIN}/p1.log]==])
if(NOT _rc EQUAL 0)
	message(FATAL_ERROR \"p1 configure failed (\${_rc}), see ${DD_BIN}/p1.log\")
endif()
")
execute_process(
	COMMAND "${CMAKE_COMMAND}" -P "${DD_BIN}/p1.cmake"
	COMMAND ${_cmd2}
	RESULTS_VARIABLE _rcs OUTPUT_VARIABLE _out ERROR_VARIABLE _out)
foreach(_rc IN LISTS _rcs)
	if(NOT _rc EQUAL 0)
		message(FATAL_ERROR "datadir: parallel: configure failed (${_rcs})\n${_out}")
	endif()
endforeach()
_dd_expect_in("parallel" "${DD_BIN}/data_par")
_dd_expect_clean_tmp("parallel" "${DD_BIN}/data_par")
foreach(_a IN LISTS _archives)
	file(SHA256 "${DD_BIN}/data_par/downloads/${_a}" _got)
	file(SHA256 "${_pack}/${_a}" _want)
	if(NOT _got STREQUAL _want)
		message(FATAL_ERROR "datadir: parallel: ${_a} corrupted")
	endif()
endforeach()
_dd_build("-D" "${DD_BIN}/a" "${_unset}" "-DBUILDMASTER_DATADIR=${DD_BIN}/data_d")
_dd_expect_in("-D" "${DD_BIN}/data_d")
_dd_expect_none("-D" "${DD_BIN}/a")
_dd_expect_clean_tmp("-D" "${DD_BIN}/data_d")

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
