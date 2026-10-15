# Configure-time contract: the stamp walk records a symbolic link and does
# not follow it. File links, directory links, dangling links and a changed
# target are covered. Creating the links needs the same privilege the
# Windows CI checkout already turns on (enable-symlinks).

function(_bm_stamp_test_link _original _link)
	if(EXISTS "${_link}" OR IS_SYMLINK "${_link}")
		file(REMOVE "${_link}")
	endif()
	file(CREATE_LINK "${_original}" "${_link}" SYMBOLIC RESULT _rc)
	if(NOT _rc EQUAL 0)
		_bm_log_message(CORE FATAL
			"stamp-symlinks: cannot create '${_link}' -> '${_original}' (${_rc})")
	endif()
endfunction()

set(_base "${CMAKE_CURRENT_BINARY_DIR}/stamp-symlinks")
file(REMOVE_RECURSE "${_base}")
file(MAKE_DIRECTORY "${_base}/tree/real" "${_base}/outside")
file(WRITE "${_base}/tree/real/secret.txt" "secret\n")
file(WRITE "${_base}/tree/same-a.txt" "same\n")
file(WRITE "${_base}/tree/same-b.txt" "same\n")
file(WRITE "${_base}/outside/payload.txt" "one\n")

_bm_stamp_test_link("same-a.txt" "${_base}/tree/filelink")
_bm_stamp_test_link("real" "${_base}/tree/dirlink")
_bm_stamp_test_link("missing-a" "${_base}/tree/dangling")
_bm_stamp_test_link("../outside" "${_base}/tree/outsidelink")

_bm_stamp_tree_sha("${_base}/tree" "" _file_a)
_bm_stamp_test_link("same-b.txt" "${_base}/tree/filelink")
_bm_stamp_tree_sha("${_base}/tree" "" _file_b)
if("${_file_a}" STREQUAL "${_file_b}")
	_bm_log_message(CORE FATAL
		"stamp-symlinks: retargeting a file link with the same bytes must change the digest")
endif()

_bm_stamp_tree_sha("${_base}/tree" "" _out_a)
file(WRITE "${_base}/outside/payload.txt" "two\n")
_bm_stamp_tree_sha("${_base}/tree" "" _out_b)
if(NOT "${_out_a}" STREQUAL "${_out_b}")
	_bm_log_message(CORE FATAL
		"stamp-symlinks: a directory link must not follow its target")
endif()

_bm_stamp_test_link("missing-b" "${_base}/tree/dangling")
_bm_stamp_tree_sha("${_base}/tree" "" _dang_b)
if("${_out_b}" STREQUAL "${_dang_b}")
	_bm_log_message(CORE FATAL
		"stamp-symlinks: retargeting a dangling link must change the digest")
endif()

file(WRITE "${_base}/tree/real/secret.txt" "changed\n")
_bm_stamp_tree_sha("${_base}/tree" "" _inside)
if("${_inside}" STREQUAL "${_dang_b}")
	_bm_log_message(CORE FATAL
		"stamp-symlinks: a regular file under the link target must still be hashed on its own path")
endif()

_bm_log_message(CORE STATUS "stamp-symlinks contract: OK")
