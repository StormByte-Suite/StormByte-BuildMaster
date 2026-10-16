if(NOT BB_BM_ROOT OR NOT BB_SRC OR NOT BB_WORK)
	message(FATAL_ERROR "binary-backend: BB_BM_ROOT / BB_SRC / BB_WORK unset")
endif()
if(NOT BB_GENERATOR)
	set(BB_GENERATOR "Unix Makefiles")
endif()

set(_gen -G "${BB_GENERATOR}")
set(_cc "")
if(BB_C_COMPILER)
	list(APPEND _cc "-DCMAKE_C_COMPILER=${BB_C_COMPILER}")
endif()
if(BB_CXX_COMPILER)
	list(APPEND _cc "-DCMAKE_CXX_COMPILER=${BB_CXX_COMPILER}")
endif()
set(_cfg "")
if(BB_BUILD_TYPE)
	list(APPEND _cfg "-DCMAKE_BUILD_TYPE=${BB_BUILD_TYPE}")
endif()

set(_prod_src "${BB_SRC}/producer")
set(_prod_bin "${BB_WORK}/producer")
set(_gadget_prefix "${BB_WORK}/prefix-gadget")
set(_widget_prefix "${BB_WORK}/prefix-widget")
set(_gzip "${BB_WORK}/gadget-binary.zip")
set(_wzip "${BB_WORK}/widget-binary.zip")
set(_cons_src "${BB_SRC}/consumer")
set(_cons_bin "${BB_WORK}/consumer")

file(REMOVE_RECURSE
	"${_prod_bin}" "${_gadget_prefix}" "${_widget_prefix}" "${_cons_bin}")
file(MAKE_DIRECTORY "${_gadget_prefix}" "${_widget_prefix}")

execute_process(
	COMMAND ${CMAKE_COMMAND} -S "${_prod_src}" -B "${_prod_bin}"
		${_gen} ${_cc} ${_cfg}
	RESULT_VARIABLE _rc
)
if(NOT _rc EQUAL 0)
	message(FATAL_ERROR "binary-backend: producer configure failed (${_rc})")
endif()
execute_process(
	COMMAND ${CMAKE_COMMAND} --build "${_prod_bin}"
	RESULT_VARIABLE _rc
)
if(NOT _rc EQUAL 0)
	message(FATAL_ERROR "binary-backend: producer build failed (${_rc})")
endif()

execute_process(
	COMMAND ${CMAKE_COMMAND} --install "${_prod_bin}"
		--prefix "${_gadget_prefix}" --component gadget
	RESULT_VARIABLE _rc
)
if(NOT _rc EQUAL 0)
	message(FATAL_ERROR "binary-backend: install gadget failed (${_rc})")
endif()
execute_process(
	COMMAND ${CMAKE_COMMAND} --install "${_prod_bin}"
		--prefix "${_widget_prefix}" --component widget
	RESULT_VARIABLE _rc
)
if(NOT _rc EQUAL 0)
	message(FATAL_ERROR "binary-backend: install widget failed (${_rc})")
endif()

foreach(_zip _gzip _wzip)
	if(EXISTS "${${_zip}}")
		file(REMOVE "${${_zip}}")
	endif()
endforeach()
execute_process(
	COMMAND ${CMAKE_COMMAND} -E tar c "${_gzip}" --format=zip -- .
	WORKING_DIRECTORY "${_gadget_prefix}"
	RESULT_VARIABLE _rc
)
if(NOT _rc EQUAL 0 OR NOT EXISTS "${_gzip}")
	message(FATAL_ERROR "binary-backend: gadget zip failed (${_rc})")
endif()
execute_process(
	COMMAND ${CMAKE_COMMAND} -E tar c "${_wzip}" --format=zip -- .
	WORKING_DIRECTORY "${_widget_prefix}"
	RESULT_VARIABLE _rc
)
if(NOT _rc EQUAL 0 OR NOT EXISTS "${_wzip}")
	message(FATAL_ERROR "binary-backend: widget zip failed (${_rc})")
endif()

function(_bb_file_url path out)
	file(TO_CMAKE_PATH "${path}" _cmake)
	if(WIN32)
		set(${out} "file:///${_cmake}" PARENT_SCOPE)
	else()
		set(${out} "file://${_cmake}" PARENT_SCOPE)
	endif()
endfunction()
_bb_file_url("${_gzip}" _gurl)
_bb_file_url("${_wzip}" _wurl)

file(GLOB _in_lib "${_widget_prefix}/lib/*")
file(GLOB _in_lib64 "${_widget_prefix}/lib64/*")
set(_bm_libdir "")
if(_in_lib AND NOT _in_lib64)
	set(_bm_libdir "lib64")
elseif(_in_lib64 AND NOT _in_lib)
	set(_bm_libdir "lib")
endif()
set(_libdir_arg "")
if(NOT _bm_libdir STREQUAL "")
	list(APPEND _libdir_arg "-DBM_LIBDIR=${_bm_libdir}")
	message(STATUS "binary-backend: consumer libdir ${_bm_libdir} (archive used the other)")
endif()

execute_process(
	COMMAND ${CMAKE_COMMAND} -S "${_cons_src}" -B "${_cons_bin}"
		${_gen} ${_cc} ${_cfg}
		"-DBM_ROOT=${BB_BM_ROOT}"
		"-DWIDGET_URL=${_wurl}"
		"-DGADGET_URL=${_gurl}"
		${_libdir_arg}
	RESULT_VARIABLE _rc
	OUTPUT_VARIABLE _out
	ERROR_VARIABLE _err
)
if(NOT _rc EQUAL 0)
	message(FATAL_ERROR "binary-backend: consumer configure failed (${_rc})\n${_out}\n${_err}")
endif()

execute_process(
	COMMAND ${CMAKE_COMMAND} -S "${_cons_src}" -B "${_cons_bin}"
		${_gen} ${_cc} ${_cfg}
		"-DBM_ROOT=${BB_BM_ROOT}"
		"-DWIDGET_URL=${_wurl}"
		"-DGADGET_URL=${_gurl}"
		${_libdir_arg}
	RESULT_VARIABLE _rc
	OUTPUT_VARIABLE _out2
	ERROR_VARIABLE _err2
)
if(NOT _rc EQUAL 0)
	message(FATAL_ERROR "binary-backend: consumer reconfigure failed (${_rc})\n${_out2}\n${_err2}")
endif()
foreach(_title widget-bin gadget-bin)
	string(FIND "${_out2}${_err2}" "Downloading ${_title}" _hit)
	if(_hit LESS 0 OR NOT "${_out2}${_err2}" MATCHES "Downloading ${_title}[^\n]*\\(cached\\) OK")
		message(FATAL_ERROR "binary-backend: second configure did not reuse ${_title}\n${_out2}\n${_err2}")
	endif()
endforeach()

execute_process(
	COMMAND ${CMAKE_COMMAND} --build "${_cons_bin}" --target widget-bin_install
	RESULT_VARIABLE _rc
	OUTPUT_VARIABLE _iout
	ERROR_VARIABLE _ierr
)
if(NOT _rc EQUAL 0)
	message(FATAL_ERROR "binary-backend: widget-bin_install failed (${_rc})\n${_iout}\n${_ierr}")
endif()
if(NOT "${_iout}${_ierr}" MATCHES "gadget-bin")
	message(FATAL_ERROR "binary-backend: widget-bin_install did not extract gadget\n${_iout}\n${_ierr}")
endif()

execute_process(
	COMMAND ${CMAKE_COMMAND} --build "${_cons_bin}" --target widget_drive
	RESULT_VARIABLE _rc
)
if(NOT _rc EQUAL 0)
	message(FATAL_ERROR "binary-backend: widget_drive build failed (${_rc})")
endif()
execute_process(
	COMMAND ${CMAKE_COMMAND} --build "${_cons_bin}" --target widget-use_install
	RESULT_VARIABLE _rc
)
if(NOT _rc EQUAL 0)
	message(FATAL_ERROR "binary-backend: widget-use build failed (${_rc})")
endif()

file(READ "${_cons_bin}/binary-paths.txt" _paths)
string(REGEX MATCH "lib=([^\r\n]*)" _m "${_paths}")
set(_lib "${CMAKE_MATCH_1}")
string(REGEX MATCH "bin=([^\r\n]*)" _m "${_paths}")
set(_bin "${CMAKE_MATCH_1}")
string(REGEX MATCH "exe=([^\r\n]*)" _m "${_paths}")
set(_exe "${CMAKE_MATCH_1}")
if(NOT EXISTS "${_exe}")
	message(FATAL_ERROR "binary-backend: widget_drive was not produced (${_exe})")
endif()

if(WIN32)
	set(ENV{PATH} "${_bin};$ENV{PATH}")
	execute_process(COMMAND "${_exe}" RESULT_VARIABLE _rc OUTPUT_VARIABLE _run)
elseif(APPLE)
	set(ENV{DYLD_LIBRARY_PATH} "${_lib}")
	execute_process(COMMAND "${_exe}" RESULT_VARIABLE _rc OUTPUT_VARIABLE _run)
else()
	set(ENV{LD_LIBRARY_PATH} "${_lib}")
	execute_process(COMMAND "${_exe}" RESULT_VARIABLE _rc OUTPUT_VARIABLE _run)
endif()
if(NOT _rc EQUAL 0 OR NOT _run MATCHES "widget-ok")
	message(FATAL_ERROR "binary-backend: widget_drive failed (${_rc}): ${_run}")
endif()
message(STATUS "binary-backend: widget_drive linked and ran against the shared library")
