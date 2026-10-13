# cmake -DOUTPUT=... -DINPUTS=a.a,b.a -DBUILDMASTER_SRCDIR=... -DCMAKE_AR=... -P
# INPUTS is comma-separated.
# CMAKE_AR is the publisher profile archiver (lib.exe when TOOLCHAIN=msvc).

if(NOT BUILDMASTER_SRCDIR)
	get_filename_component(_here "${CMAKE_CURRENT_LIST_DIR}" DIRECTORY)
	get_filename_component(BUILDMASTER_SRCDIR "${_here}" DIRECTORY)
endif()

include("${BUILDMASTER_SRCDIR}/log.cmake")
if(COMMAND _bm_log_level_init)
	_bm_log_level_init()
endif()

if(NOT OUTPUT OR NOT INPUTS)
	_bm_log_message(BUNDLE FATAL "merge_static_archives: need -DOUTPUT= and -DINPUTS=")
endif()

string(REPLACE "," ";" _inputs "${INPUTS}")
if(NOT _inputs)
	_bm_log_message(BUNDLE FATAL "merge_static_archives: empty INPUTS")
endif()

foreach(_in IN LISTS _inputs)
	if(NOT EXISTS "${_in}")
		_bm_log_message(BUNDLE FATAL "merge_static_archives: missing input ${_in}")
	endif()
endforeach()

get_filename_component(_out_dir "${OUTPUT}" DIRECTORY)
file(MAKE_DIRECTORY "${_out_dir}")

if(NOT CMAKE_AR OR CMAKE_AR STREQUAL "")
	_bm_log_message(BUNDLE FATAL
		"merge_static_archives: -DCMAKE_AR= is required (toolchain profile AR)")
endif()
if(NOT EXISTS "${CMAKE_AR}")
	_bm_log_message(BUNDLE FATAL
		"merge_static_archives: CMAKE_AR missing: ${CMAKE_AR}")
endif()

get_filename_component(_ar_name "${CMAKE_AR}" NAME)
set(_merge_tool "${CMAKE_AR}")
if(APPLE)
	find_program(_libtool NAMES libtool)
	if(NOT _libtool)
		_bm_log_message(BUNDLE FATAL "merge_static_archives: libtool not found (needed on Apple)")
	endif()
	set(_merge_tool "${_libtool}")
endif()
if(DEFINED STAMP_FILE AND NOT STAMP_FILE STREQUAL "")
	file(LOCK "${STAMP_FILE}.lock" GUARD PROCESS TIMEOUT 300)
	set(_key_text "output=${OUTPUT}\ntool=${_merge_tool}\n")
	foreach(_in IN LISTS _inputs)
		file(SHA256 "${_in}" _input_hash)
		string(APPEND _key_text "input=${_in}:${_input_hash}\n")
	endforeach()
	file(SHA256 "${CMAKE_CURRENT_LIST_FILE}" _recipe_hash)
	file(SHA256 "${_merge_tool}" _tool_hash)
	string(APPEND _key_text "recipe=${_recipe_hash}\ntool_hash=${_tool_hash}\n")
	string(SHA256 _key "${_key_text}")
	if(EXISTS "${STAMP_FILE}" AND EXISTS "${OUTPUT}")
		file(STRINGS "${STAMP_FILE}" _old_stamp)
		list(LENGTH _old_stamp _old_stamp_length)
		if(_old_stamp_length EQUAL 2)
			list(GET _old_stamp 0 _old_key)
			list(GET _old_stamp 1 _old_output_hash)
			file(SHA256 "${OUTPUT}" _output_hash)
			if(_old_key STREQUAL "${_key}" AND _old_output_hash STREQUAL "${_output_hash}")
				_bm_log_message(BUNDLE INFO "REPACK is current: ${OUTPUT}")
				return()
			endif()
		endif()
	endif()
endif()

set(_tmp_output "${OUTPUT}.part")
file(REMOVE "${_tmp_output}")

function(_bm_repack_publish temporary output stamp key)
	file(RENAME "${temporary}" "${output}" RESULT _rename_result)
	if(NOT _rename_result STREQUAL "0")
		_bm_log_message(BUNDLE FATAL
			"merge_static_archives: cannot publish ${output}: ${_rename_result}")
	endif()
	if(NOT "${stamp}" STREQUAL "")
		file(SHA256 "${output}" _output_hash)
		file(WRITE "${stamp}.part" "${key}\n${_output_hash}\n")
		file(RENAME "${stamp}.part" "${stamp}" RESULT _stamp_result)
		if(NOT _stamp_result STREQUAL "0")
			_bm_log_message(BUNDLE FATAL
				"merge_static_archives: cannot publish stamp ${stamp}: ${_stamp_result}")
		endif()
	endif()
endfunction()
string(TOLOWER "${_ar_name}" _ar_l)
set(_style "gnu_ar")
if(_ar_l MATCHES "llvm-lib" OR _ar_l STREQUAL "lib" OR _ar_l MATCHES "lib\\.exe$")
	set(_style "msvc_lib")
endif()

if(APPLE)
	execute_process(
		COMMAND "${_merge_tool}" -static -o "${_tmp_output}" ${_inputs}
		RESULT_VARIABLE _rc
		OUTPUT_VARIABLE _out
		ERROR_VARIABLE _err
	)
	if(NOT _rc EQUAL 0)
		_bm_log_message(BUNDLE FATAL "merge_static_archives: libtool -static failed (${_rc}): ${_err}")
	endif()
	_bm_repack_publish("${_tmp_output}" "${OUTPUT}" "${STAMP_FILE}" "${_key}")
	_bm_log_message(BUNDLE INFO "merged ${OUTPUT} with libtool -static")
	return()
endif()

if(_style STREQUAL "msvc_lib")
	execute_process(
		COMMAND "${CMAKE_AR}" /NOLOGO "/OUT:${_tmp_output}" ${_inputs}
		RESULT_VARIABLE _rc
		OUTPUT_VARIABLE _out
		ERROR_VARIABLE _err
	)
	if(NOT _rc EQUAL 0)
		_bm_log_message(BUNDLE FATAL "merge_static_archives: ${CMAKE_AR} /OUT failed (${_rc}): ${_err}")
	endif()
	_bm_repack_publish("${_tmp_output}" "${OUTPUT}" "${STAMP_FILE}" "${_key}")
	_bm_log_message(BUNDLE INFO "merged ${OUTPUT} with ${CMAKE_AR} (msvc_lib)")
	return()
endif()

set(_mri "${_tmp_output}.mri")
set(_mri_txt "CREATE ${_tmp_output}\n")
foreach(_in IN LISTS _inputs)
	string(APPEND _mri_txt "ADDLIB ${_in}\n")
endforeach()
string(APPEND _mri_txt "SAVE\nEND\n")
file(WRITE "${_mri}" "${_mri_txt}")

execute_process(
	COMMAND "${CMAKE_AR}" -M
	INPUT_FILE "${_mri}"
	RESULT_VARIABLE _rc
	OUTPUT_VARIABLE _out
	ERROR_VARIABLE _err
)
file(REMOVE "${_mri}")
if(NOT _rc EQUAL 0)
	_bm_log_message(BUNDLE FATAL "merge_static_archives: ar -M failed (${_rc}): ${_err}")
endif()

_bm_repack_publish("${_tmp_output}" "${OUTPUT}" "${STAMP_FILE}" "${_key}")
_bm_log_message(BUNDLE INFO "merged ${OUTPUT} with ${CMAKE_AR} (gnu_ar)")
