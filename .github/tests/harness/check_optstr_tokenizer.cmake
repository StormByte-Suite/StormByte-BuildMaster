set(_patches patch-one.diff patch-two.diff)
set(_optstr
	"TOOLCHAIN=gcc;GIT={PATCH={${_patches}};TITLE=tokenizer probe};LINK={m;dl};LINKFLAGS={LINUX={-pthread;-Wl,--as-needed}}")

_bm_opt_split_pairs("${_optstr}" _pairs)
list(LENGTH _pairs _pair_count)
if(NOT _pair_count EQUAL 4)
	message(FATAL_ERROR
		"optstr tokenizer: expected 4 outer items, got ${_pair_count}: ${_pairs}")
endif()

_bm_opt_parse_git("${_optstr}"
	_git_present _fetch _switch _reset _parsed_patches _title _root)
if(NOT _git_present OR NOT "${_parsed_patches}" STREQUAL "patch-one.diff;patch-two.diff")
	message(FATAL_ERROR
		"optstr tokenizer: PATCH batch parsed as '${_parsed_patches}'")
endif()
if(NOT _title STREQUAL "tokenizer probe")
	message(FATAL_ERROR
		"optstr tokenizer: sibling TITLE parsed as '${_title}'")
endif()

_bm_opt_parse_link("${_optstr}" _link_items)
if(NOT "${_link_items}" STREQUAL "m;dl")
	message(FATAL_ERROR
		"optstr tokenizer: LINK list parsed as '${_link_items}'")
endif()

_bm_opt_parse_linkflags("${_optstr}" _linkflags)
if(NOT "${_linkflags}" STREQUAL "-pthread;-Wl,--as-needed")
	message(FATAL_ERROR
		"optstr tokenizer: nested LINKFLAGS parsed as '${_linkflags}'")
endif()

message(STATUS "optstr tokenizer: list-valued nested items stay intact")